-- FiveM for GTAV Enhanced: calls are now a real server-owned non-spatial voice channel
-- (CreateVoiceChannel(0, 0.0)) instead of client-side Mumble voice targets. Calls are
-- always-on in both directions (no push-to-talk), so unlike radio.lua, players are added
-- unmuted and stay that way for the duration of the call.

callChannels = {} -- callChannel id -> voice channel ID (non-spatial)

--- gets (or lazily creates) the voice channel backing a call id
---@param callChannel number
local function getOrCreateCallChannel(callChannel)
	if not callChannels[callChannel] then
		callChannels[callChannel] = CreateVoiceChannel(0, 0.0)
	end
	return callChannels[callChannel]
end

--- removes a player from the call for everyone in the call.
---@param source number the player to remove from the call
---@param callChannel number the call channel to remove them from
function removePlayerFromCall(source, callChannel)
	logger.verbose('[call] Removed %s from call %s', source, callChannel)

	callData[callChannel] = callData[callChannel] or {}
	for player, _ in pairs(callData[callChannel]) do
		TriggerClientEvent('pma-voice:removePlayerFromCall', player, source)
	end
	callData[callChannel][source] = nil
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].call = 0

	local channelId = callChannels[callChannel]
	if channelId then
		RemovePlayerFromVoiceChannel(channelId, source)
		if not next(callData[callChannel]) then
			DeleteVoiceChannel(channelId)
			callChannels[callChannel] = nil
		end
	end
end

--- adds a player to a call
---@param source number the player to add to the call
---@param callChannel number the call channel to add them to
function addPlayerToCall(source, callChannel)
	logger.verbose('[call] Added %s to call %s', source, callChannel)
	-- check if the channel exists, if it does set the varaible to it
	-- if not create it (basically if not callData make callData)
	callData[callChannel] = callData[callChannel] or {}
	for player, _ in pairs(callData[callChannel]) do
		-- don't need to send to the source because they're about to get sync'd!
		if player ~= source then
			TriggerClientEvent('pma-voice:addPlayerToCall', player, source)
		end
	end
	callData[callChannel][source] = true
	voiceData[source] = voiceData[source] or defaultTable(source)
	voiceData[source].call = callChannel

	-- calls are always-on both ways, no push-to-talk, so no mute step needed here
	addToVoiceChannel(getOrCreateCallChannel(callChannel), source)

	TriggerClientEvent('pma-voice:syncCallData', source, callData[callChannel])
end

--- set the players call channel
---@param source number the player to set the call off
---@param _callChannel number the channel to set the player to (or 0 to remove them from any call channel)
function setPlayerCall(source, _callChannel)
	if GetConvarInt('voice_enableCalls', 1) ~= 1 then return end
	voiceData[source] = voiceData[source] or defaultTable(source)
	local isResource = GetInvokingResource()
	local plyVoice = voiceData[source]
	local callChannel = tonumber(_callChannel)
	if not callChannel then
		-- only full error if its sent from another server-side resource
		if isResource then
			error(("'callChannel' expected 'number', got: %s"):format(type(_callChannel)))
		else
			return logger.warn("%s sent a invalid call, 'callChannel' expected 'number', got: %s", source,
				type(_callChannel))
		end
	end
	if isResource then
		-- got set in a export, need to update the client to tell them that their call
		-- changed
		TriggerClientEvent('pma-voice:clSetPlayerCall', source, callChannel)
	end

	Player(source).state:set('callChannel', callChannel, true)

	if callChannel ~= 0 and plyVoice.call == 0 then
		addPlayerToCall(source, callChannel)
	elseif callChannel == 0 then
		removePlayerFromCall(source, plyVoice.call)
	elseif plyVoice.call > 0 then
		removePlayerFromCall(source, plyVoice.call)
		addPlayerToCall(source, callChannel)
	end
end

exports('setPlayerCall', setPlayerCall)

RegisterNetEvent('pma-voice:setPlayerCall', function(callChannel)
	setPlayerCall(source, callChannel)
end)
