---
description: Speak a test phrase with narrate (optionally with a specific voice ID)
allowed-tools: Bash, PowerShell, Read
---

Speak a test phrase. Arguments: $ARGUMENTS

- If the arguments contain an ElevenLabs voice ID (about 20 letters and digits), pass it as `-VoiceId`.
- If they contain other text, use it as the phrase; otherwise use a sample status update such as "I fixed the login bug and all three tests pass. Should I add a retry now, or leave it for later?"

Run (put the phrase in -Text exactly as a single argument):
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/narrate.ps1" -Event Test -Text "<phrase>" [-VoiceId <id>]`

The audio plays on the user's speakers; you cannot hear it. If the command prints `narrate error:`, explain it. Otherwise read the last lines of `%APPDATA%\narrate\narrate.log` and report which voice was used.
