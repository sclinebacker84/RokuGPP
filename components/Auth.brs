function init()
    m.kb = m.top.findNode("kb")
    m.kb.title = "Enter Auth Code"
    m.kb.buttons = ["Ok"]        
    m.kb.observeField("buttonSelected","onButtonClick")
    m.kb.setFocus(True)
end function

function onButtonClick(a)
    if a.getData() = 0
        m.pg = createObject("roSGNode", "ProgressDialog")
        m.pg.title = "Fetching Tokens"
        m.top.appendChild(m.pg)
        at = createObject("roSGNode", "GoogleAPI")
        at.functionName = "getTokens"
        at.setField("code",m.kb.text)
        at.observeField("finished","onFinished")
        at.control = "RUN"
    end if
end function

function onFinished()
    m.pg.close = True
    m.top.removeChild(m.pg)
    m.kb.close = True
end function