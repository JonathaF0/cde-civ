--[[
    CDECAD Civilian Manager - NUI Handler
    Handles NUI callbacks and messages
]]

-- Close ID card when clicked
RegisterNUICallback('closeID', function(data, cb)
    cb('ok')
end)

-- Handle escape key
RegisterNUICallback('escape', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
