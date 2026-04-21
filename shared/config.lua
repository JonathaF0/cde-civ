--[[
    CDECAD Civilian Manager Configuration
]]

Config = {}

-- =============================================================================
-- API CONFIGURATION
-- =============================================================================

-- Your CDECAD API URL (no trailing slash)
Config.API_URL = 'https://cdecad.com/api'

-- Your CDECAD API Key
Config.API_KEY = ''

-- Your Community ID (Discord Guild ID)
Config.COMMUNITY_ID = '1234578900123456'

-- =============================================================================
-- PERSISTENCE CONFIGURATION
-- =============================================================================

-- How to persist selected civilian across sessions
-- Options: 'kvp', 'mysql'
-- 'kvp' - Uses FiveM's built-in Key-Value storage (no database needed)
-- 'mysql' - Uses MySQL database (requires oxmysql)
Config.Persistence = 'kvp'

-- MySQL table name (only used if Persistence = 'mysql')
Config.MySQLTable = 'cdecad_selected_civs'

-- =============================================================================
-- COMMANDS CONFIGURATION
-- =============================================================================

Config.Commands = {
    -- Command to open civilian selector
    SelectCiv = 'setciv',
    
    -- Command to show current civilian info
    ShowInfo = 'myciv',
    
    -- Command to open bank
    Bank = 'bank',
    
    -- Command to register current vehicle
    RegisterVehicle = 'regveh',
    
    -- Command to show ID to nearby players
    ShowID = 'showid',
    
    -- Command to clear selected civilian
    ClearCiv = 'clearciv'
}

-- =============================================================================
-- ID CARD CONFIGURATION
-- =============================================================================

Config.IDCard = {
    -- Show HTML ID card UI
    ShowHTML = true,
    
    -- Also output to chat/skybox
    ShowInChat = true,
    
    -- Use ox_lib notify for ID display (alternative to HTML)
    UseOxNotify = false,
    
    -- ID card display duration (ms)
    DisplayDuration = 10000,
    
    -- Range for nearby players to see ID (in meters)
    ShowRange = 3.0,
    
    -- Enable ox_target integration (look at player -> Show ID / Request ID)
    UseOxTarget = true,
    
    -- ID Card appearance (fallback if community settings not available)
    CardStyle = {
        -- State name on the ID
        StateName = 'Tennessee',
        
        -- Card title
        CardTitle = "DRIVER'S LICENSE",
        
        -- Background color (hex)
        BackgroundColor = '#1a365d',
        
        -- Text color (hex)
        TextColor = '#ffffff',
        
        -- Accent color (hex)
        AccentColor = '#3182ce'
    }
}

-- =============================================================================
-- BANK CONFIGURATION
-- =============================================================================

Config.Bank = {
    -- Enable bank functionality
    Enabled = true,
    
    -- Starting balance for new civilians (if not set in CAD)
    DefaultBalance = 5000,
    
    -- Allow transfers between players
    AllowTransfers = true,
    
    -- Minimum transfer amount
    MinTransfer = 1,
    
    -- Maximum transfer amount (0 = unlimited)
    MaxTransfer = 0,
    
    -- Transaction fee percentage (0 = no fee)
    TransferFee = 0
}

-- =============================================================================
-- VEHICLE REGISTRATION CONFIGURATION
-- =============================================================================

Config.VehicleRegistration = {
    -- Enable vehicle registration
    Enabled = true,
    
    -- Registration fee
    Fee = 500,
    
    -- Require player to be in vehicle to register
    RequireInVehicle = true,
    
    -- Auto-detect vehicle info from game
    AutoDetect = true,
    
    -- Allow registering stolen vehicles
    AllowStolen = false
}

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

Config.Notifications = {
    -- Use ox_lib notifications
    UseOxLib = true,
    
    -- Notification duration (ms)
    Duration = 5000,
    
    -- Notification position
    Position = 'top-right'
}

-- =============================================================================
-- MUGSHOT CONFIGURATION
-- =============================================================================

-- Automatically capture an in-game FiveM mugshot when a civilian is selected
-- and upload it to the CAD as a fallback photo.
-- Set to false (recommended) when your players upload custom photos via the
-- CAD portal — the CAD photo is always the source of truth and will never
-- be overwritten by an in-game capture regardless of this setting.
Config.CaptureFiveMMugshot = false

-- =============================================================================
-- DEBUG
-- =============================================================================

-- Set to true to see debug messages in console (F8)
Config.Debug = true
