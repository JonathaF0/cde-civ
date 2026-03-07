--[[
    CDECAD Civilian Manager - Client Script
    Handles commands, UI, and local state
]]

local ActiveCivilian = nil
local IsIDShowing = false

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

local function Debug(...)
    if Config.Debug then
        print('[CDECAD-CIVMANAGER]', ...)
    end
end

local function Notify(type, message)
    if Config.Notifications.UseOxLib then
        lib.notify({
            title = 'Civilian Manager',
            description = message,
            type = type,
            duration = Config.Notifications.Duration,
            position = Config.Notifications.Position
        })
    else
        -- Fallback to chat
        TriggerEvent('chat:addMessage', {
            color = type == 'success' and {0, 255, 0} or type == 'error' and {255, 0, 0} or {255, 255, 255},
            args = {'[CivManager]', message}
        })
    end
end

-- Get current vehicle info
local function GetCurrentVehicleInfo()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        return nil
    end
    
    local plate = GetVehicleNumberPlateText(vehicle):gsub('%s+', '')
    local model = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(model)
    local makeName = GetMakeNameFromVehicleModel(model)
    
    -- Get vehicle color
    local primaryColor, secondaryColor = GetVehicleColours(vehicle)
    local colorNames = {
        [0] = 'Black', [1] = 'Graphite', [2] = 'Black Steel', [3] = 'Dark Silver',
        [4] = 'Silver', [5] = 'Blue Silver', [6] = 'Steel Gray', [7] = 'Shadow Silver',
        [8] = 'Stone Silver', [9] = 'Midnight Silver', [10] = 'Gun Metal', [11] = 'Anthracite Gray',
        [27] = 'Red', [28] = 'Torino Red', [29] = 'Formula Red', [30] = 'Blaze Red',
        [31] = 'Graceful Red', [32] = 'Garnet Red', [33] = 'Desert Red', [34] = 'Cabernet Red',
        [35] = 'Candy Red', [36] = 'Sunrise Orange', [37] = 'Classic Gold', [38] = 'Orange',
        [49] = 'Dark Green', [50] = 'Racing Green', [51] = 'Sea Green', [52] = 'Olive Green',
        [53] = 'Green', [54] = 'Gasoline Blue Green', [55] = 'Midnight Blue', [56] = 'Dark Blue',
        [57] = 'Saxony Blue', [58] = 'Blue', [59] = 'Mariner Blue', [60] = 'Harbor Blue',
        [61] = 'Diamond Blue', [62] = 'Surf Blue', [63] = 'Nautical Blue', [64] = 'Bright Blue',
        [65] = 'Purple Blue', [66] = 'Spinnaker Blue', [67] = 'Ultra Blue', [68] = 'Bright Blue',
        [88] = 'Yellow', [89] = 'Race Yellow', [91] = 'Bronze', [92] = 'Yellow Bird',
        [93] = 'Lime', [94] = 'Champagne', [95] = 'Pueblo Beige', [96] = 'Dark Ivory',
        [97] = 'Choco Brown', [98] = 'Golden Brown', [99] = 'Light Brown', [100] = 'Straw Beige',
        [101] = 'Moss Brown', [102] = 'Bison Brown', [103] = 'Creek Brown', [104] = 'Feltzer Brown',
        [105] = 'Maple Brown', [106] = 'Beechwood', [107] = 'Sienna Brown', [108] = 'Saddle',
        [109] = 'Moss', [110] = 'Woodbeech', [111] = 'White', [112] = 'Frost White',
        [113] = 'Worn White', [131] = 'Bright White', [134] = 'Pink', [135] = 'Salmon Pink',
        [136] = 'Hot Pink', [137] = 'Pfsiter Pink', [138] = 'Bright Orange', [139] = 'Orange',
        [140] = 'Blue', [141] = 'White', [142] = 'Blue', [143] = 'Taxi Yellow',
        [145] = 'Green', [146] = 'Brown', [150] = 'Worn Red', [151] = 'Worn Golden Red',
        [152] = 'Worn Dark Red', [153] = 'Worn Dark Green', [155] = 'Worn Blue', [156] = 'Worn Dark Blue',
    }
    
    local colorName = colorNames[primaryColor] or 'Unknown'
    
    return {
        plate = plate,
        model = displayName or 'Unknown',
        make = makeName or 'Unknown',
        color = colorName,
        year = tostring(2020 + math.random(0, 5)) -- Fake year since GTA doesn't have this
    }
