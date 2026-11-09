# narrate

Spoken updates for **Claude Code on Windows**. Step away from the screen and still know what Claude is doing.

- **When Claude finishes**, you hear a short summary: *"api-server. Fixed the login bug, three tests passing. Should I add a retry now, or later?"*
- **When Claude needs you** (a permission prompt or a question), you hear an alert.
- **When you send a new prompt**, any speech still playing stops.
- **Voices:** [ElevenLabs](https://elevenlabs.io) (Eleven v4 by default) or the **free built-in Windows voice**, which needs no key or account.
- **Voice rotation:** give it a few voices and each session gets its own, so parallel sessions are easy to tell apart.

Pair it with Claude Code's built-in voice dictation (hold-to-talk) to talk back.

## Install

In Claude Code:

```
/plugin marketplace add daniardel/narrate
/plugin install narrate@narrate
```

It works straight away with the Windows voice. For ElevenLabs voices, run `/narrate:setup`.

**Requires:** Windows 10 or 11, Windows PowerShell 5.1 (built in), and Claude Code with the `claude` command on PATH (used for summaries).

## Commands

| Command | What it does |
|---|---|
| `/narrate:setup` | Store your ElevenLabs API key through a Windows password dialog (`/narrate:setup remove` deletes it) |
| `/narrate:voices` | List your voices, play previews, choose one or a rotation |
| `/narrate:test [text]` | Speak a test phrase |
| `/narrate:config [change]` | Show or change settings, such as length, volume, model or summaries |
| `/narrate:off` / `/narrate:on` | Mute or unmute |

## ElevenLabs key: recommended settings

Create a **restricted** key at elevenlabs.io → Developers → API Keys:

- **Text to Speech:** Access (required)
- **Voices:** Read (optional, lets `/narrate:voices` list your voices)
- **Everything else:** no access
- Set a **credit limit**. Updates are short (about 250 characters), so 100,000–200,000 credits a month is plenty.

## Settings

`%APPDATA%\narrate\config.json`, applied immediately. Ask `/narrate:config` or edit it directly:

| Key | Default | |
|---|---|---|
| `enabled` | `true` | Master switch |
| `provider` | `"auto"` | `auto` (ElevenLabs if a key is set, else Windows), `elevenlabs`, or `windows` |
| `voiceId` | George | ElevenLabs voice |
| `voiceIds` | `[]` | Rotation list: one random voice per session |
| `modelId` | `"eleven_v4_turbo"` | ElevenLabs model |
| `maxWords` | `40` | Longest spoken update |
| `summarize` | `true` | Summarize long replies with Claude Haiku (about 5–7 s). `false` reads the first sentences instead, which is faster |
| `sayProject` | `true` | Say the project folder name first |
| `volume` | `0.9` | 0.0 – 1.0 |
| `windowsVoice` | `""` | Installed Windows voice to use in free mode |

## Privacy and security

- **Your key** is entered in a Windows dialog, never typed into the chat or onto a command line. It is stored encrypted with Windows DPAPI in `%APPDATA%\narrate\key.dat`, and only your Windows account can decrypt it.
- **Claude's replies are never run as commands.** Text reaches ElevenLabs as a JSON request body, reaches the summarizer as standard input to `claude -p` (with all tools disabled), and reaches the Windows voice as an in-process .NET string. So a reply containing `&`, `|`, quotes or other shell characters is only ever spoken.
- **What leaves your PC:** with ElevenLabs, the short spoken summary is sent to ElevenLabs. With summaries on, the reply is summarized by Claude Haiku through your own Claude Code login. In Windows-voice mode with `summarize: false`, nothing leaves your PC.
- Hooks run in the background (`async`) and never slow Claude down.

## Troubleshooting

- **Silent?** Check `%APPDATA%\narrate\narrate.log`. Every spoken line and every error is logged there.
- **401 from ElevenLabs:** the key is wrong or lacks the Text to Speech permission. Run `/narrate:setup` again.
- **Hooks not running in an already-open session:** run `/hooks` once or restart Claude Code.

## Uninstall

`/plugin uninstall narrate@narrate`, then delete `%APPDATA%\narrate`.

## License

MIT
