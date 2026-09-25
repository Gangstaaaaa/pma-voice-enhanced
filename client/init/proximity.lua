-- FiveM for GTAV Enhanced: proximity is now a server-owned spatial voice channel per mode
-- (see server/main.lua's proximityChannels). The client no longer runs a distance-check
-- loop, tracks per-player targets, or listens to channels manually - the server calculates
-- who-hears-whom automatically for spatial channels. Spectator/freecam "hear everyone"
-- mode and the overrideProximityCheck/setVoiceState exports from the old system are NOT
-- reimplemented here yet; they had no direct equivalent and were out of scope for this pass.

-- cache so we only send a nui message when it changes
local lastRadioStatus = false

CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/muteply', 'Mutes the player with the specified id', {
		{ name = "player id", help = "the player to toggle mute" },
		{ name = "duration",  help = "(opt) the duration the mute in seconds (default: 900)" }
	})
	while true do
		if GetConvarInt('voice_enableUi', 1) == 1 then
			if lastRadioStatus ~= radioPressed then
				lastRadioStatus = radioPressed
				sendUIMessage({
					usingRadio = lastRadioStatus,
					-- FiveM for GTAV Enhanced: there is no MumbleIsPlayerTalking equivalent
					-- in the new voice API, so the normal-voice talking indicator is gone.
					talking = false
				})
			end
		end
		Wait(GetConvarInt('voice_refreshRate', 200))
	end
end)

--- exports addVoiceMode / removeVoiceMode
--- Updates the LOCAL voice mode list used for the UI/labels only. Call the matching
--- server export (addVoiceMode/removeVoiceMode in server/main.lua) too, or the new mode
--- will show in the UI without an actual voice channel backing it.
exports("addVoiceMode", function(distance, name)
	for i = 1, #Cfg.voiceModes do
		local voiceMode = Cfg.voiceModes[i]
		if voiceMode[2] == name then
			logger.verbose("Already had %s, overwritting instead", name)
			voiceMode[1] = distance
			return
		end
	end
	Cfg.voiceModes[#Cfg.voiceModes + 1] = { distance, name }
end)

exports("removeVoiceMode", function(name)
	for i = 1, #Cfg.voiceModes do
		local voiceMode = Cfg.voiceModes[i]
		if voiceMode[2] == name then
			table.remove(Cfg.voiceModes, i)
			if mode == i then
				mode = 1
			end
			return true
		end
	end
	return false
end)
