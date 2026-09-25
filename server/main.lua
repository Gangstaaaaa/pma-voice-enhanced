-- FiveM for GTAV Enhanced: full migration off the deprecated Mumble natives.
-- Proximity, radio and call channel membership are now owned entirely by the server via
-- the new voice channel API (CreateVoiceChannel/AddPlayerToVoiceChannel/RemovePlayerFromVoiceChannel/
-- SetPlayerMutedInVoiceChannel/DeleteVoiceChannel). No MumbleXxx native is called anywhere in
-- this resource anymore, so 'sv_mumble' does not need to be enabled - this also closes the
-- security hole that comes with it (clients could otherwise join/listen to any channel).
--
-- Dropped as part of this migration (no equivalent exists in the new voice API):
--   - Talking indicators (MumbleIsPlayerTalking) for normal proximity voice
--   - The radio/call audio submix filter effect
--   - Per-listener volume overrides (voice_defaultRadioVolume/voice_defaultCallVolume no
--     longer change how loud radio/calls sound; setRadioVolume/setCallVolume are now no-ops)
--   - Audio input intent (speech/music, /setvoiceintent removed)
--   - Local per-player mute (toggleMutePlayer) - this personal "I don't want to hear you"
--     mute isn't possible client-side anymore; /muteply (server admin mute) still works,
--     see setPlayerGloballyMuted below.

voiceData = {}
radioData = {}
callData = {}
mutedPlayers = {} -- source -> true, for /muteply. Global (not local) so radio.lua/phone.lua can read it.

proximityChannels = {}
for i = 1, #Cfg.voiceModes do
	local distance = Cfg.voiceModes[i][1]
	proximityChannels[i] = CreateVoiceChannel(1, distance + 0.0)
	logger.verbose('[proximity] Created channel %s for mode %s (%s units)', proximityChannels[i], Cfg.voiceModes[i][2],
		distance)
end

local overrideChannels = {} -- source -> channelID, for overrideProximityRange

local function defaultVoiceMode()
	local convarMode = GetConvarInt('voice_defaultVoiceMode', 2)
	if convarMode < 1 or convarMode > #Cfg.voiceModes then convarMode = 1 end
	return convarMode
end

function defaultTable(source)
	return {
		radio = 0,
		call = 0,
		proximityMode = 0,
	}
end

--- adds a player to a voice channel, re-applying their /muteply state if they have one.
--- always use this (instead of calling AddPlayerToVoiceChannel directly) so a globally
--- muted player stays muted no matter which channel they get added to next.
---@param channelId number
---@param source number
function addToVoiceChannel(channelId, source)
	AddPlayerToVoiceChannel(channelId, source)
	if mutedPlayers[source] then
		SetPlayerMutedInVoiceChannel(channelId, source, true)
	end
end

exports('addToVoiceChannel', addToVoiceChannel)

--- assigns the player to their default proximity channel. Called on join; unlike the old
--- Mumble version this needs no client acknowledgement at all, the server just does it.
---@param source number
function initializePlayerProximity(source)
	voiceData[source] = voiceData[source] or defaultTable(source)
	local voiceMode = defaultVoiceMode()
	voiceData[source].proximityMode = voiceMode
	addToVoiceChannel(proximityChannels[voiceMode], source)
	Player(source).state:set('proximity', {
		index = voiceMode,
		distance = Cfg.voiceModes[voiceMode][1],
		mode = Cfg.voiceModes[voiceMode][2],
	}, true)
	Player(source).state:set('radioChannel', 0, true)
	Player(source).state:set('callChannel', 0, true)
	Player(source).state:set('muted', mutedPlayers[source] == true, true)
end

--- moves the player between proximity channels (whisper/normal/shout).
---@param source number
---@param modeIndex number
function setProximityMode(source, modeIndex)
	if GetConvarInt('voice_enableProximityCycle', 1) ~= 1 then return end
	if not Cfg.voiceModes[modeIndex] then return end
	voiceData[source] = voiceData[source] or defaultTable(source)
	local plyVoice = voiceData[source]
	if overrideChannels[source] then return end -- an override is active, ignore normal cycling
	if plyVoice.proximityMode and plyVoice.proximityMode ~= 0 then
		RemovePlayerFromVoiceChannel(proximityChannels[plyVoice.proximityMode], source)
	end
	plyVoice.proximityMode = modeIndex
	addToVoiceChannel(proximityChannels[modeIndex], source)
	Player(source).state:set('proximity', {
		index = modeIndex,
		distance = Cfg.voiceModes[modeIndex][1],
		mode = Cfg.voiceModes[modeIndex][2],
	}, true)
end

RegisterNetEvent('pma-voice:setProximityMode', function(modeIndex)
	setProximityMode(source, tonumber(modeIndex))
end)

--- moves the player into a dedicated temporary channel with a custom range, replacing
--- their normal proximity channel until clearProximityOverride is called for them.
---@param source number
---@param range number
function overrideProximityRange(source, range)
	voiceData[source] = voiceData[source] or defaultTable(source)
	local plyVoice = voiceData[source]
	if overrideChannels[source] then
		RemovePlayerFromVoiceChannel(overrideChannels[source], source)
		DeleteVoiceChannel(overrideChannels[source])
	elseif plyVoice.proximityMode and plyVoice.proximityMode ~= 0 then
		RemovePlayerFromVoiceChannel(proximityChannels[plyVoice.proximityMode], source)
	end
	local channelId = CreateVoiceChannel(1, range + 0.0)
	overrideChannels[source] = channelId
	addToVoiceChannel(channelId, source)
	Player(source).state:set('proximity', { index = 0, distance = range, mode = 'Custom' }, true)
end

