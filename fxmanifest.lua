fx_version 'cerulean'
game 'gta5'

name 'cdecad-civmanager'
description 'CDECAD Civilian Manager - Select civs, bank, register vehicles, show ID'
author 'CDECAD'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/vehicles.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Optional: only if using MySQL persistence
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/nui.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib'
}
