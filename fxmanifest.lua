fx_version 'cerulean'
game 'gta5'

author 'Cosmo@GPT'
description 'QB NPC Taxi Job Sandy Shores'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
    'localization.lua',
    'shared/locations.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/taxi.png'
}

client_scripts {
    'client/models.lua',
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

dependencies {
    'qb-core',
    'qb-taxijob',
    'qb-target'
}