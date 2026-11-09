---
description: Set up narrate - store your ElevenLabs API key securely (or use the free Windows voice)
allowed-tools: Bash, PowerShell
---

Help the user set up narrate. Arguments: $ARGUMENTS

1. Tell the user, briefly:
   - Without a key, narrate already works with the free built-in Windows voice.
   - For ElevenLabs voices they need an API key from elevenlabs.io → Developers → API Keys. Recommend a **restricted** key: **Text to Speech: Access**, **Voices: Read** (optional, lets `/narrate:voices` list voices), everything else off, plus a **credit limit** (100,000–200,000 credits a month is plenty).
   - They must never paste the key into this chat. A small window will ask for it.
   - Optional: setting **Voices** to **Write** for a few minutes lets `/narrate:voices` add voices from the ElevenLabs library to their account (they can switch it back to Read afterwards).

2. If the arguments say `remove`, run this and report the result:
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/setup-key.ps1" -Remove`

3. Otherwise, once the user says their key is ready, run:
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/setup-key.ps1"`
   A small "narrate: ElevenLabs API key" window opens on top of everything. They paste the key and click **Save key**. The script checks the key with one short phrase, saves it encrypted for their Windows account (`%APPDATA%\narrate\key.dat`) and plays "Narrate is set up."

4. Report what the script printed. If it failed, explain the message (401 = wrong key or missing Text to Speech permission). Then suggest `/narrate:voices` to pick a voice and `/narrate:test` to hear it.

Never read, print or echo the key or the contents of key.dat.
