fx_version 'adamant'

game 'gta5'

client_scripts {
	'config.lua',
	'client/client.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'config.lua',
	'server/server.lua'
}

files {	
	'LockPart1.png',
	'LockPart2.png',
}

dependencies {
	'mythic_notify'
}