end

-- =============================================================================
-- KVP PERSISTENCE (Client-side)
-- =============================================================================

local function SaveCivilianToKVP(civilianId)
    if Config.Persistence == 'kvp' then
        SetResourceKvp('cdecad_selected_civ', civilianId or '')
        Debug('Saved civilian to KVP:', civilianId)
    end
end

local function LoadCivilianFromKVP()
    if Config.Persistence == 'kvp' then
        local civilianId = GetResourceKvpString('cdecad_selected_civ')
        if civilianId and civilianId ~= '' then
            Debug('Loaded civilian from KVP:', civilianId)
            return civilianId
        end
    end
    return nil
end

local function ClearCivilianFromKVP()
    if Config.Persistence == 'kvp' then
        DeleteResourceKvp('cdecad_selected_civ')
        Debug('Cleared civilian from KVP')
    end
end

-- =============================================================================
-- CIVILIAN SELECTOR UI
-- =============================================================================

local function OpenCivilianSelector()
    -- Fetch civilians from server
    local result = lib.callback.await('cdecad-civmanager:getCivilians', false)
    
    if not result.success then
        Notify('error', result.error or 'Failed to fetch civilians')
        return
    end
    
    if not result.civilians or #result.civilians == 0 then
        Notify('error', 'No civilians found for your account. Create one in the CAD first.')
        return
    end
    
    Debug('Received civilians:', json.encode(result.civilians))
    
    -- Build options for ox_lib menu
    local options = {}
    
    for _, civ in ipairs(result.civilians) do
        -- Handle different field name formats from API
        local firstName = civ.firstName or civ.firstname or civ.first_name or 'Unknown'
        local lastName = civ.lastName or civ.lastname or civ.last_name or 'Unknown'
        local dob = civ.dob or civ.dateOfBirth or civ.date_of_birth or civ.birthdate or 'Unknown'
        local ssn = civ.ssn or civ.citizenid or civ.id or 'Unknown'
        
        local label = firstName .. ' ' .. lastName
        local description = 'DOB: ' .. tostring(dob)
        
        if ssn and ssn ~= 'Unknown' then
            description = description .. ' | ID: ' .. tostring(ssn)
        end
        
        -- Normalize the civilian data for storage
        local normalizedCiv = {
            id = civ.id or civ._id,
            firstName = firstName,
            lastName = lastName,
            dob = dob,
            dateOfBirth = dob,
            ssn = ssn,
            gender = civ.gender,
            phone = civ.phone,
            address = civ.address,
            height = civ.height,
            weight = civ.weight,
            eyeColor = civ.eyeColor or civ.eye_color,
            hairColor = civ.hairColor or civ.hair_color,
            mugshotUrl = civ.mugshotUrl or civ.mugshot_url or civ.photoUrl,
            licenses = civ.licenses
        }
        
        table.insert(options, {
            title = label,
            description = description,
            icon = 'user',
            onSelect = function()
                SelectCivilian(normalizedCiv)
            end
        })
    end
    
    -- Add clear option
    table.insert(options, {
        title = 'Clear Selection',
        description = 'Remove current civilian selection',
        icon = 'xmark',
        onSelect = function()
            ClearCivilian()
        end
    })
    
    lib.registerContext({
        id = 'cdecad_civ_selector',
        title = 'Select Civilian',
        options = options
    })
    
    lib.showContext('cdecad_civ_selector')
