isInitialized = false

function handleInitialState()
	local voiceModeData = Cfg.voiceModes[mode]
	MumbleSetTalkerProximity(voiceModeData[1] + 0.0)
	MumbleClearVoiceTarget(voiceTarget)
	MumbleSetVoiceTarget(voiceTarget)
	MumbleSetVoiceChannel(LocalPlayer.state.assignedChannel)

	while MumbleGetVoiceChannelFromServerId(playerServerId) ~= LocalPlayer.state.assignedChannel do
		Wait(100)
		MumbleSetVoiceChannel(LocalPlayer.state.assignedChannel)
	end

	isInitialized = true

	MumbleAddVoiceTargetChannel(voiceTarget, LocalPlayer.state.assignedChannel)

	addNearbyPlayers()
end

local function onVoiceConnected(address, isReconnecting)
	logger.info('Connected to mumble server with address of %s, is this a reconnect %s',
		GetConvarInt('voice_hideEndpoints', 1) == 1 and 'HIDDEN' or address, isReconnecting)

	logger.log('Connecting to mumble, setting targets.')
	-- don't try to set channel instantly, we're still getting data.
	local voiceModeData = Cfg.voiceModes[mode]
	LocalPlayer.state:set('proximity', {
		index = mode,
		distance = voiceModeData[1],
		mode = voiceModeData[2],
	}, true)

	handleInitialState()

	logger.log('Finished connection logic')
end

AddEventHandler('mumbleConnected', onVoiceConnected)

-- FiveM for GTAV Enhanced: the Mumble compatibility layer is not documented to emit
-- 'mumbleConnected'. If it never arrives but the client reports being connected, run the
-- same initialisation ourselves so pma-voice doesn't wait forever.
CreateThread(function()
	local waited = 0
	while not isInitialized and waited < 30000 do
		Wait(1000)
		waited = waited + 1000
		if not isInitialized and MumbleIsConnected() then
			logger.warn("'mumbleConnected' did not fire but voice reports connected, running initialisation manually.")
			onVoiceConnected('unknown', false)
			return
		end
	end
	if not isInitialized then
		logger.warn("Voice did not initialise within 30s. On FiveM for GTAV Enhanced check that server.cfg has 'voice_internal' and 'setr sv_mumble true'.")
	end
end)

AddEventHandler('mumbleDisconnected', function(address)
	isInitialized = false
	logger.info('Disconnected from mumble server with address of %s',
		GetConvarInt('voice_hideEndpoints', 1) == 1 and 'HIDDEN' or address)
end)

-- TODO: Convert the last Cfg to a Convar, while still keeping it simple.
AddEventHandler('pma-voice:settingsCallback', function(cb)
	cb(Cfg)
end)
