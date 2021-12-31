function init()
    m.sec = CreateObject("roRegistrySection", "GPPAuth")
    m.port = CreateObject("roMessagePort")
    m.br = "&"
    m.creds = ParseJson(ReadAsciiFile("pkg:/oauth2.json")).installed
    m.response = createObject("roList")
end function

function prepareRequest()
    ro = CreateObject("roUrlTransfer")
    ro.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ro.RetainBodyOnError(True)
    ro.setMessagePort(m.port)
    return ro
end function

function prepareAuthRequest()
    ro = prepareRequest()
    ro.AddHeader("Content-Type","application/x-www-form-urlencoded")
    ro.SetUrl("https://oauth2.googleapis.com/token")
    return ro
end function

function refreshToken()
    print "Refreshing Token"
    ro = prepareAuthRequest()
    ro.AsyncPostFromString("client_id="+m.creds.client_id + m.br + "client_secret="+m.creds.client_secret + m.br + "grant_type=refresh_token" + m.br + "refresh_token="+m.sec.Read("RefreshToken"))
    msg = wait(0, m.port)
    if msg.getResponseCode() < 300
        msg = ParseJson(msg.getString())
        m.sec.Write("AccessToken",msg.access_token)
        m.sec.Flush()
    else
        print msg.GetFailureReason()
    end if
end function

function getTokens()    
    ro = prepareAuthRequest()
    ro.AsyncPostFromString("client_id="+m.creds.client_id + m.br + "client_secret="+m.creds.client_secret + m.br + "grant_type=authorization_code" + m.br + "redirect_uri=urn:ietf:wg:oauth:2.0:oob" + m.br + "code="+m.top.code)
    msg = wait(0, m.port)
    if msg.getResponseCode() < 300
        msg = ParseJson(msg.getString())
        m.sec.Write("AccessToken",msg.access_token)
        m.sec.Write("RefreshToken",msg.refresh_token)
        m.sec.Flush()
    else
        print msg.GetFailureReason()
    end if
    m.top.finished = True
end function

function getAlbums(retry = True, pageToken = invalid)
    ro = prepareRequest()
    url = "https://photoslibrary.googleapis.com/v1/albums"
    if pageToken <> invalid
        url = url + "?pageToken="+pageToken
    end if
    ro.setUrl(url)
    ro.AddHeader("Authorization","Bearer "+m.sec.Read("AccessToken"))
    ro.AsyncGetToString()
    msg = wait(0, m.port)
    if msg.getResponseCode() >= 400
        if retry
            print msg.GetFailureReason()
            refreshToken()
            getAlbums(False, pageToken)
        else
            m.top.finished = True
        end if
    else
        msg = parseJson(msg.getString())
        if msg.albums <> invalid
            for each a in msg.albums
                m.response.addTail(a)
            end for
        end if
        if msg.nextPageToken <> invalid
            getAlbums(True,msg.nextPageToken)
        else
            m.top.response = m.response.toArray()
            m.top.finished = True
        end if
    end if
end function

function getContent(retry = True, pageToken = invalid)
    ro = prepareRequest()
    url = "https://photoslibrary.googleapis.com/v1/mediaItems:search"
    if pageToken <> invalid
        url = url + "?pageToken="+pageToken
    end if
    ro.setUrl(url)
    ro.AddHeader("Authorization","Bearer "+m.sec.Read("AccessToken"))
    ro.AddHeader("Content-type","application/json")
    ro.AsyncPostFromString(formatJson({"pageSize":100,"albumId":m.top.album.id}))
    msg = wait(0, m.port)
    if msg.getResponseCode() >= 400
        if retry
            print msg.GetFailureReason()
            refreshToken()
            getContent(False, pageToken)
        else
            m.top.finished = True
        end if
    else
        msg = parseJson(msg.getString())
        if msg.mediaItems <> invalid
            for each a in msg.mediaItems
                m.response.addTail(a)
            end for
        end if
        if msg.nextPageToken <> invalid
            getContent(True,msg.nextPageToken)
        else
            m.top.response = m.response.toArray()
            m.top.finished = True
        end if
    end if
end function