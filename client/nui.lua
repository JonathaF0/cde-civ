--[[
    CDECAD Civilian Manager - NUI Handler
    Handles NUI callbacks and messages
]]

-- Close ID card when clicked
RegisterNUICallback('closeID', function(data, cb)
    cb('ok')
end)

-- getMugshot is no longer used — the NUI JS fetches the photo directly from
-- the CAD API via browser fetch() (see html/script.js showIDCard).
-- Kept as a no-op so existing SavedNUICallbacks don't error if called.
RegisterNUICallback('getMugshot', function(data, cb)
    cb({ mugshotUrl = nil })
end)

-- Handle escape key
RegisterNUICallback('escape', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- =============================================================================
-- BANK NUI CALLBACKS
-- =============================================================================

-- Close bank panel
RegisterNUICallback('closeBank', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Deposit
RegisterNUICallback('bankDeposit', function(data, cb)
    local result = lib.callback.await('cdecad-civmanager:bankDeposit', false,
        data.civilianId, tonumber(data.amount), data.description)
    cb(result)
end)

-- Withdraw
RegisterNUICallback('bankWithdraw', function(data, cb)
    local result = lib.callback.await('cdecad-civmanager:bankWithdraw', false,
        data.civilianId, tonumber(data.amount), data.description)
    cb(result)
end)

-- Transfer
RegisterNUICallback('bankTransfer', function(data, cb)
    local result = lib.callback.await('cdecad-civmanager:bankTransfer', false,
        data.fromCivilianId, data.toAccountNumber, tonumber(data.amount), data.description)
    cb(result)
end)
