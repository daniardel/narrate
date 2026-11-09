<#
  narrate: list the voices in your ElevenLabs "My Voices" (needs the key's
  Voices permission set to Read), or the Windows voices installed on this PC.

    voices.ps1             # ElevenLabs voices: id | name | category | tuned for v4
    voices.ps1 -Windows    # installed Windows voices
#>
param([switch]$Windows)

# When launched from Git Bash or PowerShell 7, PSModulePath points at PowerShell 7
# modules and Windows PowerShell cannot load its own (Get-Credential,
# ConvertTo-SecureString). Use Windows PowerShell's own module path.
if ($PSVersionTable.PSEdition -ne 'Core') {
  $env:PSModulePath = (@([Environment]::GetFolderPath('MyDocuments') + '\WindowsPowerShell\Modules',
    "$env:ProgramFiles\WindowsPowerShell\Modules", "$PSHOME\Modules") -join ';')
}
$ErrorActionPreference = 'Stop'
$KeyFile = Join-Path (Join-Path $env:APPDATA 'narrate') 'key.dat'

if ($Windows -or -not (Test-Path $KeyFile)) {
  if (-not $Windows) { 'No ElevenLabs key set up (run /narrate:setup). Installed Windows voices:' }
  Add-Type -AssemblyName System.Speech
  $s = New-Object System.Speech.Synthesis.SpeechSynthesizer
  $s.GetInstalledVoices() | Where-Object Enabled | ForEach-Object { '{0} | {1} | {2}' -f $_.VoiceInfo.Name, $_.VoiceInfo.Gender, $_.VoiceInfo.Culture }
  exit 0
}

$key = (New-Object Net.NetworkCredential('', (ConvertTo-SecureString ((Get-Content $KeyFile -Raw).Trim())))).Password
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $v = Invoke-RestMethod -Uri 'https://api.elevenlabs.io/v1/voices' -Headers @{ 'xi-api-key' = $key } -UseBasicParsing
} catch {
  $code = $null; try { $code = [int]$_.Exception.Response.StatusCode } catch {}
  if ($code -eq 401) { 'The key cannot list voices. In ElevenLabs, set the key''s Voices permission to Read (speech still works without it).' }
  else { "Could not list voices: $($_.Exception.Message)" }
  exit 1
}
"$($v.voices.Count) voices (id | name | category | tuned for v4):"
$v.voices | Sort-Object category, name | ForEach-Object {
  '{0} | {1} | {2} | {3}' -f $_.voice_id, $_.name, $_.category, $(if (($_.high_quality_base_model_ids -join ',') -match 'eleven_v4') { 'yes' } else { '-' })
}
