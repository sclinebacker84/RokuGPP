function init()
    sec = CreateObject("roRegistrySection", "GPPAuth")
    ' for each k in sec.getKeyList()
    '     sec.delete(k)
    ' end for
    if not (sec.Exists("AccessToken") and sec.Exists("RefreshToken"))
        m.activeScreen = createObject("roSGNode", "Auth")
        m.activeScreen.findNode("kb").observeField("close","onAuthTaskFinish")
        m.top.appendChild(m.activeScreen)
    else
        startSearchScreen()
    end if
end function

function onAuthTaskFinish(a)
    m.top.removeChild(m.activeScreen)
    startSearchScreen()
end function

function startSearchScreen()
    m.activeScreen = createObject("roSGNode", "Search")
    m.top.appendChild(m.activeScreen)
end function