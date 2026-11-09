---
description: Show or change narrate settings (length, volume, model, summaries, project name)
allowed-tools: Read, Edit, Bash, PowerShell
---

Show or change narrate's settings. Arguments: $ARGUMENTS

The settings file is `%APPDATA%\narrate\config.json` (created on first run; if it is missing, run `/narrate:test` once). Read it first and keep keys you are not changing. Changes apply immediately.

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `true` | Master switch (`/narrate:off`, `/narrate:on`) |
| `provider` | `"auto"` | `auto` = ElevenLabs if a key is set up, else Windows; or force `elevenlabs` / `windows` |
| `voiceId` | George | ElevenLabs voice when no rotation is set |
| `voiceIds` | `[]` | Rotation: each session picks one of these at random |
| `voiceNames` | `{}` | ID → name, only for the log |
| `modelId` | `"eleven_v4_turbo"` | ElevenLabs model (`eleven_v4` = more expressive, slower) |
| `maxWords` | `40` | Longest spoken update |
| `summarize` | `true` | Summarize long replies with Claude Haiku (about 5–7 s, uses a little of the user's Claude usage). `false` = read the first sentences instead, faster and free |
| `sayProject` | `true` | Say the project folder name first |
| `volume` | `0.9` | 0.0 – 1.0 |
| `windowsVoice` | `""` | Installed Windows voice name for the free mode |

With no arguments, show the current settings in plain words. Otherwise apply the requested change and confirm it. The log is `%APPDATA%\narrate\narrate.log` if something is not working.
