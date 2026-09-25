-- FiveM for GTAV Enhanced: proximity/radio/call channel membership is entirely server-side
-- now (see server/main.lua). There is no MumbleConnected handshake to wait for anymore -
-- the server adds the player to their default proximity channel as soon as they join, with
-- no client acknowledgement required. The old isInitialized/handleInitialState dance and
-- the 30s "did voice connect" fallback that used to live in this file are gone entirely.

-- kept for third-party resources that read the voice mode list this way
AddEventHandler('pma-voice:settingsCallback', function(cb)
	cb(Cfg)
end)