exports('overrideProximityRange', overrideProximityRange)
RegisterNetEvent('pma-voice:overrideProximityRange', function(range)
	overrideProximityRange(source, tonumber(range))
end)

--- clears a proximity override and restores the players normal proximity channel.
---@param source number
function clearProximityOverride(source)
	local plyVoice = voiceData[source]
	if not plyVoice or not overrideChannels[source] then return end
	RemovePlayerFromVoiceChannel(overrideChannels[source], source)
	DeleteVoiceChannel(overrideChannels[source])
	overrideChannels[source] = nil
	setProximityMode(source, plyVoice.proximityMode ~= 0 and plyVoice.proximityMode or defaultVoiceMode())
end

exports('clearProximityOverride', clearProximityOverride)
RegisterNetEvent('pma-voice:clearProximityOverride', function()
	clearProximityOverride(source)
end)

--- exports addVoiceMode / removeVoiceMode
--- Registers (or removes) a proximity mode and its backing channel at runtime.
---@param distance number
---@param name string
exports('addVoiceMode', function(distance, name)
	for i = 1, #Cfg.voiceModes do
		if Cfg.voiceModes[i][2] == name then
			logger.verbose("Already had %s, overwritting instead", name)
			Cfg.voiceModes[i][1] = distance
			DeleteVoiceChannel(proximityChannels[i])
			proximityChannels[i] = CreateVoiceChannel(1, distance + 0.0)
			return
		end
	end
	Cfg.voiceModes[#Cfg.voiceModes + 1] = { distance, name }
	proximityChannels[#Cfg.voiceModes] = CreateVoiceChannel(1, distance + 0.0)
end)

exports('removeVoiceMode', function(name)
	for i = 1, #Cfg.voiceModes do
		if Cfg.voiceModes[i][2] == name then
			DeleteVoiceChannel(proximityChannels[i])
			table.remove(Cfg.voiceModes, i)
			table.remove(proximityChannels, i)
			return true
		end
	end
	return false
end)

--- sets (or clears) a global mute for the player, applied across every channel they're
--- currently in. Used by /muteply. Radio/call channels only get force-muted (never
--- force-unmuted) here, since those channels have their own PTT-driven mute state.
---@param source number
---@param muted boolean
function setPlayerGloballyMuted(source, muted)
	mutedPlayers[source] = muted or nil
	local plyVoice = voiceData[source]
	if not plyVoice then return end
	if plyVoice.proximityMode and plyVoice.proximityMode ~= 0 then
		SetPlayerMutedInVoiceChannel(proximityChannels[plyVoice.proximityMode], source, muted)
	end
	if overrideChannels[source] then
		SetPlayerMutedInVoiceChannel(overrideChannels[source], source, muted)
	end
	if muted and plyVoice.radio ~= 0 and radioChannels[plyVoice.radio] then
		SetPlayerMutedInVoiceChannel(radioChannels[plyVoice.radio], source, true)
	end
	if muted and plyVoice.call ~= 0 and callChannels[plyVoice.call] then
		SetPlayerMutedInVoiceChannel(callChannels[plyVoice.call], source, true)
	end
	Player(source).state:set('muted', muted, true)
end

exports('setPlayerGloballyMuted', setPlayerGloballyMuted)
exports('isPlayerGloballyMuted', function(source) return mutedPlayers[source] == true end)

-- these two exports keep old third-party integrations from hard-erroring; they can't
-- actually do anything anymore since there's no per-listener volume/mute in the new API.
exports('setRadioVolume', function() end)
exports('setCallVolume', function() end)
exports('isPlayerMuted', function(source) return mutedPlayers[source] == true end)

CreateThread(function()
	local plyTbl = GetPlayers()
	for i = 1, #plyTbl do
		local ply = tonumber(plyTbl[i])
		initializePlayerProximity(ply)
	end

	local radioVolume = GetConvarInt("voice_defaultRadioVolume", 30)
	local callVolume = GetConvarInt("voice_defaultCallVolume", 60)
	if
		radioVolume == 0 or radioVolume == 1 or
		callVolume == 0 or callVolume == 1
	then
		SetConvarReplicated("voice_defaultRadioVolume", 30)
		SetConvarReplicated("voice_defaultCallVolume", 60)
		for i = 1, 5 do
			Wait(5000)
			logger.warn(
				"`voice_defaultRadioVolume` or `voice_defaultCallVolume` have their value set as a float, this is going to automatically be fixed but please update your convars.")
		end
	end
end)

AddEventHandler('playerJoining', function()
	initializePlayerProximity(source)
end)

AddEventHandler("playerDropped", function()
	local source = source
	local plyData = voiceData[source]

	if plyData then
		if plyData.radio ~= 0 then
			removePlayerFromRadio(source, plyData.radio)
		end
		if plyData.call ~= 0 then
			removePlayerFromCall(source, plyData.call)
		end
	end

	-- The engine automatically removes a disconnecting player from every channel they were
	-- in, so proximity/override channels need no manual RemovePlayerFromVoiceChannel call -
	-- but override channels are per-player and still need deleting so they don't leak.
	if overrideChannels[source] then
		DeleteVoiceChannel(overrideChannels[source])
		overrideChannels[source] = nil
	end
	mutedPlayers[source] = nil
	voiceData[source] = nil
end)

-- only meant for internal use so no documentation
function isValidPlayer(source)
	return voiceData[source]
end

exports('isValidPlayer', isValidPlayer)

function getPlayersInRadioChannel(channel)
	local returnChannel = radioData[channel]
	if returnChannel then
		return returnChannel
	end
	-- channel doesnt exist
	return {}
end

exports('getPlayersInRadioChannel', getPlayersInRadioChannel)
exports('GetPlayersInRadioChannel', getPlayersInRadioChannel)
