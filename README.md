# CDECAD Civilian Manager

A FiveM resource that allows players to select and manage their CDECAD civilians in-game. Features persistent civilian selection, ID card display, vehicle registration, and bank integration.

## Features

- **Civilian Selection**: Players can choose from their CDECAD civilians using `/setciv`
- **Persistent Selection**: Selected civilian persists across sessions (KVP or MySQL)
- **Show ID**: Display a professional HTML ID card to nearby players
- **Vehicle Registration**: Register your current vehicle to your civilian
- **Bank Integration**: (Placeholder for economy system integration)
- **Skybox/Chat Output**: Optional text-based ID display

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql) (Optional - only if using MySQL persistence)
- CDECAD Backend with FiveM routes installed

## Installation

1. Download and extract to your resources folder
2. Add the new routes to your CDECAD backend (see fivem-routes-addition.js)
3. Configure shared/config.lua with your API settings
4. Add `ensure cdecad-civmanager` to your server.cfg
5. Restart your server

## Commands

| Command | Description |
|---------|-------------|
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
