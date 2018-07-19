# ==================================================================
# mpMiner updater
# Current client version: 0.1.0
# ==================================================================
function Unzip($zipfile, $outdir) {

    Write-Host ""
    Write-Host "Nameščam novo verzijo..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipfile)
    foreach ($entry in $archive.Entries) {
        $entryTargetFilePath = [System.IO.Path]::Combine($outdir, $entry.FullName)
        $entryDir = [System.IO.Path]::GetDirectoryName($entryTargetFilePath)
        
        #Ensure the directory of the archive entry exists
        if (!(Test-Path $entryDir )) {
            New-Item -ItemType Directory -Path $entryDir | Out-Null 
        }
        
        #If the entry is not a directory entry, then extract entry
        if (!$entryTargetFilePath.EndsWith("\") -and !$entryTargetFilePath.EndsWith("/")) {
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $entryTargetFilePath, $true);
        }
    }
    Write-Host "Nova verzija nameščena."
    Write-Host ""
}

function DeleteOldFiles() {
    Write-Host ""
    Write-Host "Brišem staro verzijo..."

    if ([System.IO.File]::Exists("$PSScriptRoot\mpMiner.exe")) {
        Remove-Item "$PSScriptRoot\mpMiner.exe" -Force
    }
    if ([System.IO.File]::Exists("$PSScriptRoot\appsettings.json")) {
        Remove-Item "$PSScriptRoot\appsettings.json" -Force
    }
    if ([System.IO.File]::Exists("$PSScriptRoot\mpMiner.exe.config")) {
        Remove-Item "$PSScriptRoot\mpMiner.exe.config" -Force
    }
    if ([System.IO.Directory]::Exists("$PSScriptRoot\lib")) {
        Remove-Item "$PSScriptRoot\lib" -Force -Recurse
    }
    Write-Host "Stara verzija odstranjena."
    Write-Host ""
}
# ==================================================================
# Updater
# ==================================================================

# Get data from API endpoint

Write-Host ""
Write-Host "Posodabjam mpMiner...."
Start-Sleep -s 3
#Write-Host "Fetching update data from API..."
$url = "http://mpminer.com/api/desktop/getVersion"
$apiResponse = Invoke-RestMethod -Method Get -Uri $url

#Write-Host "Response: ${apiResponse.payload}"
$url = $apiResponse.payload.downloadUrl
$version = $apiResponse.payload.semver
Write-Host "Zadnja verzija: ${version}; URL: ${url}"

# DOWNLOAD NEW VERSION
Write-Host "[${version}] Prenašam mpMiner..."
$zipFile = "$PSScriptRoot\mpMiner.zip"
$unzipFolder = "$PSScriptRoot"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $zipFile
Write-Host "Prenos končan."

# Delete old files
Start-Sleep -s 2
DeleteOldFiles

# Unzip new version
Start-Sleep -s 2
Unzip $zipFile $unzipFolder

# Start mpMiner.exe with /update argument
Start-Sleep -s 2
$exeFile = "$PSScriptRoot\mpMiner.exe"
Start-Process $exeFile "/update"