end

-- Select a civilian
function SelectCivilian(civData)
    Debug('SelectCivilian called with:', json.encode(civData))
    
    -- Clear old civilian first
    ActiveCivilian = nil
    
    -- Set new civilian
    ActiveCivilian = civData
    
    -- Save to persistence
    local saveId = civData.ssn or civData.id
    Debug('Saving to KVP with ID:', saveId)
    SaveCivilianToKVP(saveId)
    
    -- Notify server
    TriggerServerEvent('cdecad-civmanager:selectCivilian', civData)
    
    Notify('success', 'Now playing as: ' .. (civData.firstName or 'Unknown') .. ' ' .. (civData.lastName or 'Unknown'))
    
    Debug('ActiveCivilian is now:', ActiveCivilian and (ActiveCivilian.firstName .. ' ' .. ActiveCivilian.lastName) or 'nil')
end

-- Clear current civilian
function ClearCivilian()
    Debug('ClearCivilian called')
    ActiveCivilian = nil
    ClearCivilianFromKVP()
    TriggerServerEvent('cdecad-civmanager:selectCivilian', nil)
    Notify('success', 'Civilian selection cleared')
end

-- =============================================================================
-- COMMANDS
-- =============================================================================

-- /setciv - Open civilian selector
RegisterCommand(Config.Commands.SelectCiv, function()
    OpenCivilianSelector()
end, false)

-- /myciv - Show current civilian info
RegisterCommand(Config.Commands.ShowInfo, function()
    if not ActiveCivilian then
        Notify('error', 'No civilian selected. Use /' .. Config.Commands.SelectCiv)
        return
    end
    
    local info = string.format('%s %s | DOB: %s | Phone: %s',
        ActiveCivilian.firstName,
        ActiveCivilian.lastName,
        ActiveCivilian.dob or ActiveCivilian.dateOfBirth or 'Unknown',
        ActiveCivilian.phone or 'Unknown'
    )
    
    Notify('info', info)
end, false)

-- /showid - Show ID to nearby players
RegisterCommand(Config.Commands.ShowID, function()
    if not ActiveCivilian then
        Notify('error', 'No civilian selected. Use /' .. Config.Commands.SelectCiv)
        return
    end
    
    TriggerServerEvent('cdecad-civmanager:showID')
end, false)

-- /bank - Open bank (placeholder - integrate with your economy)
RegisterCommand(Config.Commands.Bank, function()
    if not Config.Bank.Enabled then
        Notify('error', 'Bank is disabled')
        return
    end
    
    if not ActiveCivilian then
        Notify('error', 'No civilian selected. Use /' .. Config.Commands.SelectCiv)
        return
    end
    
    -- For now just show balance info
    -- You can integrate this with your actual banking system
    Notify('info', 'Bank account for: ' .. ActiveCivilian.firstName .. ' ' .. ActiveCivilian.lastName)
    
    -- TODO: Open actual bank UI or integrate with existing bank system
end, false)

-- /regveh - Register current vehicle
RegisterCommand(Config.Commands.RegisterVehicle, function()
    if not Config.VehicleRegistration.Enabled then
        Notify('error', 'Vehicle registration is disabled')
        return
    end
    
    if not ActiveCivilian then
        Notify('error', 'No civilian selected. Use /' .. Config.Commands.SelectCiv)
        return
    end
    
    if Config.VehicleRegistration.RequireInVehicle then
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 then
            Notify('error', 'You must be in a vehicle to register it')
            return
        end
    end
    
    local vehicleInfo = GetCurrentVehicleInfo()
    
    if not vehicleInfo then
        Notify('error', 'Could not get vehicle information')
        return
    end
    
    -- Confirm registration
    local confirm = lib.alertDialog({
        header = 'Register Vehicle',
        content = string.format('Register this vehicle?\n\n**Plate:** %s\n**Make:** %s\n**Model:** %s\n**Color:** %s\n\n**Fee:** $%d',
            vehicleInfo.plate,
            vehicleInfo.make,
            vehicleInfo.model,
            vehicleInfo.color,
            Config.VehicleRegistration.Fee
        ),
        centered = true,
        cancel = true
    })
    
    if confirm ~= 'confirm' then
        return
    end
    
    -- Register with server
    local result = lib.callback.await('cdecad-civmanager:registerVehicle', false, vehicleInfo)
    
    if result.success then
        Notify('success', 'Vehicle registered: ' .. vehicleInfo.plate)
    else
        Notify('error', result.error or 'Failed to register vehicle')
    end
end, false)

