fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Employee management system allowing players to hire/fire other players'
version '2.1.2'


ui_page 'web/build/index.html'

client_script {
    'client/client.lua'
}
server_script {
  '@oxmysql/lib/MySQL.lua',
  "server/server.lua"
}
shared_script {
   '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
  "shared/Config.lua"
}
files {
  'locales/*.lua',
  'web/build/index.html',
  'web/build/**/*'
}
