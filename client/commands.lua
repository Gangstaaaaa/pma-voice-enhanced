local wasProximityDisabledFromOverride = false
disableProximityCycle = false

-- FiveM for GTAV Enhanced: MumbleSetAudioInputIntent has no replacement in the new voice
-- API, so /setvoiceintent can no longer do anything. Commented out (not deleted) rather
-- than removed outright.
-- RegisterCommand('setvoiceintent', function(source, args)
-- 	if GetConvarInt('voice_allowSetIntent', 1) == 1 then
-- 		local intent = args[1]
-- 		if intent == 'speech' then
-- 			MumbleSetAudioInputIntent(`speech`)
-- 		elseif intent == 'music' then
-- 			MumbleSetAudioInputIntent(`music`)
-- 		end
-- 		LocalPlayer.state:set('voiceIntent', intent, true)
-- 	end
-- end)
-- TriggerEvent('chat:addSuggestion', '/setvoiceintent', 'Sets the players voice intent', {
-- 	{
-- 		name = "intent",
-- 		help = "speech is default and enables noise suppression & high pass filter, music disables both of these."
-- 	},
-- })

-- TODO: Better implementation of this?
RegisterCommand('vol', function(_, args)
	if not args[1] then return end
	setVolume(tonumber(args[1]))
end)
TriggerEvent('chat:addSuggestion', '/vol', 'Sets the radio/phone volume', {
	{ name = "volume", help = "A range between 1-100 on how loud you want them to be" },
})

exports('setAllowProximityCycleState', function(state)
	type_check({ state, "boolean" })
	disableProximityCycle = state
end)

-- FiveM for GTAV Enhanced: proximity range is enforced by the server-owned spatial voice
-- channel (see server/main.lua), not by a client native like the old MumbleSetTalkerProximity.
-- These functions now just tell the server which channel to put us in and update the local
-- UI label optimistically; Player(source).state.proximity (set server-side) stays the real
-- source of truth and is what's synced to the client automatically.

--- switches to one of the predefined voiceModes by index, notifying the server so it can
--- move us into the matching spatial channel.
---@param modeIndex number index into Cfg.voiceModes
function setProximityState(modeIndex)
	mode = modeIndex
	TriggerServerEvent('pma-voice:setProximityMode', modeIndex)
	sendUIMessage({
		-- JS expects this value to be - 1, "custom" voice is on the last index
		voiceMode = modeIndex - 1
	})
end

exports("overrideProximityRange", function(range, disableCycle)
	type_check({ range, "number" })
	TriggerServerEvent('pma-voice:overrideProximityRange', range)
	sendUIMessage({
		-- JS expects this value to be - 1, "custom" voice is on the last index
		voiceMode = #Cfg.voiceModes
	})
	if disableCycle then
		disableProximityCycle = true
		wasProximityDisabledFromOverride = true
	end
end)

exports("clearProximityOverride", function()
	TriggerServerEvent('pma-voice:clearProximityOverride')
	sendUIMessage({
		voiceMode = mode - 1
	})
	if wasProximityDisabledFromOverride then
		disableProximityCycle = false
		wasProximityDisabledFromOverride = false
	end
end)

RegisterCommand('cycleproximity', function()
	-- Proximity is either disabled, or manually overwritten.
	if GetConvarInt('voice_enableProximityCycle', 1) ~= 1 or disableProximityCycle then return end
	local newMode = mode + 1

	-- If we're within the range of our voice modes, allow the increase, otherwise reset to the first state
	if newMode > #Cfg.voiceModes then
		newMode = 1
	end

	setProximityState(newMode)
end, false)
RegisterKeyMapping('cycleproximity', 'Cycle Proximity', 'keyboard', GetConvar('voice_defaultCycle', 'F11'))

-- hacky workaround to the fact that you can't bind secondary key mappings to PTT
do
	local isSecondaryPttPressed = false

	RegisterCommand("+secondary_ptt", function()
		isSecondaryPttPressed = true
		CreateThread(function()
			while isSecondaryPttPressed do
				SetControlNormal(0, 249, 1.0)
				SetControlNormal(1, 249, 1.0)
				SetControlNormal(2, 249, 1.0)

				Wait(0)
			end
		end)
	end)

	RegisterCommand("-secondary_ptt", function()
		isSecondaryPttPressed = false
	end)

	RegisterKeyMapping('+secondary_ptt', 'A keybind that lets you have a secondary PTT', 'PAD_ANALOGBUTTON', GetConvar('voice_defaultSecondary', 'LUP_INDEX'))
end
