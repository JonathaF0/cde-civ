--[[
    CDECAD Civilian Manager - Server Script
    Handles API calls, persistence, and data management
]]

-- Store active civilians per player (source -> civilian data)
local ActiveCivilians = {}

-- Cache community settings (fetched once on startup)
local CommunitySettings = nil

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

local function Debug(...)
    if Config.Debug then
        print('[CDECAD-CIVMANAGER]', ...)
    end
end

-- Get player's Discord ID
local function GetDiscordId(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.find(id, 'discord:') then
            return id:gsub('discord:', '')
        end
    end
    return nil
end

-- Get player's license (for KVP key)
local function GetLicense(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    return nil
end

-- =============================================================================
-- API FUNCTIONS
-- =============================================================================

-- Make API request to CDECAD
local function APIRequest(method, endpoint, data, callback)
    local url = Config.API_URL .. endpoint
    
    local headers = {
        ['Content-Type'] = 'application/json',
        ['x-api-key'] = Config.API_KEY
    }
    
    Debug('API Request:', method, url)
    
    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        Debug('API Response:', statusCode)
        
        local success = statusCode >= 200 and statusCode < 300
        local responseData = nil
        
        if responseText and responseText ~= '' then
            local ok, decoded = pcall(json.decode, responseText)
            if ok then
                responseData = decoded
            end
        end
        
        if callback then
            callback(success, responseData, statusCode)
        end
    end, method, data and json.encode(data) or '', headers)
end

-- Get all civilians for a Discord ID
local function GetCiviliansForDiscord(discordId, callback)
    APIRequest('GET', '/civilian/fivem-civilians-by-discord/' .. discordId .. '?communityId=' .. Config.COMMUNITY_ID, nil, callback)
end

-- Get civilian by SSN (citizenid)
local function GetCivilianBySSN(ssn, callback)
    APIRequest('GET', '/civilian/fivem-civilian/' .. ssn .. '?communityId=' .. Config.COMMUNITY_ID, nil, callback)
end

-- Register a vehicle
local function RegisterVehicle(civilianId, vehicleData, callback)
    local payload = {
        plate = vehicleData.plate,
        ownerId = civilianId,
        communityId = Config.COMMUNITY_ID,
        make = vehicleData.make or 'Unknown',
        model = vehicleData.model,
        color = vehicleData.color or 'Unknown',
        year = vehicleData.year or os.date('%Y')
    }
    
    APIRequest('POST', '/civilian/fivem-register-vehicle', payload, callback)
end

-- Fetch community settings from API
local function FetchCommunitySettings(callback)
    APIRequest('GET', '/civilian/fivem-community-settings?communityId=' .. Config.COMMUNITY_ID, nil, function(success, data, statusCode)
        if success and data then
            CommunitySettings = data
            Debug('Fetched community settings:', json.encode(data))
        else
            Debug('Failed to fetch community settings, using defaults')
            CommunitySettings = {
                communityName = 'Unknown',
                jurisdiction = {
                    city = '',
                    county = '',
                    state = Config.IDCard.CardStyle.StateName or 'San Andreas'
                }
            }
        end
        
        if callback then
            callback(CommunitySettings)
        end
    end)
end

-- =============================================================================
-- PERSISTENCE FUNCTIONS
-- =============================================================================

-- Save selected civilian (server-side for MySQL, or tell client for KVP)
local function SaveSelectedCivilian(source, civilianId)
    if Config.Persistence == 'mysql' then
        local discordId = GetDiscordId(source)
        if discordId then
            MySQL.Async.execute([[
                INSERT INTO ]] .. Config.MySQLTable .. [[ (discord_id, civilian_id, updated_at)
                VALUES (@discord, @civ, NOW())
                ON DUPLICATE KEY UPDATE civilian_id = @civ, updated_at = NOW()
            ]], {
                ['@discord'] = discordId,
                ['@civ'] = civilianId
            })
            Debug('Saved civilian to MySQL:', discordId, civilianId)
        end
    else
        -- KVP is handled client-side, just acknowledge
        Debug('KVP persistence handled client-side')
    end
end

-- Load selected civilian from MySQL
local function LoadSelectedCivilian(source, callback)
    if Config.Persistence == 'mysql' then
        local discordId = GetDiscordId(source)
        if discordId then
            MySQL.Async.fetchScalar([[
                SELECT civilian_id FROM ]] .. Config.MySQLTable .. [[ WHERE discord_id = @discord
            ]], {
                ['@discord'] = discordId
            }, function(civilianId)
                callback(civilianId)
            end)
        else
            callback(nil)
        end
    else
        -- KVP is handled client-side
        callback(nil)
    end
end

-- =============================================================================
-- CALLBACKS
-- =============================================================================

-- Get community settings
lib.callback.register('cdecad-civmanager:getCommunitySettings', function(source)
    if CommunitySettings then
        return CommunitySettings
    end
    
    -- If not cached yet, fetch synchronously
    local result = nil
    local completed = false
    
    FetchCommunitySettings(function(settings)
        result = settings
        completed = true
    end)
    
    while not completed do
        Wait(10)
    end
    
    return result
end)

-- Get civilians for player
lib.callback.register('cdecad-civmanager:getCivilians', function(source)
    local discordId = GetDiscordId(source)
    
    if not discordId then
        Debug('No Discord ID found for source:', source)
        return { success = false, error = 'No Discord ID found. Make sure Discord is linked.' }
    end
    
    Debug('Fetching civilians for Discord:', discordId)
    
    local result = nil
    local completed = false
    
    GetCiviliansForDiscord(discordId, function(success, data, statusCode)
        if success and data then
            result = { success = true, civilians = data }
        else
            result = { success = false, error = 'Failed to fetch civilians', statusCode = statusCode }
        end
        completed = true
    end)
    
    while not completed do
        Wait(10)
    end
    
    return result
end)

-- Get specific civilian data
lib.callback.register('cdecad-civmanager:getCivilian', function(source, civilianId)
    local result = nil
    local completed = false
    
    GetCivilianBySSN(civilianId, function(success, data, statusCode)
        if success and data then
            result = { success = true, civilian = data }
        else
            result = { success = false, error = 'Civilian not found' }
        end
        completed = true
    end)
    
    while not completed do
        Wait(10)
    end
    
    return result
end)

-- Load last selected civilian (MySQL only)
lib.callback.register('cdecad-civmanager:loadLastCivilian', function(source)
    if Config.Persistence ~= 'mysql' then
        return nil
    end
    
    local result = nil
    local completed = false
    
    LoadSelectedCivilian(source, function(civilianId)
        result = civilianId
        completed = true
    end)
    
    while not completed do
        Wait(10)
    end
    
    return result
end)

-- Register vehicle
lib.callback.register('cdecad-civmanager:registerVehicle', function(source, vehicleData)
    local activeCiv = ActiveCivilians[source]
    
    if not activeCiv then
        return { success = false, error = 'No civilian selected. Use /setciv first.' }
    end
    
    local result = nil
    local completed = false
    
    RegisterVehicle(activeCiv.ssn or activeCiv.id, vehicleData, function(success, data, statusCode)
        if success then
            result = { success = true, vehicle = data }
        else
            result = { success = false, error = 'Failed to register vehicle', statusCode = statusCode }
        end
        completed = true
    end)
    
    while not completed do
        Wait(10)
    end
    
    return result
end)

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

-- Player selects a civilian
RegisterNetEvent('cdecad-civmanager:selectCivilian', function(civilianData)
    local source = source
    
    if not civilianData then
        ActiveCivilians[source] = nil
        Debug('Cleared civilian for source:', source)
        return
    end
    
    -- Store the new civilian (overwriting any previous)
    ActiveCivilians[source] = civilianData
    Debug('Set civilian for source:', source)
    Debug('  Name:', civilianData.firstName, civilianData.lastName)
    Debug('  SSN:', civilianData.ssn)
    
    -- Save to persistence
    SaveSelectedCivilian(source, civilianData.ssn or civilianData.id)
    
    -- Notify player with confirmation
    TriggerClientEvent('cdecad-civmanager:civilianSet', source, civilianData)
    TriggerClientEvent('cdecad-civmanager:notify', source, 'success', 'Civilian set: ' .. (civilianData.firstName or '') .. ' ' .. (civilianData.lastName or ''))
end)

-- Player shows ID to nearby players
RegisterNetEvent('cdecad-civmanager:showID', function()
    local source = source
    local activeCiv = ActiveCivilians[source]
    
    if not activeCiv then
        TriggerClientEvent('cdecad-civmanager:notify', source, 'error', 'No civilian selected. Use /setciv first.')
        return
    end
    
    Debug('ShowID triggered for source:', source, 'Civilian:', activeCiv.firstName, activeCiv.lastName)
    
    -- Get player position
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Build style with community settings
    local cardStyle = {
        StateName = 'San Andreas', -- Default
        CardTitle = "DRIVER'S LICENSE",
        BackgroundColor = '#1a365d'
    }
    
    -- Override with community settings if available
    if CommunitySettings and CommunitySettings.jurisdiction then
        if CommunitySettings.jurisdiction.state and CommunitySettings.jurisdiction.state ~= '' then
            cardStyle.StateName = CommunitySettings.jurisdiction.state
        end
    end
    
    -- Find nearby players
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local targetId = tonumber(playerId)
        if targetId ~= source then
            local targetPed = GetPlayerPed(targetId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance <= Config.IDCard.ShowRange then
                TriggerClientEvent('cdecad-civmanager:receiveID', targetId, activeCiv, GetPlayerName(source), cardStyle)
            end
        end
    end
    
    -- Also show to the player themselves
    TriggerClientEvent('cdecad-civmanager:receiveID', source, activeCiv, 'You', cardStyle)
end)

-- Player disconnected
AddEventHandler('playerDropped', function(reason)
    local source = source
    ActiveCivilians[source] = nil
    Debug('Player dropped, cleared civilian for source:', source)
end)

-- =============================================================================
-- OX_TARGET EVENTS
-- =============================================================================

-- Show ID to a specific player (from ox_target)
RegisterNetEvent('cdecad-civmanager:showIDToPlayer', function(targetId)
    local source = source
    local activeCiv = ActiveCivilians[source]
    
    if not activeCiv then
        TriggerClientEvent('cdecad-civmanager:notify', source, 'error', 'No civilian selected.')
        return
    end
    
    Debug('ShowID to specific player:', targetId, 'from:', source)
    
    -- Build style with community settings
    local cardStyle = {
        StateName = 'San Andreas',
        CardTitle = "DRIVER'S LICENSE",
        BackgroundColor = '#1a365d'
    }
    
    if CommunitySettings and CommunitySettings.jurisdiction then
        if CommunitySettings.jurisdiction.state and CommunitySettings.jurisdiction.state ~= '' then
            cardStyle.StateName = CommunitySettings.jurisdiction.state
        end
    end
    
    -- Send to the target player
    TriggerClientEvent('cdecad-civmanager:receiveID', targetId, activeCiv, GetPlayerName(source), cardStyle)
    
    -- Also show to yourself
    TriggerClientEvent('cdecad-civmanager:receiveID', source, activeCiv, 'You', cardStyle)
end)

-- Request ID from another player
RegisterNetEvent('cdecad-civmanager:requestID', function(targetId)
    local source = source
    
    Debug('ID requested from player:', targetId, 'by:', source)
    
    -- Notify the target player that someone wants their ID
    TriggerClientEvent('cdecad-civmanager:idRequested', targetId, source, GetPlayerName(source))
end)

-- =============================================================================
-- EXPORTS
-- =============================================================================

-- Get a player's active civilian
exports('GetActiveCivilian', function(source)
    return ActiveCivilians[source]
end)

-- Check if player has a civilian selected
exports('HasActiveCivilian', function(source)
    return ActiveCivilians[source] ~= nil
end)

-- =============================================================================
-- MYSQL SETUP (if using MySQL persistence)
-- =============================================================================

if Config.Persistence == 'mysql' then
    MySQL.ready(function()
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS ]] .. Config.MySQLTable .. [[ (
                discord_id VARCHAR(32) PRIMARY KEY,
                civilian_id VARCHAR(64) NOT NULL,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ]], {}, function()
            Debug('MySQL table ready')
        end)
    end)
end

-- =============================================================================
-- STARTUP
-- =============================================================================

CreateThread(function()
    Wait(2000)
    
    -- Fetch community settings on startup
    FetchCommunitySettings(function(settings)
        if settings then
            print('[CDECAD-CIVMANAGER] Community settings loaded - State: ' .. (settings.jurisdiction and settings.jurisdiction.state or 'San Andreas'))
        end
    end)
end)

print('[CDECAD-CIVMANAGER] Server script loaded')
