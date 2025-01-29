fx_version 'cerulean'
game 'gta5'

author 'R4fson'
description 'Custom Garage Script - by (r4fson)'
discord 'r4fson'
version '1.0'

lua54 'yes'
shared_scripts {
    '@ox_lib/init.lua',
    --'@qb-core/import.lua',  -- UNCOMMENT YOUR FRAMEWORK
    --'@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'locales/*.lua', 
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

-- UI Files
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css'
}

