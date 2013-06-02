# snapback.ps1
# Easy backups with Drive Snapshot (www.drivesnapshot.de)
#
# Author: Karsten Violka kav@violka-it.de
# Version: 0.01
#
# IDEA: Clean old backups
# IDEA: SFTP, Amazon S3

# ---------- <Configuration>
$snapshotExe = "c:\tools\snapshot.exe"    # path to snapshot.exe
$snapshotOptions = "-R -W --forcevss"     # commandline options to use
$maxDiffSize = 1024 * 1024 * 512          # new full image when diff gets bigger
#$encryption passphrase

$sourceDrives = @("C:", "D:")
$destinationRoot = "\\10.3.1.10\backup"     # no trailing \
$user = "user"
$pass = "pass"
$encryptionPassphrase = "sesam"
$destinationFolderBase = "vse-h-ts01-neu"

$stdOutLog = "$Env:temp\snapback_stdout.log"
# ---------- </Configuration>

# ---------- <Helper functions>
function mapUncPath($path, $user, $pass) {
  $net = new-object -ComObject WScript.Network
  # to be shure remove mapping.
  RemoveUncPath $path, $user, $pass
  
  try {
    # first parameter empty means "dont use a drive letter"
    $net.MapNetworkDrive("", $destinationRoot, $false, $user, $pass)
    Write-Host "Mapped $destinationRoot"
  } catch {
    Write-Host "Mapping failed!"
  }
}

function RemoveUncPath($path, $user, $pass) {
$net = new-object -ComObject WScript.Network
  try {
    $net.RemoveNetworkDrive($destinationRoot, $true, $true);
  } catch {
    Write-Host "remove failed"
  }
}

function getRecentHashfile($path){
  # Write-Host "getRecentHashfile in $path"
  return Get-ChildItem ($path + "\*.hsh") | Sort-Object lastwritetime -descending | Select-Object -first 1  
}

function getRecentSNA($path, $lookForDif = $false){
  if ($lookForDif) {
    $pattern = "\*dif.sna"
  } else {
    $pattern = "\*ful.sna"
  }
  Write-Host "lookfor $path$pattern"
  return Get-ChildItem ("$path$pattern") | Sort-Object lastwritetime -descending | Select-Object -first 1 
}

function getSizeOfLastDiffImage($path, $hashFile) {
  $recentSNA = getRecentSNA $path $true
  $newer = $recentSNA.LastWriteTime -gt $hashFile.LastWriteTime 
  
  if ($recentSNA -and $newer) {
    $files = Get-ChildItem ($path + "\" + $recentSNA.BaseName + ".*")
    # Write-Host "last image" + $files
    return ($files | Measure-Object -property length -sum).sum
  } else {
    return 0
  }
}

function doSnapshot($hashFile = $false) {
  # Variables in filename are filled in by Drive Snapshot, the ´ is the escape sign
  $arguments = "$sourceDrive $destinationPath\`$date_`$computername_`$disk_`$type $snapshotOptions"
  if ($hashFile) {
    $arguments += " -h$hashFile" 
    Write-Host "do diffsnap"
    Write-Host "$hashFile"
  } else {
    Write-Host "do fullsnap"
  }
  Write-Host "$arguments"
  writeLog "Arguments: $arguments"
  $proc = Start-Process $snapshotExe -ArgumentList $arguments -Wait -PassThru -RedirectStandardOutput $stdOutLog
  Get-Content $stdOutLog | Out-File $logFile -Append -encoding ASCII
  if ($proc.ExitCode -ne 0) {
    writeLog "ExitCode:"
    writeLog $proc.ExitCode
    Write-Host "ExitCode:" 
    Write-Host $proc.ExitCode
  }
}

function writeLog ($line) {
  Add-Content -path $logFile -value $line
}

# ------------ </Helper functions>

# ------------ <Main script>
if ($destinationRoot.StartsWith("\\")) {
  mapUncPath $destinationRoot $user $pass
}

foreach ($sourceDrive in $sourceDrives) {
  $destinationPath = $destinationRoot + "\" + $destinationFolderBase + "-" + $sourceDrive.substring(0,1)
  $logFile = $destinationPath + "\snapback.log"
  # create destination folder
  if (!(Test-Path -path $destinationPath)) {
    New-Item $destinationPath -type directory
  }
  writeLog "------ Start: $((get-date).toString('u'))"
  $hash = getRecentHashfile $destinationPath

  if ($hash) {
    Write-Host "hash found -> $hash"
    $size = getSizeOfLastDiffImage $destinationPath $hash
    $mbytes = "{0:N2}" -f ($size / 1MB) + " MB"
    Write-Host "Size of last diff image:" $mbytes 
    if ($size -gt $maxDiffSize) {
      doSnapshot      # full image
    } else {
      doSnapshot $hash  # diff image
    }
  } else {
    Write-Host "no hashfile -> full image"
    doSnapshot
  }
  writeLog "------ Finish: $((get-date).toString('u'))"
  writeLog " "
}
# TODO: remove path
RemoveUncPath $path, $user, $pass
Write-Host "all done"

<#
http://mcpmag.com/articles/2011/12/06/best-of-both-worlds-start-process-cmdlet.aspx
http://windowsitpro.com/windows/create-your-own-powershell-functions
#>
