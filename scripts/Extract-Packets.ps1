<#
.SYNOPSIS
    Extracts and decompiles Hytale protocol classes from a server JAR file.

.DESCRIPTION
    This script extracts the full com.hypixel.hytale.protocol package
    (including packets, entities, enums, and other protocol classes)
    and decompiles them using Vineflower decompiler.

.PARAMETER JarPath
    Path to the Hytale server JAR file.

.PARAMETER OutputPath
    Path where decompiled sources will be written.

.PARAMETER VineflowerPath
    Path to the Vineflower JAR file (will be downloaded if not present).

.EXAMPLE
    .\Extract-Packets.ps1 -JarPath "HytaleServer.jar" -OutputPath "protocol"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$JarPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "protocol",

    [Parameter(Mandatory = $false)]
    [string]$VineflowerPath = "vineflower.jar"
)

$ErrorActionPreference = "Stop"

# Constants
$VINEFLOWER_VERSION = "1.10.1"
$VINEFLOWER_URL = "https://github.com/Vineflower/vineflower/releases/download/$VINEFLOWER_VERSION/vineflower-$VINEFLOWER_VERSION.jar"
$PROTOCOL_PACKAGE = "com/hypixel/hytale/protocol"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        default   { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-JavaInstalled {
    try {
        $null = & java -version 2>&1
        return $true
    }
    catch {
        return $false
    }
}

function Get-Vineflower {
    param([string]$DestinationPath)

    if (Test-Path $DestinationPath) {
        Write-Log "Vineflower already exists at $DestinationPath"
        return
    }

    Write-Log "Downloading Vineflower $VINEFLOWER_VERSION..."
    try {
        Invoke-WebRequest -Uri $VINEFLOWER_URL -OutFile $DestinationPath -UseBasicParsing
        Write-Log "Vineflower downloaded successfully" -Level "SUCCESS"
    }
    catch {
        throw "Failed to download Vineflower: $_"
    }
}

function Extract-ProtocolClasses {
    param(
        [string]$JarPath,
        [string]$TempPath
    )

    Write-Log "Extracting protocol classes from JAR..."

    # Create temp directory
    if (Test-Path $TempPath) {
        Remove-Item -Path $TempPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $TempPath -Force | Out-Null

    # Extract full protocol package using jar or unzip
    $extractPath = Join-Path $TempPath "extracted"
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    # Resolve JAR to absolute path
    $absoluteJarPath = (Resolve-Path $JarPath).Path

    # Use unzip to extract full protocol package
    if (Get-Command "unzip" -ErrorAction SilentlyContinue) {
        & unzip -q $absoluteJarPath "$PROTOCOL_PACKAGE/*" -d $extractPath
    }
    else {
        # Fallback: extract all with Expand-Archive and keep only protocol
        $tempExtract = Join-Path $TempPath "full-extract"
        Expand-Archive -Path $absoluteJarPath -DestinationPath $tempExtract -Force

        $sourceProtocol = Join-Path $tempExtract $PROTOCOL_PACKAGE
        $destProtocol = Join-Path $extractPath $PROTOCOL_PACKAGE

        if (Test-Path $sourceProtocol) {
            $parentDir = Split-Path $destProtocol -Parent
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            Copy-Item -Path $sourceProtocol -Destination $destProtocol -Recurse -Force
        }

        # Cleanup full extract
        Remove-Item -Path $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }

    $protocolPath = Join-Path $extractPath $PROTOCOL_PACKAGE
    if (-not (Test-Path $protocolPath)) {
        throw "Protocol classes not found in JAR at path: $PROTOCOL_PACKAGE"
    }

    # Count extracted classes
    $classCount = (Get-ChildItem -Path $protocolPath -Filter "*.class" -Recurse).Count
    Write-Log "Extracted $classCount class files" -Level "SUCCESS"

    return $extractPath
}

function New-ProtocolJar {
    param(
        [string]$ExtractedPath,
        [string]$OutputJar
    )

    Write-Log "Creating temporary JAR with protocol classes..."

    # Use Compress-Archive (cross-platform, no file locking issues)
    $comPath = Join-Path $ExtractedPath "com"

    # Create as .zip first, then rename to .jar
    $tempZip = [System.IO.Path]::ChangeExtension($OutputJar, ".zip")

    if (Test-Path $tempZip) {
        Remove-Item $tempZip -Force
    }
    if (Test-Path $OutputJar) {
        Remove-Item $OutputJar -Force
    }

    Compress-Archive -Path $comPath -DestinationPath $tempZip -Force
    Rename-Item -Path $tempZip -NewName (Split-Path $OutputJar -Leaf) -Force

    Write-Log "Protocol JAR created: $OutputJar" -Level "SUCCESS"
}

function Invoke-Decompiler {
    param(
        [string]$VineflowerPath,
        [string]$InputPath,
        [string]$OutputPath
    )

    Write-Log "Decompiling classes with Vineflower..."

    # Vineflower options for best output
    $vineflowerArgs = @(
        "-jar", $VineflowerPath,
        "-dgs=1",      # Decompile generic signatures
        "-rsy=1",      # Remove synthetic members
        "-rbr=1",      # Remove bridge methods
        "-lit=1",      # Output numeric literals as-is
        "-asc=0",      # Keep Unicode characters as-is (don't escape to ASCII)
        $InputPath,
        $OutputPath
    )

    $process = Start-Process -FilePath "java" -ArgumentList $vineflowerArgs -Wait -NoNewWindow -PassThru

    if ($process.ExitCode -ne 0) {
        throw "Decompilation failed with exit code: $($process.ExitCode)"
    }

    Write-Log "Decompilation completed successfully" -Level "SUCCESS"
}

function Copy-DecompiledSources {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    Write-Log "Organizing decompiled sources..."

    # Clear destination
    if (Test-Path $DestinationPath) {
        Remove-Item -Path $DestinationPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null

    # Find the decompiled protocol directory
    $decompiledProtocol = Join-Path $SourcePath $PROTOCOL_PACKAGE

    if (-not (Test-Path $decompiledProtocol)) {
        # Vineflower might output differently, search for it
        $decompiledProtocol = Get-ChildItem -Path $SourcePath -Directory -Recurse |
            Where-Object { $_.FullName -like "*$($PROTOCOL_PACKAGE.Replace('/', '\'))*" } |
            Select-Object -First 1 -ExpandProperty FullName
    }

    if (-not $decompiledProtocol -or -not (Test-Path $decompiledProtocol)) {
        throw "Could not find decompiled protocol sources"
    }

    # Copy each subdirectory (packets, entities, etc.) to destination
    Get-ChildItem -Path $decompiledProtocol -Directory | ForEach-Object {
        $destSubDir = Join-Path $DestinationPath $_.Name
        Copy-Item -Path $_.FullName -Destination $destSubDir -Recurse -Force
        $fileCount = (Get-ChildItem -Path $destSubDir -Filter "*.java" -Recurse).Count
        Write-Log "  - $($_.Name): $fileCount files"
    }

    # Copy any root-level protocol files
    Get-ChildItem -Path $decompiledProtocol -File -Filter "*.java" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $DestinationPath -Force
    }

    $totalFiles = (Get-ChildItem -Path $DestinationPath -Filter "*.java" -Recurse).Count
    Write-Log "Organized $totalFiles Java source files" -Level "SUCCESS"
}

function Main {
    Write-Log "=== Hytale Protocol Extractor ===" -Level "INFO"
    Write-Log "JAR Path: $JarPath"
    Write-Log "Output Path: $OutputPath"

    # Validate inputs
    if (-not (Test-Path $JarPath)) {
        throw "JAR file not found: $JarPath"
    }

    # Resolve to absolute paths
    $JarPath = Resolve-Path $JarPath
    $OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    $VineflowerPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($VineflowerPath)

    # Check Java
    if (-not (Test-JavaInstalled)) {
        throw "Java is not installed or not in PATH"
    }
    Write-Log "Java found" -Level "SUCCESS"

    # Get Vineflower
    Get-Vineflower -DestinationPath $VineflowerPath

    # Create temp directory (cross-platform compatible)
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "hytale-protocol-$([System.Guid]::NewGuid().ToString('N').Substring(0, 8))"
    $tempJar = Join-Path $tempDir "protocol.jar"
    $tempDecompiled = Join-Path $tempDir "decompiled"

    try {
        # Extract protocol classes
        $extractedPath = Extract-ProtocolClasses -JarPath $JarPath -TempPath $tempDir

        # Create JAR with protocol classes
        New-ProtocolJar -ExtractedPath $extractedPath -OutputJar $tempJar

        # Decompile
        New-Item -ItemType Directory -Path $tempDecompiled -Force | Out-Null
        Invoke-Decompiler -VineflowerPath $VineflowerPath -InputPath $tempJar -OutputPath $tempDecompiled

        # Organize output
        Copy-DecompiledSources -SourcePath $tempDecompiled -DestinationPath $OutputPath

        Write-Log "=== Extraction Complete ===" -Level "SUCCESS"
        Write-Log "Decompiled sources available at: $OutputPath"
    }
    finally {
        # Cleanup temp directory
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Run main
Main
