<#
  narrate: find, preview and choose voices.

    voices.ps1                         # your ElevenLabs voices (needs Voices: Read)
    voices.ps1 -Search "funny old man" # search the public ElevenLabs Voice Library
    voices.ps1 -Preview <id>[,<id>...] # play each voice's free preview clip (no credits)
    voices.ps1 -Add <id>[,<id>...]     # add library voices to your account (needs Voices: Write)
    voices.ps1 -Use <id>[,<id>...]     # one id = that voice; several = per-session rotation
    voices.ps1 -Windows                # installed Windows voices
    voices.ps1 -Windows -Preview "Microsoft Zira Desktop"
    voices.ps1 -Windows -Use "Microsoft Zira Desktop"

  Results of the last listing and search are cached in %APPDATA%\narrate\cache,
  so -Preview, -Add and -Use know each voice's name and preview clip.
#>
param(
  [string]$Search,
  [string[]]$Preview,
  [string[]]$Add,
  [string[]]$Use,
  [switch]$Windows,
  [int]$Count = 15
)

# When launched from Git Bash or PowerShell 7, PSModulePath points at PowerShell 7
# modules and Windows PowerShell cannot load its own (Get-Credential,
# ConvertTo-SecureString). Use Windows PowerShell's own module path.
if ($PSVersionTable.PSEdition -ne 'Core') {
  $env:PSModulePath = (@([Environment]::GetFolderPath('MyDocuments') + '\WindowsPowerShell\Modules',
    "$env:ProgramFiles\WindowsPowerShell\Modules", "$PSHOME\Modules") -join ';')
}
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding $false } catch {}   # names and descriptions are UTF-8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Data    = Join-Path $env:APPDATA 'narrate'
$Cache   = Join-Path $Data 'cache'
$KeyFile = Join-Path $Data 'key.dat'
$CfgFile = Join-Path $Data 'config.json'
$MineCache   = Join-Path $Cache 'my-voices.json'
$SearchCache = Join-Path $Cache 'search.json'
New-Item -ItemType Directory -Force -Path $Cache | Out-Null

