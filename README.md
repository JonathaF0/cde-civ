# CDECAD Civilian Manager

![](/api/files/019db1ea-326d-749b-872b-0cdcf95fec38/cdecad-civ.png)

A FiveM resource that allows players to select and manage their CDECAD civilians in-game. Features persistent civilian selection, ID card display, vehicle registration, and bank integration.

## Features

- **Civilian Selection**: Players can choose from their CDECAD civilians using `/setciv`
- **Persistent Selection**: Selected civilian persists across sessions (KVP or MySQL)
- **Show ID**: Display a HTML NUI ID card to nearby players
- **Vehicle Registration**: Register your current vehicle to your civilian
- **Bank Integration**: (Placeholder for economy system integration)
- **Skybox/Chat Output**: Optional text-based ID display

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql) (Optional - only if using MySQL persistence)
- [MugShotBase64](https://github.com/BaziForYou/MugShotBase64) (Optional - only if you want civ mugshots to be pushed to CAD)
  - MugShotBase64 will overwrite any and all previous mugshots, but will not overwrite any custom uploaded pictures.
- CDECAD Instance

## Installation

1. [Download](https://github.com/JonathaF0/cde-civ/releases/tag/release) and extract to your resources folder (_if using the optional resources above, please download and extract them to your resources folder)_
2. Configure shared/config.lua with your API settings
3. Add `ensure cdecad-civmanager` to your server.cfg
4. Restart your server

## Commands

|     |     |
| --- | --- |
| Command | Description |
| `/setciv` | Open civilian selector menu |
| `/myciv` | Show your current civilian info |
| `/showid` | Show your ID to nearby players |
| `/bank` | Open bank (Character Banking Profile **_Early Access_**) |
| `/regveh` | Register your current vehicle |
| `/clearciv` | Clear your civilian selection |

## Configuration

See shared/config.lua for all options including:

- API URL and key
- Guild/Server ID
- Persistence mode (KVP or MySQL)
- ID card styling
- Command names
- Vehicle registration settings

```lua
-- Your CDECAD API URL (no trailing slash)
Config.API_URL = 'https://cdecad.com/api'

-- Your CDECAD API Key
Config.API_KEY = ''

-- Your Community ID (Discord Guild ID)
Config.COMMUNITY_ID = '1234578900123456'
```

## Support

For issues or questions:

1. Enable `Config.EnableDebug = true` and check your server console
2. Verify all configuration values in `config.lua`
3. Open a ticket in the CDE Inc Discord

---

Built by [CDE Inc](https://cdecad.com)
