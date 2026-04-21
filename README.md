# CDECAD Civilian Manager

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
- CDECAD Instance

## Installation

1. Download and extract to your resources folder
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
| `/bank` | Open bank (requires integration) |
| `/regveh` | Register your current vehicle |
| `/clearciv` | Clear your civilian selection |

## Configuration

See shared/config.lua for all options including:

- API URL and key
- Persistence mode (KVP or MySQL)
- ID card styling
- Command names
- Vehicle registration settings

## Support

For issues or questions:

1. Enable `Config.EnableDebug = true` and check your server console
2. Verify all configuration values in `config.lua`
3. Open a ticket in the CDE Inc Discord

---

Built by [CDE Inc](https://cdecad.com)
