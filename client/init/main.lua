-- FiveM for GTAV Enhanced: this file used to create the radio/call audio submixes and
-- handle per-listener volume overrides (MumbleSetVolumeOverrideByServerId /
-- MumbleSetSubmixForServerId). Neither has a replacement in the new voice API - audio
-- routing is now entirely handled server-side by real channel membership - so all of that
-- is gone. What's left is just local UI/sound-effect bookkeeping (mic clicks, radio
-- enabled toggle) that never depended on Mumble in the first place.

local volumes = {
	['click_on'] = GetConvarInt('voice_onClickVolume', 10) / 100,
	['click_off'] = GetConvarInt('voice_offClickVolume', 3) / 100,
}

radioEnabled, radioPressed, mode = true, false, GetConvarInt('voice_defaultVoiceMode', 2)
radioData = {}
callData = {}

--- function setVolume
--- FiveM for GTAV Enhanced: per-listener volume (how loud radio/calls sound) has no
--- equivalent in the new voice API. This now only controls the local mic-click sound
--- effect volumes.
---@param volume number between 0 and 100
---@param volumeType string 'click_on' or 'click_off'
function setVolume(volume, volumeType)
	type_check({ volume, "number" })
	if not volumeType or not volumes[volumeType] then
		return error(('setVolume got a invalid volume type %s'):format(volumeType))
	end
	LocalPlayer.state:set(volumeType, volume, true)
	volumes[volumeType] = volume / 100
end

-- kept as no-ops so third-party integrations (radio/phone resources) that call these don't
-- hard-error; they can no longer change anything since per-listener volume doesn't exist.
exports('setRadioVolume', function() end)
exports('getRadioVolume', function() return 100 end)
exports("setCallVolume", function() end)
exports('getCallVolume', function() return 100 end)

exports('setMicClickOnVolume', function(vol)
	setVolume(vol, 'click_on')
end)
exports('getMicClickOnVolume', function()
	return volumes['click_on'] * 100
end)
exports('setMicClickOffVolume', function(vol)
	setVolume(vol, 'click_off')
end)
exports('getMicClickOffVolume', function()
	return volumes['click_off'] * 100
end)

--- function playMicClicks
---plays the mic click if the player has them enabled.
---@param clickType boolean whether to play the 'on' or 'off' click.
function playMicClicks(clickType)
	if micClicks ~= true then return logger.verbose("Not playing mic clicks because client has them disabled") end
	sendUIMessage({
		sound = (clickType and "audio_on" or "audio_off"),
		volume = (clickType and volumes['click_on'] or volumes['click_off'])
	})
end

-- kept as no-ops: there is no per-listener local mute in the new voice API. Use
-- /muteply (server/main.lua's setPlayerGloballyMuted) for muting a player for real.
exports('isPlayerMuted', function() return false end)
exports('getMutedPlayers', function() return {} end)
exports('toggleMutePlayer', function() end)

--- function setVoiceProperty
--- sets the specified voice property
---@param type string what voice property you want to change (only takes 'radioEnabled' and 'micClicks')
---@param value any the value to set the type to.
function setVoiceProperty(type, value)
	if type == "radioEnabled" then
		radioEnabled = value
		handleRadioEnabledChanged(value)
		sendUIMessage({
			radioEnabled = value
		})
	elseif type == "micClicks" then
		micClicks = value == true or value == "true"
		SetResourceKvp('pma-voice_enableMicClicks', tostring(micClicks))
	end
end

exports('setVoiceProperty', setVoiceProperty)
-- compatibility
exports('SetMumbleProperty', setVoiceProperty)
exports('SetTokoProperty', setVoiceProperty)
