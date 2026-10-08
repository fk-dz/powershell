<#
 FATYAK Shell - run Python, JavaScript, TypeScript, Java, Go, PHP, C and C++ from PowerShell.
 100% local, free, no API, no installer: each runtime is a portable ZIP downloaded once
 to %LOCALAPPDATA%\FATYAK (nothing touches PATH or the registry; delete the folder to remove all).
 Developer: FATYAK | License: MIT
#>
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$Root = Join-Path $env:LOCALAPPDATA 'FATYAK'
$Work = Join-Path $Root 'work'
New-Item -ItemType Directory -Force $Work | Out-Null
$env:GOCACHE = Join-Path $Root 'gocache'
$env:GOPATH  = Join-Path $Root 'gopath'
$Host.UI.RawUI.WindowTitle = 'FATYAK Shell'

# Runtime catalog. Change a URL here to update a version.
$Catalog = [ordered]@{
  python = @{ Label='Python 3.12';  Size='10 MB';  Exe='python.exe'; Ext='py';   Url='https://www.python.org/ftp/python/3.12.7/python-3.12.7-embed-amd64.zip' }
  node   = @{ Label='JavaScript (Node.js 22)'; Size='30 MB'; Exe='node.exe'; Ext='js'; Url='https://nodejs.org/dist/v22.11.0/node-v22.11.0-win-x64.zip' }
  deno   = @{ Label='TypeScript (Deno)'; Size='40 MB'; Exe='deno.exe'; Ext='ts'; Url='https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip' }
  java   = @{ Label='Java 21 (Temurin)'; Size='190 MB'; Exe='java.exe'; Ext='java'; Url='https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jdk_x64_windows_hotspot_21.0.5_11.zip' }
  go     = @{ Label='Go 1.23'; Size='75 MB'; Exe='go.exe'; Ext='go'; Url='https://go.dev/dl/go1.23.3.windows-amd64.zip' }
  php    = @{ Label='PHP 8.3'; Size='30 MB'; Exe='php.exe'; Ext='php'; Url='https://windows.php.net/downloads/releases/archives/php-8.3.13-nts-Win32-vs16-x64.zip' }
  c      = @{ Label='C  (Zig toolchain)'; Size='80 MB'; Exe='zig.exe'; Ext='c'; Url='https://ziglang.org/download/0.13.0/zig-windows-x86_64-0.13.0.zip'; Zig='cc' }
  cpp    = @{ Label='C++ (Zig toolchain)'; Size='shared with C'; Exe='zig.exe'; Ext='cpp'; Url='https://ziglang.org/download/0.13.0/zig-windows-x86_64-0.13.0.zip'; Zig='c++'; Dir='c' }
}

function Say($t,$c='White'){ Write-Host $t -ForegroundColor $c }
function Show-Banner {
  Clear-Host
  Say @'

   ███████╗ █████╗ ████████╗██╗   ██╗ █████╗ ██╗  ██╗
   ██╔════╝██╔══██╗╚══██╔══╝╚██╗ ██╔╝██╔══██╗██║ ██╔╝
   █████╗  ███████║   ██║    ╚████╔╝ ███████║█████╔╝
   ██╔══╝  ██╔══██║   ██║     ╚██╔╝  ██╔══██║██╔═██╗
   ██║     ██║  ██║   ██║      ██║   ██║  ██║██║  ██╗
   ╚═╝     ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
'@ 'DarkYellow'
  Say '   S H E L L   ·   local, free, no API, no install   ·   by FATYAK' 'Magenta'
  Say ('   ' + ('─' * 70)) 'DarkGray'
}
function Get-Exe($key) {
  $r = $Catalog[$key]; $dir = Join-Path $Root ($(if ($r.Dir) { $r.Dir } else { $key }))
  if (-not (Test-Path $dir)) { return $null }
  Get-ChildItem $dir -Recurse -Filter $r.Exe -File -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}
function Install-Runtime($key) {
  $exe = Get-Exe $key; if ($exe) { return $exe }
  $r = $Catalog[$key]; $name = if ($r.Dir) { $r.Dir } else { $key }
  $dir = Join-Path $Root $name; $zip = Join-Path $Root "$name.zip"
  Say "   Downloading $($r.Label) (~$($r.Size)), one time only..." 'Yellow'
  Invoke-WebRequest $r.Url -OutFile $zip -UseBasicParsing
  Expand-Archive $zip -DestinationPath $dir -Force; Remove-Item $zip
  if ($key -eq 'python') {   # enable site-packages in the embeddable build
    $pth = Get-ChildItem $dir -Filter '*._pth' | Select-Object -First 1
    (Get-Content $pth.FullName) -replace '^#import site','import site' | Set-Content $pth.FullName
  }
  Get-Exe $key
}
function Read-Code {
  Say '   Paste or type your code. Finish with a line containing only :run' 'Cyan'
  $l = @(); while (($x = Read-Host '  ') -ne ':run') { $l += $x }; $l -join "`n"
}
function Invoke-Lang($key, $file) {
  $r = $Catalog[$key]; $exe = Install-Runtime $key
  Say "   Running with $($r.Label)...`n" 'DarkGray'
  switch ($key) {
    'go'   { & $exe run $file }
    'deno' { & $exe run --allow-all $file }
    'c'    { $o = "$file.exe"; & $exe cc  -o $o $file; if ($LASTEXITCODE -eq 0) { & $o } }
    'cpp'  { $o = "$file.exe"; & $exe c++ -o $o $file; if ($LASTEXITCODE -eq 0) { & $o } }
    default { & $exe $file }
  }
  Say "`n   exit code: $LASTEXITCODE" 'DarkGray'
}
function Invoke-Menu {
  $keys = @($Catalog.Keys)
  Say '   Choose a language:' 'Cyan'
  for ($i=0; $i -lt $keys.Count; $i++) {
    $ok = if (Get-Exe $keys[$i]) { '● ready' } else { '○ downloads on first use' }
    Say ('   [{0}] {1,-26} {2}' -f ($i+1), $Catalog[$keys[$i]].Label, $ok) 'White'
  }
  $n = [int](Read-Host "`n   Number") - 1
  $key = $keys[$n]; $r = $Catalog[$key]
  Say '   [1] Type/paste code   [2] Run an existing file' 'Cyan'
  if ($key -eq 'python') { Say '   [3] Interactive Python console' 'Cyan' }
  switch (Read-Host '   Choose') {
    '1' { $f = Join-Path $Work "snippet.$($r.Ext)"; Set-Content $f (Read-Code) -Encoding UTF8; Invoke-Lang $key $f }
    '2' { Invoke-Lang $key (Read-Host '   File path') }
    '3' { & (Install-Runtime 'python') -i }
  }
}

while ($true) {
  Show-Banner
  Say '   [1] Run code' 'White'
  Say '   [2] Open the runtimes folder' 'White'
  Say '   [0] Exit' 'White'
  $c = Read-Host "`n   fatyak"
  try {
    switch ($c) {
      '1' { Invoke-Menu }
      '2' { Invoke-Item $Root }
      '0' { Say '   Bye - FATYAK' 'Magenta'; return }
      default { continue }
    }
  } catch { Say "   Error: $($_.Exception.Message)" 'Red' }
  Read-Host "`n   Press Enter to return to the menu" | Out-Null
}
