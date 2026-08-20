# EchoVox Installer -- Windows PowerShell
# Usage: irm https://raw.githubusercontent.com/abdullahhanif-001/EchoVox/main/install.ps1 | iex

$ErrorActionPreference = "Stop"
$EchoVoxDir = if ($env:ECHOVOX_DIR) { $env:ECHOVOX_DIR } else { "$env:USERPROFILE\EchoVox" }
$ModelUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
$ModelName = "ggml-small.bin"

function Info($msg)  { Write-Host "[EchoVox] $msg" -ForegroundColor Cyan }
function Ok($msg)    { Write-Host "[EchoVox] $msg" -ForegroundColor Green }
function Err($msg)   { Write-Host "[EchoVox] $msg" -ForegroundColor Red; exit 1 }

Info "Detected: Windows $env:PROCESSOR_ARCHITECTURE"

# --- Dependencies ---
Info "Checking dependencies..."

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Info "Installing Git..."
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
    $env:PATH = "$env:ProgramFiles\Git\cmd;$env:PATH"
}

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    Info "Installing CMake..."
    winget install --id Kitware.CMake -e --accept-source-agreements --accept-package-agreements
    $env:PATH = "$env:ProgramFiles\CMake\bin;$env:PATH"
}

$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$hasMSVC = $false
if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    if ($vsPath) { $hasMSVC = $true }
}
if (-not $hasMSVC) {
    Info "Installing Visual Studio Build Tools (C++ compiler)..."
    winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-source-agreements --accept-package-agreements --override "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --quiet --wait"
}

# --- Clone / update ---
if (Test-Path $EchoVoxDir) {
    Info "Updating existing installation at $EchoVoxDir..."
    Set-Location $EchoVoxDir
    git pull --ff-only 2>$null
} else {
    Info "Cloning EchoVox..."
    git clone https://github.com/abdullahhanif-001/EchoVox.git $EchoVoxDir
    Set-Location $EchoVoxDir
}

# --- Build ---
Info "Building whisper.cpp..."
Set-Location whisper.cpp
if (-not (Test-Path build)) { New-Item -ItemType Directory -Path build | Out-Null }
Set-Location build

cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --config Release

Ok "Build complete."

# --- Download model ---
Set-Location $EchoVoxDir
$modelDir = Join-Path $EchoVoxDir "models"
$modelPath = Join-Path $modelDir $ModelName

if (-not (Test-Path $modelPath)) {
    Info "Downloading Whisper small model (~466MB)..."
    if (-not (Test-Path $modelDir)) { New-Item -ItemType Directory -Path $modelDir | Out-Null }
    Invoke-WebRequest -Uri $ModelUrl -OutFile $modelPath -UseBasicParsing
    Ok "Model downloaded."
} else {
    Ok "Model already exists."
}

# --- Verify ---
Info "Checking build output..."
$bin = Join-Path $EchoVoxDir "whisper.cpp\build\bin\Release\whisper-cli.exe"
if (-not (Test-Path $bin)) {
    $bin = Join-Path $EchoVoxDir "whisper.cpp\build\Release\whisper-cli.exe"
}
if (-not (Test-Path $bin)) {
    $bin = Join-Path $EchoVoxDir "whisper.cpp\build\bin\whisper-cli.exe"
}
if (Test-Path $bin) {
    Ok "whisper-cli.exe found at $bin"
} else {
    Info "Binary location may vary. Check whisper.cpp\build\ for whisper-cli.exe"
}

Write-Host ""
Ok "============================================"
Ok "  EchoVox installed at: $EchoVoxDir"
Ok "  Model: models\$ModelName"
Ok "============================================"
Write-Host ""
Info "Quick start:"
Write-Host "  cd $EchoVoxDir"
Write-Host "  .\whisper.cpp\build\bin\Release\whisper-cli.exe -m models\$ModelName -l ur -f your_audio.wav"