-- /clearciv - Clear selected civilian
RegisterCommand(Config.Commands.ClearCiv, function()
    ClearCivilian()
end, false)

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

-- Receive notification from server
RegisterNetEvent('cdecad-civmanager:notify', function(type, message)
    Notify(type, message)
end)

-- Civilian set confirmation from server
RegisterNetEvent('cdecad-civmanager:civilianSet', function(civData)
    Debug('civilianSet event received from server')
    if civData then
        Debug('Server confirmed civilian:', civData.firstName, civData.lastName)
        -- Force update the local state
        ActiveCivilian = civData
    else
        Debug('Server cleared civilian')
        ActiveCivilian = nil
    end
end)

-- Receive ID from another player
RegisterNetEvent('cdecad-civmanager:receiveID', function(civData, fromName, cardStyle)
    Debug('Received ID from:', fromName, 'Data:', json.encode(civData))
    
    if Config.IDCard.ShowHTML then
        -- Show HTML ID card with server-provided style
        SendNUIMessage({
            action = 'showID',
            civilian = civData,
            from = fromName,
            duration = Config.IDCard.DisplayDuration,
            style = cardStyle or Config.IDCard.CardStyle
        })
        SetNuiFocus(false, false)
    end
    
    if Config.IDCard.ShowInChat then
        -- Show in chat/skybox
        local idText = string.format('[ID SHOWN by %s] %s %s | DOB: %s | SSN: %s',
            fromName,
            civData.firstName or 'Unknown',
            civData.lastName or 'Unknown',
            civData.dob or civData.dateOfBirth or 'Unknown',
            civData.ssn or 'Unknown'
        )
        
        TriggerEvent('chat:addMessage', {
            color = {66, 182, 245},
            args = {'', idText}
        })
    end
    
    if Config.IDCard.UseOxNotify then
        lib.notify({
            title = 'ID Shown by ' .. fromName,
            description = (civData.firstName or 'Unknown') .. ' ' .. (civData.lastName or 'Unknown'),
            type = 'info',
            duration = Config.IDCard.DisplayDuration
        })
    end
end)

-- Someone requested your ID
RegisterNetEvent('cdecad-civmanager:idRequested', function(requesterId, requesterName)
    if not ActiveCivilian then
        Notify('info', requesterName .. ' requested your ID, but you have no civilian selected.')
        return
    end
    
    -- Show a confirmation dialog
    local confirm = lib.alertDialog({
        header = 'ID Requested',
        content = '**' .. requesterName .. '** is requesting to see your ID.\n\nShow your ID to them?',
        centered = true,
        cancel = true
    })
    
    if confirm == 'confirm' then
        TriggerServerEvent('cdecad-civmanager:showIDToPlayer', requesterId)
    end
end)

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

