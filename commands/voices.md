---
description: List your voices, preview them, and choose one or a per-session rotation
allowed-tools: Bash, PowerShell, Read, Edit
---

Help the user browse and choose voices. Arguments: $ARGUMENTS

1. List voices:
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/voices.ps1"`
   (Add `-Windows` to list installed Windows voices instead.) Show the result as a short numbered table: name, category, whether it is tuned for v4. Voices tuned for v4 sound best with the default model `eleven_v4_turbo`.

2. Offer previews. For each voice the user wants to hear, run one at a time, with the number and name spoken first so they can tell them apart:
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/narrate.ps1" -Event Test -VoiceId <id> -Text "Voice <n>, <name>. I fixed the login bug and all three tests pass. Should I add a retry now, or leave it for later?"`
   Each preview costs roughly 150 ElevenLabs credits; mention this before playing many.

3. Save the choice in `%APPDATA%\narrate\config.json` (read it first, keep other keys):
   - One voice: set `"voiceId"` and set `"voiceIds": []`.
   - A rotation: set `"voiceIds"` to the list of IDs. Each new Claude Code session then gets one of them at random and keeps it for the whole session. Also add `"voiceNames": { "<id>": "<name>" }` so the log names the voice.
   - Windows voice: set `"windowsVoice"` to the installed voice name.
   Changes apply immediately, no restart.

To add voices from the public ElevenLabs Voice Library, the user opens Voice Library on elevenlabs.io and clicks Add; they then appear in step 1.
