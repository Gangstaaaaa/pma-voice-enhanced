game 'gta5'
version '7.0.1'

fx_version 'cerulean'
author 'AvarianKnight'
description 'VOIP built on FiveM\'s Mumble natives. On FiveM for GTAV Enhanced this needs the Mumble compatibility layer: voice_internal + setr sv_mumble true.'

dependencies {
	'/onesync',
}

lua54 'yes'

shared_script 'shared.lua'

client_scripts {
	'client/utils/*',
	'client/init/proximity.lua',
	'client/init/init.lua',
	'client/init/main.lua',
	'client/init/submix.lua',
	'client/module/*.lua',
	'client/*.lua',
}

server_scripts {
	'server/**/*.lua',
	'server/**/*.js'
}

files {
	'ui/*.ogg',
	'ui/css/*.css',
	'ui/js/*.js',
	'ui/index.html',
}

ui_page 'ui/index.html'

provides {
	'mumble-voip',
	'tokovoip',
	'toko-voip',
	'tokovoip_script'
}

-- voice_useNativeAudio, voice_use2dAudio, voice_useSendingRangeOnly and the external Mumble
-- server convars are not available on FiveM for GTAV Enhanced, so they are no longer listed.
convar_category 'PMA-Voice' {
	"PMA-Voice Configuration Options",
	{
		{ "Mumble compatibility (required on Enhanced)", "$sv_mumble",              "CV_BOOL",   "true" },
		{ "Enable UI",                             "$voice_enableUi",             "CV_INT",    "1" },
		{ "Enable F11 proximity key",              "$voice_enableProximityCycle", "CV_INT",    "1" },
		{ "Proximity cycle key",                   "$voice_defaultCycle",         "CV_STRING", "F11" },
		{ "Voice radio volume",                    "$voice_defaultRadioVolume",   "CV_INT",    "30" },
		{ "Voice call volume",                     "$voice_defaultCallVolume",    "CV_INT",    "60" },
		{ "Enable radios",                         "$voice_enableRadios",         "CV_INT",    "1" },
		{ "Enable calls",                          "$voice_enableCalls",          "CV_INT",    "1" },
		{ "Enable submix",                         "$voice_enableSubmix",         "CV_INT",    "1" },
		{ "Enable radio animation",                "$voice_enableRadioAnim",      "CV_INT",    "0" },
		{ "Radio key",                             "$voice_defaultRadio",         "CV_STRING", "LMENU" },
		{ "UI refresh rate",                       "$voice_uiRefreshRate",        "CV_INT",    "200" },
		{ "Allow players to set audio intent",     "$voice_allowSetIntent",       "CV_INT",    "1" },
		{ "Voice debug mode",                      "$voice_debugMode",            "CV_INT",    "0" },
		{ "Hide server endpoints in logs",         "$voice_hideEndpoints",        "CV_INT",    "1" },
	}
}
