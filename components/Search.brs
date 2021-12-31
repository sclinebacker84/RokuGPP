function init()
    m.sec = CreateObject("roRegistrySection", "GPPAuth")

    m.albumNode = m.top.findNode("albums")
    m.albumNode.observeField("itemSelected","onAlbumSelected")
    
    m.lgroup = m.top.findNode("lgroup")
    m.lgroup.translation = [100, 30]
    m.lgroupTitle = m.top.findNode("lgroupTitle")

    m.contentNode = m.top.findNode("content")
    m.contentNode.observeField("itemSelected","onContentSelected")

    m.rgroup = m.top.findNode("rgroup")
    m.rgroup.translation = [500, 30]
    m.rgroupTitle = m.top.findNode("rgroupTitle")
    
    fetchAlbums()
end function

function sort(a,k)
    d = {}
    for each i in a:
        d[i[k]] = i
    end for
    l = createObject("roList")
    for each i in d.keys()
        l.addTail(d[i])
    end for
    return l.toArray()
end function

'Album stuff

function onAlbumSelected(a)
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
    m.lgroupTitle.text = "Albums"
    if(s <> invalid)
        m.lgroupTitle.text = m.lgroupTitle.text + " (Searching for: " + s + ")"
    end if
end function

'Content stuff

function onContentSelected(a)
    a = m.content.response[m.contentNode.content.getChild(a.getData()).description.toInt()]
    m.vid = createObject("roSGNode","Video")
    m.vidC = createObject("roSGNode","ContentNode")
    m.vidC.ContentType = "movie"
    m.vidC.url = a.baseUrl+"=dv-m18"
    m.vidC.Title = a.filename
    m.vid.content = m.vidC
    m.vid.observeField("state","onVideoStateChange")
    m.top.appendChild(m.vid)
    m.vid.setFocus(True)
    m.vid.control = "play"
end function

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
    m.content.response = sort(m.content.response,"filename")
    searchContent()
end function

function searchContent(s = invalid)
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
    m.rgroupTitle.text = "Items"
    if(s <> invalid)
        m.rgroupTitle.text = m.rgroupTitle.text + " (Searching for: " + s + ")"
    end if
end function

function handleSearch(a)
    if a.getData() = 0
        m.kb.close = True
        m.top.removeChild(m.kb)
        searchAlbums(lcase(m.kb.text))
    else
        print "searchContent"
    end if
end function

function createKb()
    m.kb = createObject("roSGNode","KeyboardDialog")
    m.kb.buttons = ["OK","Cancel"]
    m.kb.title = "Search"
    m.top.appendChild(m.kb)
    m.kb.setFocus(True)
    m.kb.observeField("buttonSelected","handleSearch")
end function

function onKeyEvent(key,press) as Boolean
    if(press)
        if(key = "options")
            createKb()
        end if
    end if
    return False
end function