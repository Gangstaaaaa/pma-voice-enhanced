> # ⚠️ FiveM for GTAV Enhanced ONLY
>
> This version of pma-voice has been modified to run on **FiveM for GTAV Enhanced**. It is **not** intended for FiveM Legacy, and the Legacy-specific options have been removed or replaced in this README.
>
> # ⚠️ Disclaimer: AI-assisted changes, errors are possible
>
> The Enhanced-specific changes in this version were written with the help of AI and have **not** been fully tested. There may be errors or unexpected behaviour (for example with proximity range, submix effects, or voice initialisation). Please test on a development server before using this in production, and keep a backup of the original resource.

## PLEASE NOTE: Currently master branch has some breaking changes

if you experience the hud not talking make sure you enable voice chat cause I had the same issue.

If you previously used `voice_defaultPhoneVolume` you will instead need to use `voice_defaultCallVolume`
If you previously used `voice_enablePhones` you will instead need to use `voice_enableCalls`

If you were previously using the state bag getter `Player(source).state.phone` you will instead need to use `Player(source).state.call`

# pma-voice
A voice system designed around the use of the FiveM for GTAV Enhanced internal voice server, using the Mumble compatibility layer.

Based on the original [pma-voice](https://github.com/AvarianKnight/pma-voice) by AvarianKnight.

## Support

Please report any issues you have with the original resource in the GitHub [Issues](https://github.com/AvarianKnight/pma-voice/issues).

Issues caused by the Enhanced changes in this version should **not** be reported to the original repository, since they are not part of the upstream project.

# Compatibility Notice:

This script is not compatible with other voice systems (duh), that means if you have vMenus voice chat you will **have** to [disable](https://docs.vespura.com/vmenu/faq/#q-how-do-i-disable-voice-chat) it.

Please do not override `NetworkSetTalkerProximity`, `MumbleSetTalkerProximity`, `MumbleSetAudioInputDistance`, `MumbleSetAudioOutputDistance` or `NetworkSetVoiceActive` in any of your other scripts as there have been cases where it breaks pma-voice.

# Credits

- @AvarianKnight for pma-voice (the original resource this version is based on)
- @Frazzle for mumble-voip (for which the concept came from)
- @pichotm for pVoice (where the grid concept came from)

# FiveM for GTAV Enhanced Setup

FiveM for GTAV Enhanced replaces Mumble with a new voice implementation. pma-voice still uses the (now **deprecated**) Mumble natives, which only work through the Mumble compatibility layer. That layer, and the internal voice server, have to be enabled in your `server.cfg`:

```cfg
voice_internal
setr sv_mumble true
```

#### Security note

Enabling `sv_mumble` allows client-controlled voice channels. Any client can join any channel and listen to any conversation. This is how pma-voice currently works, so keep it in mind. The Mumble natives are deprecated and will be removed in a future version of FiveM for GTAV Enhanced, at which point pma-voice will need to be migrated to the new server-side voice API.

#### What was changed for Enhanced

- Removed the use of the `voice_useNativeAudio`, `voice_use2dAudio`, `voice_use3dAudio` and `voice_useSendingRangeOnly` convars (they no longer exist on Enhanced). Voice mode distances are always the standard Whisper 3.0 / Normal 7.0 / Shouting 15.0.
- The server no longer defaults `voice_useNativeAudio` to `true`, and now warns if `sv_mumble` is not enabled.
- Added a fallback for voice initialisation in case the `mumbleConnected` event is not fired by the compatibility layer.
- Server-side state bag values (`radioChannel`, `callChannel`, `muted`) are now set explicitly as replicated.
- Removed the external Mumble server convars from the manifest and this README (see below).
- Removed a leftover debug `print` and fixed a mistyped key mapping type for the secondary push-to-talk keybind.
- Removed the RedM-only code (RedM native wrappers and raw keymaps) and the FiveM/RedM game checks, so the keybinds always register. The manifest now targets `gta5` only.

The public exports, events and state bags listed below were left unchanged, so resources that integrate with pma-voice (radio and phone resources, for example) should keep working.

# FiveM for GTAV Enhanced Config

You only need to add the convar **if** you're changing the value.

All of the configs here are set using `setr [voice_configOption] [boolean]`

| ConVar                     | Default | Description                                                   | Parameter(s) |
|----------------------------|---------|---------------------------------------------------------------|--------------|
| sv_mumble                  |  false  | Enables the Mumble compatibility layer. **Required for pma-voice to work on Enhanced** | boolean      |

#### Removed on FiveM for GTAV Enhanced

The following convars no longer exist on Enhanced and have no effect, do not set them:

| ConVar                     | Notes                                                         |
|----------------------------|---------------------------------------------------------------|
| voice_useNativeAudio       | Removed by the engine. Native audio is no longer available.   |
| voice_use2dAudio           | Removed by the engine.                                        |
| voice_use3dAudio           | Removed by the engine.                                        |
| voice_useSendingRangeOnly  | Removed by the engine.                                        |

`voice_inBitrate` (set by the client) still works the same as before.

# Config

### PLEASE NOTE: Any keybind changes only affect new players, if you want to change your key bind go to Key Bindings -> FiveM -> Look for keybinds under 'pma-voice'.

All of the config is done via ConVars in order to streamline the process.

The ints are used like a boolean to 0 would be false, 1 true.

All of the configs here are set using `setr [voice_configOption] [int]` OR `setr [voice_configOption] "[string]"`

#### Note: If a convar defaults to 1 (true) you don't have set it again unless you want to disable it.

### General Voice Settings

| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_enableUi               |    1    | Enables the built in user interface                            | int          |
| voice_enableProximityCycle   |    1    | Enables the usage of the F11 proximity key, if disabled players are stuck on the first proximity  | int          |
| voice_defaultCycle           |   F11   | The default key to cycle the players proximity. You can find a list of valid keys [in the Cfx docs](https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/)                | string       |
| voice_defaultRadioVolume          |   30   | The default volume to set the radio to (has to be between 1 and 100) *NOTE: Only new joins will have the new value, players that already joined will not.* | float       |
| voice_defaultCallVolume          |   60   | The default volume to set the call to (has to be between 1 and 100) *NOTE: Only new joins will have the new value, players that already joined will not.* | float       |
| voice_onClickVolume          |   10   | The default volume to set the radio turn on mic click's to (has to be between 1 and 100) *NOTE: Only new joins will have the new value, players that already joined will not.* | float       |
| voice_offClickVolume          |   3   | The default volume to set the radio turn off mic click's to (has to be between 1 and 100) *NOTE: Only new joins will have the new value, players that already joined will not.* | float       |
| voice_defaultVoiceMode  |  2      | Default proximity voice value when player joins server. (Voice Modes; 1:Whisper, 2:Normal, 3:Shouting) | int      |

### Call & Radio

| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_enableRadios           |    1    | Enables the radio sub-modules                                 | int          |
| voice_enableCalls           |    1    | Enables the call sub-modules                                 | int          |
| voice_enableSubmix      |    1    | Enables the submix which adds a radio/call style submix to their voice **NOTE: The native audio option this used to depend on was removed on Enhanced, so submix effects are untested and may not work** | int          |
| voice_enableRadioAnim        |   1     | Enables (grab shoulder mic) animation while talking on the radio.          | int          |
| voice_defaultRadio           |   LMENU  | The default key to use the radio. You can find a list of valid keys [in the FiveM docs](https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/)                             | string       |

### Sync

| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_refreshRate   |   200    | How often the UI/Proximity is refreshed | int     |

### Misc.
| ConVar                  | Default | Description                                                        | Parameter(s) |
|-------------------------|---------|--------------------------------------------------------------------|--------------|
| voice_allowSetIntent         |   1  | Whether or not to allow players to set their audio intents (you can see more [here](https://docs.fivem.net/natives/?_0x6383526B)). *Untested on Enhanced, the new voice stack has its own noise and echo cancellation.*  | int       |
| voice_debugMode              |   0     | 1 for basic logs, 4 for verbose logs                          | int          |
| voice_hideEndpoints     | 1   | Hides the voice server address in logs | int        |

#### External voice server

The external Mumble server convars (`voice_externalAddress`, `voice_externalPort` and `voice_externalDisallowJoin`) are Mumble-specific and are no longer used in this version. FiveM for GTAV Enhanced has its own (very experimental) external voice server, configured with `voice_external_host` and `voice_external_connect`. See the [Cfx voice documentation](https://docs.fivem.net/docs/scripting-manual/voice/) for details. It has not been tested with this resource.

### Aces

pma-voice comes with a built in /muteply (tgtPly) (duration) command, in order to allow your staff to use it you will have to grand them the ace!

Example:
`add_ace group.superadmin command.muteply allow;`

This would only allow the superadmin group to mute players.

### Exports

#### Client

##### Setters

| Export              | Description                 | Parameter(s) |
|---------------------|-----------------------------|--------------|
| [setVoiceProperty](docs/client-setters/setVoiceProperty.md)    | Set config options          | string, any  |
| [setRadioChannel](docs/client-setters/setRadioChannel.md)     | Set radio channel           | int          |
| [setCallChannel](docs/client-setters/setCallChannel.md)      | Set call channel            | int          |
| [setRadioVolume](docs/client-setters/setRadioVolume.md)      | Set radio volume for player | int          |
| [setCallVolume](docs/client-setters/setCallVolume.md)        | Set call volume for player  | int          |
| [setMicClickOnVolume](docs/client-setters/setMicClickOnVolume.md)      | Set mic click on volume for player | int          |
| [setMicClickOffVolume](docs/client-setters/setCallVolume.md)        | Set mic click off volume for player  | int          |
| [addPlayerToRadio](docs/client-setters/setRadioChannel.md)      | Set radio channel        | int          |
| [addPlayerToCall](docs/client-setters/setCallChannel.md)       | Set call channel         | int          |
| [removePlayerFromRadio](docs/client-setters/removePlayerFromRadio.md) | Remove player from radio |              |
| [removePlayerFromCall](docs/client-setters/removePlayerFromCall.md)  | Remove player from call  |              |

##### Toggles

| Export              | Description                                            | Parameter(s) |
|---------------------|--------------------------------------------------------|--------------|
| toggleMutePlayer    | Toggles the selected player muted for the local client | int          |

Supported from mumble-voip / toko-voip

| Export                | Description              | Parameter(s) |
|-----------------------|--------------------------|--------------|
| [SetMumbleProperty](docs/client-setters/setVoiceProperty.md)     | Set config options       | string, any  |
| [SetTokoProperty](docs/client-setters/setVoiceProperty.md)       | Set config options       | string, any  |
| [SetRadioChannel](docs/client-setters/setRadioChannel.md)       | Set radio channel        | int          |
| [SetCallChannel](docs/client-setters/setCallChannel.md)        | Set call channel         | int          |

#### Getters

The majority of setters are done through player states.


| State Bag     | Description                                                  | Return Type  |
|---------------|--------------------------------------------------------------|--------------|
| [proximity](docs/state-getters/stateBagGetters.md)     | Returns a table with the mode index, distance, and mode name | table        |
| [radioChannel](docs/state-getters/stateBagGetters.md)  | Returns the players current radio channel, or 0 for none     | int          |
| [callChannel](docs/state-getters/stateBagGetters.md)   | Returns the players current call channel, or 0 for none      | int          |
| [disableRadio](docs/state-getters/stateBagGetters.md)   | Returns if the players radio is currently disabled, or 0 if its not. This is expected to be use as a bitwise, do *not* use a bool | int          |

#### Events

These are events designed for third-party resource integration. These are emitted only to the current client.

| Event                    | Description                                                  | Event Params   |
|--------------------------|--------------------------------------------------------------|----------------|
| [pma-voice:settingsCallback](docs/client-getters/events.md) | When emited it will return the current pma-voice settings. | cb(voiceSettings) |
| [pma-voice:radioActive](docs/client-getters/events.md) | Triggered when the radio is activated / deactivated | boolean |
| [pma-voice:setTalkingMode](docs/client-getters/events.md) | Triggered on proximity mode change with the voice mode id | int |


#### Server

##### Setters

| Export               | Description                          | Parameter(s) |
|----------------------|--------------------------------------|--------------|
| [setPlayerRadio](docs/server-setters/setPlayerRadio.md)       | Sets the players radio channel       | int, int     |
| [setPlayerCall](docs/server-setters/setPlayerCall.md)        | Sets the players call channel        | int, int     |
| [addChannelCheck](docs/server-setters/addChannelCheck.md)      | Adds a channel check to the players radio channel | int, function |
| [removeChannelCheck](docs/server-setters/removeChannelCheck.md)      | Removes a channel check for the players radio channel | int |

##### Getters

###### State Bags
You can access the state with `Player(source).state['state bag here']`

| State Bag     | Description                                                  | Return Type  |
|---------------|--------------------------------------------------------------|--------------|
| [proximity](docs/state-getters/stateBagGetters.md)     | Returns a table with the mode index, distance, and mode name | table        |
| [radioChannel](docs/state-getters/stateBagGetters.md)  | Returns the players current radio channel, or 0 for none     | int          |
| [callChannel](docs/state-getters/stateBagGetters.md)   | Returns the players current call channel, or 0 for none      | int          |
| [voiceIntent](docs/state-getters/stateBagGetters.md) | Returns the players current voice intent, either 'speech' or 'music' | string |
| [disableRadio](docs/state-getters/stateBagGetters.md)   | Returns if the players radio is currently disabled, or 0 if its not. This is expected to be use as a bitwise, do *not* use a bool | int          |

```ts
enum DisabledRadioStates {
	Enabled = 0,
	IsDead = 1,
	IsCuffed = 2,
	IsPdCuffed = 4,
	IsUnderWater = 8,
	DoesntHaveItem = 16,
	PlayerDisabledRadio = 32,
}
```

###### Exports

| Export                       | Description                                       | Parameter(s) |
|------------------------------|---------------------------------------------------|------|
| [getPlayersInRadioChannel](docs/server-getters/getPlayersInRadioChannel.md)     | Gets the current players in a radio channel       | int  |
