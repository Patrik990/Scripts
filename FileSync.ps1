# Files sync path parameter with selection check #
#-------------------------------------------------
Param (
#  Source path
  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $SourcePath,

# Destination path
  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $DestinationPath,

# Log path
  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $LogPath
 )

# Path selection check / creation
if (-not (Test-Path -Path $SourcePath)) {
    Write-Host "Source folder does not exist - The folder will be created!" -f Red
    Write-Host "> Provided folder: $SourcePath" -f DarkCyan
}
if (-not (Test-Path -Path $SourcePath)) {
    New-Item -Path $SourcePath -ItemType Directory -Confirm
    Write-host "New Source Folder Created at '$SourcePath'!" -f Green
    $ErrorActionPreference = "Stop"
}
Else {
    Write-host "Source Folder '$SourcePath' already exists!" -f DarkGreen
}

if (-not (Test-Path -Path $DestinationPath)) {
    Write-Host "Destination folder does not exist - The folder will be created!!" -f Red
    Write-Host "> Provided folder: $DestinationPath" -f DarkCyan
}
if (-not (Test-Path -Path $DestinationPath)) {
    New-Item -Path $DestinationPath -ItemType Directory -Confirm
    Write-host "New Destination Folder Created at '$DestinationPath'!" -f Green
    $ErrorActionPreference = "Stop"
}
Else {
    Write-host "Destination Folder '$DestinationPath' already exists!" -f DarkGreen
}

if (-not (Test-Path -Path $LogPath)) {
    Write-Host "Log folder does not exist - The folder will be created!" -f Red
    Write-Host "> Provided folder: $LogPath" -f DarkCyan
}
if (-not (Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Confirm
    Write-host "New Log Folder Created at '$LogPath'!" -f Green
    $ErrorActionPreference = "Stop"
}
Else {
    Write-host "Log Folder '$LogPath' already exists!" -f DarkGreen
}

Write-Host "Synchronization started..." -ForegroundColor DarkYellow

# Log recording to the file #
#----------------------------
function WriteLog
{
Param ([string]$LogString)
$Stamp = (Get-Date).ToString("yyyy/MM/dd hh:mm:ss")
$LogMessage = "$Stamp $LogString"
Add-content $LogFile -value $LogMessage
}

$LogFile = Set-Location -Path $LogPath
$LogFile = "Sync_Log $((Get-Date).ToString("yyyy-MM-dd")).log"

# Sync execution #
#-----------------
while ($true){

    # Get the file in the source path
    $fileInSource = Get-ChildItem -Recurse $SourcePath -Force
    # Get the file in the destination path
    $fileInDestination = Get-ChildItem -Recurse $DestinationPath -Force

    $filesToCopy = @()  
    $filesToRemove = @()

    foreach ($file in $fileInSource){
        #Check if the file exist in the destination
        $destinationMatch = $fileInDestination | Where-Object {$_.Name -eq $file.Name}
        if ($destinationMatch) {
            # Check if the file in the source is newer than the one in the destination - copy the file to the destination
            if ($destinationMatch.LastWriteTime -ne $file.LastWriteTime) {$filesToCopy += $file}
        }
        else {$filesToCopy += $file}
    }
    foreach ($file in $fileInDestination) {
        # Check if the file does not exists in the source - remove the file from destination
        $sourceMatch = $fileInSource | Where-Object {$_.Name -eq $file.Name}
        if (-not $sourceMatch) {$filesToRemove += $file}
    }

    if ($filesToCopy) {
        for ($i = 0; $i -lt $filesToCopy.Count; $i++) {
            Copy-Item -Path $filesToCopy[$i].FullName -Destination $DestinationPath -Force
            if ($?)
            {
                Write-Host "Successfully copied $($filesToCopy[$i].FullName) to $destinatrionPath" -ForegroundColor Green
                WriteLog "Successfully copied $($filesToCopy[$i].FullName)"
            }else{
                Write-Host "Failed to copy $($filesToCopy[$i].FullName) to $destinatrionPath" -ForegroundColor Red
                WriteLog "Failed to copy $($filesToCopy[$i].FullName)"
            }
        }
    }
    
    if ($filesToRemove) {
        for ($i = 0; $i -lt $filesToRemove.Count; $i++) {
            Remove-Item -Path $filesToRemove[$i].FullName -Force
            if ($?)
            {
                Write-Host "Successfully removed $($filesToRemove[$i].FullName)" -ForegroundColor Green
                WriteLog "Successfully removed $($filesToRemove[$i].FullName)"
            }else{
                Write-Host "Failed to remove $($filesToRemove[$i].FullName)" -ForegroundColor Red
                WriteLog "Failed to remove $($filesToRemove[$i].FullName)"
            }
        }
    } 
}