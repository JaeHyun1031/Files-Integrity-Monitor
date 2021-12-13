Function Calculate-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}
Function Remove-Existing-Baseline() {
    $baselineExists = Test-Path -Path .\Baseline.txt

    if ($baselineExists) {
        Remove-Item -Path .\Baseline.txt
    }
}


Write-Host ""
Write-Host "What would you like to do?"
Write-Host ""
Write-Host "    [A] Set a new baseline"
Write-Host "    [B] Start monitoring with current baseline"
Write-Host ""
$option = Read-Host -Prompt "Please enter A or B"
$filePath = Read-Host -Prompt "Please enter the path of your folder that you want to monitor"
Write-Host ""

if ($option -eq "A".ToUpper()) {
    Write-Host "Set a new baseline"

    # Delete existing Baseline.txt
    Remove-Existing-Baseline

    # Calculate Hash of the files and save in Baseline.txt
    # Collect all files in the target folder
    $files = Get-ChildItem -Path $filePath

    # Calculate the hash, and save at Baseline.txt for each file
    foreach ($f in $files) {
        $hash = Calculate-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\Baseline.txt -Append
    }
    
}

elseif ($option -eq "B".ToUpper()) {
    Write-Host "Start monitoring with current baseline"
    Write-Host "You will be notified if there is any file creation, change, or deletion"

    $hashDict = @{}

    # Load file|hash from Baseline.txt and store them in a dictionary
    $pathsAndHashes = Get-Content -Path .\Baseline.txt
    
    foreach ($f in $pathsAndHashes) {
         $hashDict.add($f.Split("|")[0],$f.Split("|")[1])
    }

    # Start monitoring files with current baseline
    while ($true) {
        Start-Sleep -Seconds 1
        
        $files = Get-ChildItem -Path $filePath

        # Calculate the hash, and save at Baseline.txt for each file
        foreach ($f in $files) {
            $hash = Calculate-Hash $f.FullName

            # Notify the user if there is any file creation
            if ($hashDict[$hash.Path] -eq $null) {
                Write-Host "New file creation is detected: $($hash.Path)" -ForegroundColor Green
            }
            else {
                # Notify the user if there is any file change
                if ($hashDict[$hash.Path] -ne $hash.Hash) {
                    Write-Host "New file change is detected: $($hash.Path)" -ForegroundColor Yellow
                }
            }
        }

        foreach ($key in $hashDict.Keys) {
            $baselineFileExists = Test-Path -Path $key
            if (-Not $baselineFileExists) {
                # Notify the user if there is any file deletion
                Write-Host "New file deletion is detected: $($key)" -ForegroundColor Red
            }
        }
    }
}