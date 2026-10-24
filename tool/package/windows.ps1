# Packs the Windows release folder as a zip, a setup.exe (Inno Setup) and an
# .msi (WiX 5):
#
#   flutter build windows --release
#   $env:VERSION = '0.3.0'; tool/package/windows.ps1
#
# Everything lands in dist\.
$ErrorActionPreference = 'Stop'

$Version = $env:VERSION
if (-not $Version) {
  $Version = (Select-String -Path pubspec.yaml -Pattern '^version:\s*([^+\s]+)').Matches[0].Groups[1].Value
}
# * Windows Installer only takes numbers, so 0.3.0-beta.1 becomes 0.3.0
$MsiVersion = ($Version -split '[-+]')[0]

$Bundle = Resolve-Path build\windows\x64\runner\Release
$Dist = New-Item -ItemType Directory -Force dist
$Packaging = Resolve-Path windows\packaging

# * The Visual C++ runtime, so Stash starts on PCs that never installed it
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
  Copy-Item "$env:WINDIR\System32\$dll" $Bundle
}

Compress-Archive -Path "$Bundle\*" -DestinationPath "$Dist\stash-windows-x64.zip" -Force

$Iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $Iscc)) {
  choco install innosetup --no-progress -y | Out-Host
}
& $Iscc /Q "/DAppVersion=$Version" "/DBundleDir=$Bundle" "/DOutputDir=$Dist" "$Packaging\stash.iss"
if ($LASTEXITCODE) { throw "Inno Setup failed ($LASTEXITCODE)" }

if (-not (Get-Command wix -ErrorAction SilentlyContinue)) {
  dotnet tool install --global wix --version 5.0.2 | Out-Host
  $env:PATH += ";$env:USERPROFILE\.dotnet\tools"
}
wix build "$Packaging\stash.wxs" -arch x64 -d "Version=$MsiVersion" `
  -bindpath "bundle=$Bundle" -o "$Dist\stash-windows-x64.msi"
if ($LASTEXITCODE) { throw "WiX failed ($LASTEXITCODE)" }
Remove-Item "$Dist\*.wixpdb" -ErrorAction SilentlyContinue

Get-ChildItem $Dist
