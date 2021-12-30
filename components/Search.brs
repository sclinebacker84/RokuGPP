function init()
    m.items = m.top.findNode("items")
    m.items.observeField("itemSelected","onItemSelected")
    m.lgroup = m.top.findNode("lgroup")
    m.lgroupTitle = m.top.findNode("lgroupTitle")
    m.lgroupTitle.text = "Albums"
    m.lgroup.translation = [100, 30]
    m.albums = createObject("roSGNode", "GoogleAPI")
    m.albums.functionName = "getAlbums"
    m.albums.observeField("finished","onAlbumsFinished")
    m.albums.control = "RUN"
    m.pg = createObject("roSGNode", "ProgressDialog")
    m.pg.title = "Getting Albums"
    m.top.appendChild(m.pg)
end function

function onAlbumsFinished(a)
    m.top.removeChild(m.pg)
    searchAlbums()
end function

function refreshContent()
    m.content = createObject("roSGNode", "ContentNode")
    m.items.content = m.content
    m.items.setFocus(True)
end function

function onItemSelected(a)
    print m.albums.response[a.getData()]
end function

function searchAlbums(s = invalid)
    refreshContent()
    for each a in m.albums.response
        if s = invalid
            n = createObject("roSGNode", "ContentNode")
            n.title = a.title
            m.content.appendChild(n)
        end if
    end for
end function