CreateThread(function()
    -- Wait a bit for everything to load
    Wait(3000)
    
    -- Try to load last selected civilian
    local lastCivId = nil
    
    if Config.Persistence == 'kvp' then
        lastCivId = LoadCivilianFromKVP()
    elseif Config.Persistence == 'mysql' then
        lastCivId = lib.callback.await('cdecad-civmanager:loadLastCivilian', false)
    end
    
    if lastCivId then
        Debug('Found last civilian:', lastCivId)
        
        -- Fetch the civilian data
        local result = lib.callback.await('cdecad-civmanager:getCivilian', false, lastCivId)
        
        if result.success and result.civilian then
            ActiveCivilian = result.civilian
            TriggerServerEvent('cdecad-civmanager:selectCivilian', result.civilian)
            Notify('info', 'Restored civilian: ' .. result.civilian.firstName .. ' ' .. result.civilian.lastName)
        else
            Debug('Could not restore civilian, clearing KVP')
            ClearCivilianFromKVP()
        end
    end
end)

-- =============================================================================
-- EXPORTS
-- =============================================================================

exports('GetActiveCivilian', function()
    return ActiveCivilian
end)

exports('HasActiveCivilian', function()
    return ActiveCivilian ~= nil
end)

exports('OpenCivilianSelector', OpenCivilianSelector)

-- =============================================================================
-- CHAT SUGGESTIONS
-- =============================================================================

TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.SelectCiv, 'Select a civilian from your CAD account')
TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.ShowInfo, 'Show your current civilian info')
TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.ShowID, 'Show your ID to nearby players')
TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.Bank, 'Open your bank account')
TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.RegisterVehicle, 'Register your current vehicle')
TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.ClearCiv, 'Clear your civilian selection')

-- =============================================================================
-- OX_TARGET INTEGRATION
-- =============================================================================

CreateThread(function()
    -- Check if ox_target integration is enabled
    if not Config.IDCard.UseOxTarget then
        Debug('ox_target integration disabled in config')
        return
    end
    
    -- Wait for ox_target to be ready
    Wait(2000)
    
    -- Check if ox_target is available
    if GetResourceState('ox_target') ~= 'started' then
        Debug('ox_target not found, skipping target integration')
        return
    end
    
    -- Add target option to players
    exports.ox_target:addGlobalPlayer({
        {
            name = 'cdecad_show_id',
            icon = 'fas fa-id-card',
            label = 'Show ID',
            distance = 3.0,
            onSelect = function(data)
                if not ActiveCivilian then
                    Notify('error', 'No civilian selected. Use /' .. Config.Commands.SelectCiv)
                    return
                end
                
                -- Get the target player's server ID
                local targetPed = data.entity
                local targetPlayerId = NetworkGetPlayerIndexFromPed(targetPed)
                local targetServerId = GetPlayerServerId(targetPlayerId)
                
                Debug('ox_target Show ID - targetPed:', targetPed, 'targetPlayerId:', targetPlayerId, 'targetServerId:', targetServerId)
                
                if targetServerId and targetServerId > 0 then
                    -- Send ID to specific player via server
                    TriggerServerEvent('cdecad-civmanager:showIDToPlayer', targetServerId)
                    Notify('success', 'Showing ID to player')
                else
                    Notify('error', 'Could not identify target player')
                end
            end,
            canInteract = function(entity, distance, coords, name, bone)
                return ActiveCivilian ~= nil
            end
        },
        {
            name = 'cdecad_request_id',
            icon = 'fas fa-hand-paper',
            label = 'Request ID',
            distance = 3.0,
            onSelect = function(data)
                local targetPed = data.entity
                local targetPlayerId = NetworkGetPlayerIndexFromPed(targetPed)
                local targetServerId = GetPlayerServerId(targetPlayerId)
                
                Debug('ox_target Request ID - targetServerId:', targetServerId)
                
                if targetServerId and targetServerId > 0 then
                    TriggerServerEvent('cdecad-civmanager:requestID', targetServerId)
                    Notify('info', 'Requested ID from player')
                else
                    Notify('error', 'Could not identify target player')
                end
            end
        }
    })
    
    print('[CDECAD-CIVMANAGER] ox_target integration loaded')
end)

print('[CDECAD-CIVMANAGER] Client script loaded')