# Accept "a,b" as well as "a","b".
function Split-Ids([string[]]$list) { @($list | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
function Assert-Id([string]$id) { if ($id -notmatch '^[A-Za-z0-9]{8,40}$') { throw "Not a voice ID: $id" } }

function Get-ApiKey {
  if (-not (Test-Path $KeyFile)) { throw 'No ElevenLabs key set up. Run /narrate:setup first.' }
  $ss = ConvertTo-SecureString ((Get-Content $KeyFile -Raw).Trim())   # DPAPI: this Windows user only
  return (New-Object Net.NetworkCredential('', $ss)).Password
}

function Invoke-Eleven([string]$path, [string]$method = 'Get', $body = $null) {
  $p = @{ Uri = "https://api.elevenlabs.io$path"; Method = $method; UseBasicParsing = $true; TimeoutSec = 30
          Headers = @{ 'xi-api-key' = (Get-ApiKey) } }
  if ($body) { $p.ContentType = 'application/json; charset=utf-8'; $p.Body = [Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Compress)) }
  # Decode the bytes as UTF-8 ourselves: Windows PowerShell 5.1 guesses Latin-1 and mangles names.
  $r = Invoke-WebRequest @p
  [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json
}

function Get-StatusCode($err) { try { return [int]$err.Exception.Response.StatusCode } catch { return $null } }

function Read-Cache([string]$file) {
  # Windows PowerShell 5.1 hands a JSON array back as ONE object; foreach unrolls it.
  if (Test-Path $file) {
    try { $all = (Get-Content $file -Raw -Encoding UTF8).TrimStart([char]0xFEFF) | ConvertFrom-Json; foreach ($v in $all) { $v } } catch {}
  }
}
function Find-Voice([string]$id) {
  $hit = @(Read-Cache $SearchCache) + @(Read-Cache $MineCache) | Where-Object { $_.id -eq $id } | Select-Object -First 1
  if ($hit) { return $hit }
  try {   # a voice in the account that was not in the last listing
    $v = Invoke-Eleven "/v1/voices/$id"
    return [pscustomobject]@{ id = $v.voice_id; name = $v.name; preview = $v.preview_url }
  } catch { return $null }
}

function Play-Url([string]$url) {
  $u = [uri]$url
  if ($u.Scheme -ne 'https') { throw "Refusing a non-https preview link: $url" }
  $tmp = Join-Path $env:TEMP ('narrate-preview-' + [guid]::NewGuid().ToString('N') + '.mp3')
  try {
    Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 30 -OutFile $tmp | Out-Null
    Add-Type -AssemblyName PresentationCore
    $mp = New-Object System.Windows.Media.MediaPlayer
    $mp.Open([uri]$tmp); $n = 0
    while (-not $mp.NaturalDuration.HasTimeSpan -and $n -lt 50) { Start-Sleep -Milliseconds 100; $n++ }
    $mp.Play()
    $ms = if ($mp.NaturalDuration.HasTimeSpan) { $mp.NaturalDuration.TimeSpan.TotalMilliseconds } else { 12000 }
    Start-Sleep -Milliseconds ([int]$ms + 400); $mp.Close()
  } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
}

function Update-Config([scriptblock]$change) {
  $cfg = [ordered]@{}
  if (Test-Path $CfgFile) {
    $j = (Get-Content $CfgFile -Raw -Encoding UTF8).TrimStart([char]0xFEFF) | ConvertFrom-Json
    foreach ($p in $j.PSObject.Properties) { $cfg[$p.Name] = $p.Value }
  }
  & $change $cfg
  [IO.File]::WriteAllText($CfgFile, ($cfg | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding $false))
}

try {
  # ---------- Windows voices ----------
  if ($Windows -or (-not (Test-Path $KeyFile) -and -not ($Search -or $Add))) {
    Add-Type -AssemblyName System.Speech
    $s = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $installed = @($s.GetInstalledVoices() | Where-Object Enabled | ForEach-Object { $_.VoiceInfo })
    if ($Preview) {
      foreach ($name in $Preview) {
        $s.SelectVoice($name); "Playing: $name"
        $s.Speak("Hi, I'm $($name -replace '^Microsoft |\s*Desktop$', ''). I fixed the login bug and all three tests pass.")
      }
    } elseif ($Use) {
      $name = $Use[0]
      if (-not ($installed | Where-Object Name -eq $name)) { throw "No installed Windows voice named '$name'." }
      Update-Config { param($c) $c.windowsVoice = $name }
      "Saved. The Windows voice is now $name."
    } else {
      if (-not $Windows) { 'No ElevenLabs key set up (run /narrate:setup for ElevenLabs voices). Installed Windows voices:' }
      $installed | ForEach-Object { '{0} | {1} | {2}' -f $_.Name, $_.Gender, $_.Culture }
    }
    $s.Dispose(); exit 0
  }

  # ---------- search the public library ----------
  if ($Search) {
    $q = [uri]::EscapeDataString($Search)
    $r = Invoke-Eleven "/v1/shared-voices?page_size=$Count&search=$q&sort=trending"
    $list = @($r.voices | ForEach-Object {
      [pscustomobject]@{ id = $_.voice_id; owner = $_.public_owner_id; name = $_.name; preview = $_.preview_url
        about = (@($_.gender, $_.age, $_.accent, $_.use_case) | Where-Object { $_ }) -join ', '
        description = [string]$_.description; users = $_.cloned_by_count }
    })
    $list | ConvertTo-Json -Depth 4 | Set-Content $SearchCache -Encoding UTF8
    if (-not $list.Count) { "No library voices match '$Search'. Try broader words, like 'funny', 'old', 'british' or 'narrator'."; exit 0 }
    "$($list.Count) library voices for '$Search' (n | id | name | about | used by | description):"
    $i = 0
    foreach ($v in $list) {
      $i++; $d = ($v.description -replace '\s+', ' ').Trim(); if ($d.Length -gt 90) { $d = $d.Substring(0, 87) + '...' }
      '{0} | {1} | {2} | {3} | {4} | {5}' -f $i, $v.id, $v.name, $v.about, $v.users, $d
    }
    exit 0
  }

  # ---------- free preview clips ----------
  if ($Preview) {
    foreach ($id in @(Split-Ids $Preview)) {
      Assert-Id $id
      $v = Find-Voice $id
      if (-not $v -or -not $v.preview) { "No preview clip for $id."; continue }
      "Playing: $($v.name)"
      Play-Url $v.preview
    }
    exit 0
  }

  # ---------- add library voices to the account ----------
  if ($Add) {
    foreach ($id in @(Split-Ids $Add)) {
      Assert-Id $id
      $v = Read-Cache $SearchCache | Where-Object { $_.id -eq $id } | Select-Object -First 1
      if (-not $v) { "Search for $id first (voices.ps1 -Search ...), so its owner is known."; continue }
      try {
        $res = Invoke-Eleven "/v1/voices/add/$($v.owner)/$id" 'Post' @{ new_name = [string]$v.name }
        $newId = if ($res.voice_id) { $res.voice_id } else { $id }
        "Added: $($v.name) | $newId"
        $mine = @(Read-Cache $MineCache | Where-Object { $_.id -ne $newId }) + [pscustomobject]@{ id = $newId; name = $v.name; preview = $v.preview; category = 'professional'; v4 = '?' }
        $mine | ConvertTo-Json -Depth 4 | Set-Content $MineCache -Encoding UTF8
      } catch {
        $code = Get-StatusCode $_
        if ($code -in 401, 403) { "Could not add $($v.name): your key needs Voices set to Write (elevenlabs.io > Developers > API Keys). You can switch it back to Read afterwards." }
        else { "Could not add $($v.name): $($_.Exception.Message)" }
      }
    }
    exit 0
  }

  # ---------- save the choice ----------
  if ($Use) {
    $ids = @(Split-Ids $Use)
    $ids | ForEach-Object { Assert-Id $_ }
    $names = [ordered]@{}
    foreach ($id in $ids) { $v = Find-Voice $id; $names[$id] = if ($v) { [string]$v.name } else { $id } }
    Update-Config {
      param($c)
      $c.voiceId = $ids[0]
      $c.voiceIds = @(if ($ids.Count -gt 1) { $ids })
      $c.voiceNames = $names
    }
    if ($ids.Count -gt 1) { "Saved a rotation of $($ids.Count) voices: $(@($names.Values) -join ', '). Each new session gets one of them." }
    else { "Saved. The voice is now $($names[$ids[0]])." }
    exit 0
  }

  # ---------- list your voices ----------
  $r = Invoke-Eleven '/v1/voices'
  $list = @($r.voices | Sort-Object category, name | ForEach-Object {
    [pscustomobject]@{ id = $_.voice_id; name = $_.name; category = $_.category; preview = $_.preview_url
      v4 = $(if (($_.high_quality_base_model_ids -join ',') -match 'eleven_v4') { 'yes' } else { '-' }) }
  })
  $list | ConvertTo-Json -Depth 4 | Set-Content $MineCache -Encoding UTF8
  $current = @()
  if (Test-Path $CfgFile) {
    try {
      $c = (Get-Content $CfgFile -Raw -Encoding UTF8).TrimStart([char]0xFEFF) | ConvertFrom-Json
      $current = @(if (@($c.voiceIds).Count) { $c.voiceIds } else { $c.voiceId })
    } catch {}
  }
  "$($list.Count) voices in your account (n | id | name | category | tuned for v4 | in use):"
  $i = 0
  foreach ($v in $list) { $i++; '{0} | {1} | {2} | {3} | {4} | {5}' -f $i, $v.id, $v.name, $v.category, $v.v4, $(if ($current -contains $v.id) { 'yes' } else { '' }) }
}
catch {
  $code = Get-StatusCode $_
  if ($code -eq 401) { 'ElevenLabs refused (401). Listing and searching voices need the key''s Voices permission set to Read; adding needs Write. Speech works without it.' }
  else { "narrate error: $($_.Exception.Message)" }
  exit 1
}
