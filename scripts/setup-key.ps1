<#
  narrate: store (or remove) your ElevenLabs API key.

  Opens a small always-on-top window; paste the key into it.
  The key never appears in the chat or on any command line. It is encrypted
  with Windows DPAPI into %APPDATA%\narrate\key.dat, readable only by your
  Windows account, then checked with one short test phrase.

    setup-key.ps1            # add or replace the key
    setup-key.ps1 -Remove    # delete the key (narrate falls back to the Windows voice)
#>
param([switch]$Remove)

# When launched from Git Bash or PowerShell 7, PSModulePath points at PowerShell 7
# modules and Windows PowerShell cannot load its own (Get-Credential,
# ConvertTo-SecureString). Use Windows PowerShell's own module path.
if ($PSVersionTable.PSEdition -ne 'Core') {
  $env:PSModulePath = (@([Environment]::GetFolderPath('MyDocuments') + '\WindowsPowerShell\Modules',
    "$env:ProgramFiles\WindowsPowerShell\Modules", "$PSHOME\Modules") -join ';')
}
$ErrorActionPreference = 'Stop'
$Data = Join-Path $env:APPDATA 'narrate'
$KeyFile = Join-Path $Data 'key.dat'
New-Item -ItemType Directory -Force -Path $Data | Out-Null

if ($Remove) {
  if (Test-Path $KeyFile) { Remove-Item $KeyFile -Force; 'Key removed. narrate will use the built-in Windows voice.' }
  else { 'No key was stored.' }
  exit 0
}

# A small always-on-top window, so it cannot open hidden behind the terminal.
function Read-KeyDialog {
  Add-Type -AssemblyName System.Windows.Forms, System.Drawing
  [Windows.Forms.Application]::EnableVisualStyles()
  $f = New-Object Windows.Forms.Form
  $f.Text = 'narrate: ElevenLabs API key'
  $f.ClientSize = New-Object Drawing.Size 460, 186
  $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false; $f.MinimizeBox = $false
  $f.AutoScaleMode = 'Dpi'; $f.StartPosition = 'CenterScreen'; $f.TopMost = $true; $f.ShowInTaskbar = $true
  $f.Font = New-Object Drawing.Font 'Segoe UI', 10
  $l = New-Object Windows.Forms.Label
  $l.Text = "Paste your ElevenLabs API key below.`nIt's encrypted for your Windows account and never shown in the chat."
  $l.SetBounds(16, 14, 430, 56)
  $t = New-Object Windows.Forms.TextBox
  $t.UseSystemPasswordChar = $true; $t.SetBounds(16, 80, 428, 26)
  $ok = New-Object Windows.Forms.Button
  $ok.Text = 'Save key'; $ok.SetBounds(262, 130, 90, 34); $ok.DialogResult = 'OK'
  $cancel = New-Object Windows.Forms.Button
  $cancel.Text = 'Cancel'; $cancel.SetBounds(358, 130, 86, 34); $cancel.DialogResult = 'Cancel'
  $f.Controls.AddRange(@($l, $t, $ok, $cancel))
  $f.AcceptButton = $ok; $f.CancelButton = $cancel
  # Claude Code starts commands with a "hidden window" request, which Windows applies to
  # the first window a process shows. Showing it again explicitly makes it visible.
  Add-Type -Namespace Narrate -Name Win -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);'
  $f.Add_Shown({ [Narrate.Win]::ShowWindow($f.Handle, 5) | Out-Null; $f.TopMost = $true; $f.Activate(); $t.Focus() })
  $result = $f.ShowDialog()
  $value = $t.Text
  $t.Text = ''; $f.Dispose()
  if ($result -ne 'OK') { return $null }
  return $value
}

$plain = Read-KeyDialog
if (-not $plain -or -not $plain.Trim()) { 'Cancelled. No key stored.'; exit 1 }

# Check the key with one short request before saving it.
$plain = $plain.Trim()
$secure = ConvertTo-SecureString $plain -AsPlainText -Force
$ok = $false
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $body = @{ text = 'Narrate is set up.'; model_id = 'eleven_v4_turbo' } | ConvertTo-Json -Compress
  $tmp = Join-Path $env:TEMP ('narrate-setup-' + [guid]::NewGuid().ToString('N') + '.mp3')
  Invoke-WebRequest -Uri 'https://api.elevenlabs.io/v1/text-to-speech/JBFqnCBsd6RMkjVDRZzb?output_format=mp3_44100_128' `
    -Method Post -UseBasicParsing -TimeoutSec 30 -Headers @{ 'xi-api-key' = $plain; 'Accept' = 'audio/mpeg' } `
    -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body)) -OutFile $tmp | Out-Null
  $ok = $true
} catch {
  $code = $null; try { $code = [int]$_.Exception.Response.StatusCode } catch {}
  if ($code -eq 401) { 'ElevenLabs rejected the key (401). Check that you copied it fully and that it has the Text to Speech permission.' }
  else { "Could not check the key: $($_.Exception.Message)" }
}
$plain = $null

if (-not $ok) { 'Key NOT saved.'; exit 1 }

$secure | ConvertFrom-SecureString | Set-Content -Path $KeyFile
'Key saved and working. Playing a test phrase...'
try {
  Add-Type -AssemblyName PresentationCore
  $mp = New-Object System.Windows.Media.MediaPlayer; $mp.Open([uri]$tmp); $n = 0
  while (-not $mp.NaturalDuration.HasTimeSpan -and $n -lt 50) { Start-Sleep -Milliseconds 100; $n++ }
  $mp.Play(); Start-Sleep -Milliseconds ([int]$mp.NaturalDuration.TimeSpan.TotalMilliseconds + 300); $mp.Close()
} catch {} finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
