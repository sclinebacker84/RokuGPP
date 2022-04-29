function init()
    m.deviceInfo = createObject("roDeviceInfo")
    m.uiResolution = m.deviceInfo.getUIResolution()
    m.sec = CreateObject("roRegistrySection", "GPPAuth")

    m.albumNode = m.top.findNode("albums")
    m.albumNode.observeField("itemSelected","onAlbumSelected")
    
    m.lgroup = m.top.findNode("lgroup")
    m.lgroup.translation = [100, 30]
    m.albums = m.top.findNode("albums")
    m.lgroupTitle = m.top.findNode("lgroupTitle")

    m.contentNode = m.top.findNode("content")
    m.contentNode.observeField("itemSelected","onContentSelected")

    m.rgroup = m.top.findNode("rgroup")
    m.rgroup.translation = [500, 30]
    m.content = m.top.findNode("content")
    m.content.itemSize = [m.content.itemSize[0] + 300, m.content.itemSize[1]]
    m.rgroupTitle = m.top.findNode("rgroupTitle")
    
    fetchAlbums()
end function

function sort(a,k,useRegex=False)
    d = {}
    r = createObject("roRegex","\d+","i")
    for each i in a:
        if useRegex
            m = r.MatchAll(CreateObject("roPath","pkg:/"+i[k]).split()["basename"])
            if m.count() > 0
                m = m[m.Count()-1][0]
                while Len(m) < 3
                    m = "0"+m
                end while
            else
                m = i[k]
            end if
            d[m] = i
        else
            d[i[k]] = i
        end if
    end for
    l = createObject("roList")
    for each i in d.keys()
        l.addTail(d[i])
    end for
    return l.toArray()
end function

'Album stuff

function onAlbumSelected(a)
    m.lastAlbumSelected = a.getData()
    fetchContent(m.albums.response[m.albumNode.content.getChild(a.getData()).description.toInt()])
end function

function fetchAlbums()
    m.pg = createObject("roSGNode", "ProgressDialog")
    m.pg.title = "Getting Albums"
    m.top.appendChild(m.pg)
    m.albums = createObject("roSGNode", "GoogleAPI")
    m.albums.functionName = "getAlbums"
    m.albums.observeField("finished","onAlbumsFetched")
    m.albums.control = "RUN"
end function

function onAlbumsFetched(a)
    m.top.removeChild(m.pg)
    m.albums.response = sort(m.albums.response,"title")
    searchAlbums()
end function

function searchAlbums(s = invalid)
    if(s <> m.lastAlbumSearch)
        m.lastAlbumSelected = 0
    end if
    m.lastAlbumSearch = s
    content = createObject("roSGNode", "ContentNode")
    m.albumNode.content = content
    m.albumNode.setFocus(True)
    i = 0
    for each a in m.albums.response
        if s = invalid or instr(0,lcase(a.title),s) > 0
            n = createObject("roSGNode", "ContentNode")
            n.title = a.title
            n.description = i.toStr()
            content.appendChild(n)
        end if
        i = i + 1
    end for
    m.albumNode.jumpToItem = m.lastAlbumSelected
    m.lgroupTitle.text = "Albums"
    if(s <> invalid)
        m.lgroupTitle.text = m.lgroupTitle.text + " (Searching for: " + s + ")"
    end if
end function

'Content stuff

function fetchContent(album)
    m.pg = createObject("roSGNode", "ProgressDialog")
    m.pg.title = "Getting Content for: "+album.title
    m.top.appendChild(m.pg)
    m.content = createObject("roSGNode", "GoogleAPI")
    m.content.functionName = "getContent"
    m.content.album = album
    m.content.observeField("finished","onContentFetched")
    m.content.control = "RUN"
end function

function onContentFetched(a)
    m.top.removeChild(m.pg)
    m.content.response = sort(m.content.response,"filename",True)
    searchContent()
end function

function onContentSelected(a)
    m.lastContentSelected = a.getData()
    fetchItem(m.content.response[m.contentNode.content.getChild(a.getData()).description.toInt()])
end function

function fetchItem(item)
    m.pg = createObject("roSGNode", "ProgressDialog")
    m.pg.title = "Refreshing: "+item.filename
    m.top.appendChild(m.pg)
    m.item = createObject("roSGNode", "GoogleAPI")
    m.item.functionName = "getItem"
    m.item.item = item
    m.item.observeField("finished","onItemFetched")
    m.item.control = "RUN"
