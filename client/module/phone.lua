-- FiveM for GTAV Enhanced: call audio is handled entirely server-side by real channel
-- membership now (see server/module/phone.lua), so this file only tracks callData locally
-- for radio.lua's mic-click logic. There's no client-side voice target, per-listener
-- toggle, or talking-check equivalent left to update here.

local callChannel = 0

RegisterNetEvent('pma-voice:syncCallData', function(callTable, channel)
	callData = callTable
end)

RegisterNetEvent('pma-voice:addPlayerToCall', function(plySource)
	callData[plySource] = true
end)

RegisterNetEvent('pma-voice:removePlayerFromCall', function(plySource)
	if plySource == playerServerId then
		callData = {}
	else
		callData[plySource] = nil
	end
end)

function setCallChannel(channel)
	if GetConvarInt('voice_enableCalls', 1) ~= 1 then return end
	TriggerServerEvent('pma-voice:setPlayerCall', channel)
	callChannel = channel
	sendUIMessage({
		callInfo = channel
	})
end

exports('setCallChannel', setCallChannel)
exports('SetCallChannel', setCallChannel)

exports('addPlayerToCall', function(_call)
	local call = tonumber(_call)
	if call then
		setCallChannel(call)
	end
end)
exports('removePlayerFromCall', function()
	setCallChannel(0)
end)

RegisterNetEvent('pma-voice:clSetPlayerCall', function(_callChannel)
	if GetConvarInt('voice_enableCalls', 1) ~= 1 then return end
	callChannel = _callChannel
end)
