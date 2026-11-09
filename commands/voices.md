---
description: Find, preview (free) and choose voices, from your account or the 20,000+ voice ElevenLabs library
argument-hint: "[search words, e.g. funny old man]"
allowed-tools: Bash, PowerShell
---

Help the user find and choose narrate voices. Arguments: $ARGUMENTS

All voice work goes through one script. Run it with:
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/voices.ps1" <options>`

| Options | What it does |
|---|---|
| (none) | List the voices in the user's ElevenLabs account, numbered, with "tuned for v4" and "in use" columns |
| `-Search "<words>"` | Search the public ElevenLabs Voice Library (top 15) |
| `-Preview <id>,<id>` | Play each voice's preview clip, one after another. **Free: no credits.** |
| `-Add <id>,<id>` | Add library voices to the user's account (only voices from the last search) |
| `-Use <id>,<id>` | Save the choice: one ID = that voice; several = a rotation, one random voice per session |
| `-Windows` | List Windows voices; with `-Preview "<name>"` or `-Use "<name>"` for those |

Only ever pass voice IDs that the script itself printed. Put search words in double quotes, and remove any `"` characters from them first.

Flow:

1. **If the arguments contain search words**, go straight to step 3. Otherwise list the user's voices (no options) and show them as a short numbered table: name, category, tuned for v4, in use. If there is no ElevenLabs key, the script lists Windows voices instead: mention that `/narrate:setup` unlocks ElevenLabs voices.

2. Ask which to hear, by number, or whether to search the library for something new (for example "funny", "old british man", "calm narrator").

3. **Search:** run `-Search`, show a numbered table: name, about (gender, age, accent, use), used by, a few words of description. Offer previews.

4. **Preview:** run `-Preview` with the chosen IDs in one call. Before running it, tell the user the order they will hear them in (the clips do not announce themselves). Previews are free, so there is no need to warn about cost.

5. **Library voices must be added before they can speak.** When the user picks library voices, run `-Add` with them. If it reports that the key needs Voices: Write, tell the user to change that on elevenlabs.io → Developers → API Keys, say when they are done, run `-Add` again, then suggest switching the permission back to Read.

6. **Save** with `-Use`: one voice, or several for a rotation (each new Claude Code session gets one of them and keeps it). Use the IDs printed by `-Add` for library voices. Changes apply right away; no restart.

7. Confirm in one line which voice or rotation is set, and that `/narrate:test` speaks a test phrase.

Voices marked "tuned for v4" sound best with the default model, `eleven_v4_turbo`.