end function

function onItemFetched(a)
    m.top.removeChild(m.pg)
    a = m.item.item
    if(a.mediaMetadata.video <> invalid)
        playVideo(a)
    else if(a.mediaMetadata.photo <> invalid)
        m.vid = createObject("roSGNode","Poster")
        m.vid.translation = [160,8]
        m.vid.uri = a.baseUrl+"=h"+m.uiResolution.height.toStr()+"-w"+m.uiResolution.width.toStr()
        m.top.appendChild(m.vid)
        m.vid.setFocus(True)
    end if
end function

function playVideo(a)
    m.vid = createObject("roSGNode","Video")
    m.vidC = createObject("roSGNode","ContentNode")
    m.vidC.ContentType = "movie"
    res = "m18"
    m.vidC.url = a.baseUrl+"=dv-"+res
    m.vidC.Title = a.filename
    m.vid.content = m.vidC
    m.vid.observeField("state","onVideoStateChange")
    m.top.appendChild(m.vid)
    m.vid.setFocus(True)
    m.vid.control = "play"
end function

function searchContent(s = invalid)
    if m.lastContentSearch <> s
        m.lastContentSelected = 0
    end if
    m.lastContentSearch = s
    content = createObject("roSGNode", "ContentNode")
    m.contentNode.content = content
    m.contentNode.setFocus(True)
    i = 0
    for each a in m.content.response
        if s = invalid or instr(0,lcase(a.filename),s) > 0
            n = createObject("roSGNode", "ContentNode")
            n.title = a.filename
            n.description = i.toStr()
            content.appendChild(n)
        end if
        i = i + 1
    end for
    m.contentNode.jumpToItem = m.lastContentSelected
    m.rgroupTitle.text = "Items"
    if(s <> invalid)
        m.rgroupTitle.text = m.rgroupTitle.text + " (Searching for: " + s + ")"
    end if
end function

function handleSearch(a)
    if a.getData() = 0
        if m.albumNode.id = m.lastFocused.id
            searchAlbums(lcase(m.kb.text))
        else
            searchContent(lcase(m.kb.text))
        end if
    end if
    m.kb.close = True
    m.top.removeChild(m.kb)
    m.lastFocused.setFocus(True)
end function

function createKb()
    m.lastFocused = m.albumNode
    if(m.contentNode.hasFocus())
        m.lastFocused = m.contentNode
    end if
    m.kb = createObject("roSGNode","KeyboardDialog")
    m.kb.buttons = ["OK","Cancel"]
    m.kb.title = "Search"
    m.top.appendChild(m.kb)
    m.kb.setFocus(True)
    m.kb.observeField("buttonSelected","handleSearch")
end function

function showVideoInfoModal()
    a = m.content.response[m.contentNode.content.getChild(m.contentNode.itemFocused).description.toInt()]
    m.dg = createObject("roSGNode","Dialog")
    m.dg.title = "Info"
    m.dg.buttons = ["Ok"]
    m.dg.observeField("buttonSelected","closeVideoInfoModal")
    m.dg.message = formatJson(a.mediaMetadata)
    m.top.appendChild(m.dg)
    m.dg.setFocus(True)
end function

function closeVideoInfoModal()
    m.top.removeChild(m.dg)
    m.contentNode.setFocus(True)
end function

function onKeyEvent(key,press) as Boolean
    if(press)
        if(key = "options" and (m.contentNode.hasFocus() or m.albumNode.hasFocus()))
            createKb()
            return False
        else if(key = "back")
            if m.contentNode.hasFocus()
                searchAlbums(m.lastAlbumSearch)
            else if m.vid <> invalid and m.vid.hasFocus()
                if(m.vid.control <> invalid)
                    m.vid.control = "stop"
                end if
                m.top.removeChild(m.vid)
                searchContent(m.lastContentSearch)
            end if
            return True
        else if(key = "right" and m.contentNode.hasFocus())
            showVideoInfoModal()
            return False
        end if
    end if
    return True
end function

function onVideoStateChange(a)
    a = a.getData()
    if a = "finished"
        if m.lastContentSelected < (m.content.response.count() - 1)
            m.top.removeChild(m.vid)
            m.lastContentSelected = m.lastContentSelected + 1
            fetchItem(m.content.response[m.lastContentSelected])
        else
            m.lastContentSelected = 0
        end if
        m.contentNode.jumpToItem = m.lastContentSelected
    end if
end function