param([string]$Choice,[string]$GameRoot=$PSScriptRoot)
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding($false)
function FileDigest([string]$Path) { $h=[Security.Cryptography.SHA256]::Create();try {[BitConverter]::ToString($h.ComputeHash([IO.File]::ReadAllBytes($Path)))} finally {$h.Dispose()} }
try {
 $GameRoot=[IO.Path]::GetFullPath($GameRoot)
 $exe=Join-Path $GameRoot 'South Park - The Stick of Truth.exe'
 if (-not (Test-Path -LiteralPath $exe)) {throw 'Put these two switcher files next to the game EXE.'}
 if (Get-Process -Name 'South Park - The Stick of Truth' -ErrorAction SilentlyContinue) {throw 'Close the game before switching language.'}
 $languages=@(
  [pscustomobject]@{number='1';folder='english';label='English'},
  [pscustomobject]@{number='2';folder='azerbaijani';label='Azerbaijani'},
  [pscustomobject]@{number='4';folder='polish';label='Polish'},
  [pscustomobject]@{number='5';folder='russian';label='Russian'},
  [pscustomobject]@{number='6';folder='french';label='French'},
  [pscustomobject]@{number='7';folder='german';label='German'},
  [pscustomobject]@{number='8';folder='italian';label='Italian'},
  [pscustomobject]@{number='9';folder='spanish';label='Spanish'},
  [pscustomobject]@{number='10';folder='brazilian';label='Portuguese (Brazil)'}
 )
 if (-not $Choice) {
  Write-Host "`nSouth Park - Language`n"
  foreach ($language in $languages) {$extra=if (Test-Path -LiteralPath (Join-Path $GameRoot ('lang\'+$language.folder))) {''} else {' [not installed]'};Write-Host ($language.number+' - '+$language.label+$extra)}
  Write-Host '3 - Restore files from before the first switch'
  Write-Host '0 - Exit'
  $Choice=Read-Host 'Choose a number'
 }
 if ($Choice -eq '0') {exit 0}
 $files=@('data_localized_en.oaf','data\game.oeisku');$backup=Join-Path $GameRoot 'language-switch-backup';$mp=Join-Path $backup 'original-files.json'
 if ($Choice -eq '3') {
  if (-not (Test-Path -LiteralPath $mp)) {throw 'No language-switch backup exists.'}
  $entries=Get-Content -LiteralPath $mp -Raw | ConvertFrom-Json
  foreach ($f in $files) {$e=@($entries | Where-Object {$_.file -eq $f});if ($e.Count -ne 1) {throw 'Invalid backup manifest.'};if ($e[0].existed -and -not (Test-Path -LiteralPath (Join-Path $backup $f))) {throw 'A backup file is missing.'}}
  foreach ($f in $files) {$e=$entries | Where-Object {$_.file -eq $f};$target=Join-Path $GameRoot $f;if ($e.existed) {[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null;Copy-Item -LiteralPath (Join-Path $backup $f) -Destination $target -Force} elseif (Test-Path -LiteralPath $target) {Remove-Item -LiteralPath $target}}
  Write-Host 'Previous language files restored. Backup retained.';exit 0
 }
 $selected=@($languages | Where-Object {$_.number -eq $Choice});if ($selected.Count -ne 1) {throw 'Invalid choice.'};$selected=$selected[0]
 $config=Join-Path $GameRoot 'config.ini'
 if (Test-Path -LiteralPath $config) {
  $text=Get-Content -LiteralPath $config -Raw
  if ($text -match '(?im)^\s*language_code\s*=\s*az\s*(?:[;#].*)?$') {throw 'AZ code experiment is active. Open Test-AZ-Code.cmd and choose 2 (Restore) first.'}
 }
 $source=Join-Path $GameRoot ('lang\'+$selected.folder)
 $skuPath=Join-Path $source 'data\game.oeisku'
 if (-not (Test-Path -LiteralPath $skuPath)) {throw ('Language is not installed: '+$selected.label)}
 [xml]$sku=Get-Content -LiteralPath $skuPath -Raw -Encoding UTF8
 $archives=@($sku.OEISKU.LanguageSKU | Where-Object {$_.HasText -eq 'True'})
 if ($archives.Count -ne 1) {throw 'Cannot identify a unique text archive for this language.'}
 $archiveName=[string]$archives[0].Archive
 if ([IO.Path]::GetFileName($archiveName) -ne $archiveName -or $archiveName -notmatch '^data_localized_[a-z]+\.oaf$') {throw 'Unexpected language archive path.'}
 $archive=Join-Path $source $archiveName
 $englishSku=Join-Path $GameRoot 'lang\english\data\game.oeisku'
 foreach ($p in @($archive,$englishSku)) {if (-not (Test-Path -LiteralPath $p)) {throw ('Missing file: '+$p)}}
 # All text languages use the working English loading profile; voice remains English.
 [xml]$control=Get-Content -LiteralPath $englishSku -Raw -Encoding UTF8
 if ($control.OEISKU.DefaultText -ne 'en') {throw 'The original English configuration is required in lang\english.'}
 $sources=@($archive,$englishSku)
 if (-not (Test-Path -LiteralPath $mp)) {
  $entries=foreach ($f in $files) {$target=Join-Path $GameRoot $f;$exists=Test-Path -LiteralPath $target;if ($exists) {$saved=Join-Path $backup $f;[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($saved)) | Out-Null;Copy-Item -LiteralPath $target -Destination $saved -Force};[pscustomobject]@{file=$f;existed=[bool]$exists}}
  [IO.Directory]::CreateDirectory($backup) | Out-Null;$entries | ConvertTo-Json | Set-Content -LiteralPath $mp -Encoding UTF8
 }
 for ($i=0;$i -lt $files.Count;$i++) {$target=Join-Path $GameRoot $files[$i];[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null;Copy-Item -LiteralPath $sources[$i] -Destination $target -Force;if ((FileDigest $target) -ne (FileDigest $sources[$i])) {throw 'Copy verification failed.'}}
 Write-Host ('Selected: '+$selected.label) -ForegroundColor Green
 Write-Host 'Start the game without changing language in another launcher. Voice remains English.'
 if ($selected.folder -eq 'azerbaijani') {Write-Host 'Azerbaijani update 34: extracted text translated; proofreading in progress.'}
} catch {Write-Host ('ERROR: '+$_.Exception.Message) -ForegroundColor Red;exit 1}
