// FiveM for GTAV Enhanced: the new voice API has no "mute this player everywhere" native -
// mute/deaf are per-channel (SetPlayerMutedInVoiceChannel(channelID, ...)). main.lua's
// setPlayerGloballyMuted export applies the mute across every channel the target is
// currently in (and keeps re-applying it if they join a new one), so /muteply just calls
// that instead of touching any native directly.
let mutedTimers = {}
// muteply instead of mute because mute conflicts with rp-radio
RegisterCommand('muteply', (source, args) => {
	const mutePly = parseInt(args[0])
	const duration = parseInt(args[1]) || 900
	const resourceName = GetCurrentResourceName()
	if (mutePly && exports[resourceName].isValidPlayer(mutePly)) {
		const isMuted = !exports[resourceName].isPlayerGloballyMuted(mutePly)
		exports[resourceName].setPlayerGloballyMuted(mutePly, isMuted)
		emit('pma-voice:playerMuted', mutePly, source, isMuted, duration)
		// since this is a toggle, if theres a mutedTimers entry it can be assumed
		// that they're currently muted, so we'll clear the timeout and unmute
		if (mutedTimers[mutePly]) {
			clearTimeout(mutedTimers[mutePly])
			delete mutedTimers[mutePly]
			return
		}
		mutedTimers[mutePly] = setTimeout(() => {
			exports[resourceName].setPlayerGloballyMuted(mutePly, false)
			delete mutedTimers[mutePly]
		}, duration * 1000)
	}
}, true)
