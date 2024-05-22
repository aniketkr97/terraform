# Define the list of servers and the path to the Java executable
$servers = @("Server1", "Server2", "Server3")
$javaExecutablePath = "C:\path\to\your\java\executable.jar"
$destinationPath = "C$\Program Files\YourApp"

# Define SCCM details
$sccmSiteServer = "YourSCCMServer"
$sccmSiteCode = "YourSiteCode"

# Function to copy the Java executable to the remote server
function Copy-Executable {
    param (
        [string]$server,
        [string]$sourcePath,
        [string]$destPath
    )

    $session = New-PSSession -ComputerName $server
    try {
        Copy-Item -Path $sourcePath -Destination "\\$server\$destPath" -Recurse -Force
        Write-Host "Copied executable to $server"
    } catch {
        Write-Host "Failed to copy executable to $server: $_"
    } finally {
        Remove-PSSession -Session $session
    }
}

# Function to install the Java executable using SCCM
function Install-Executable {
    param (
        [string]$server,
        [string]$executablePath
    )

    $installScript = @"
$SCCMPath = Get-WmiObject -Namespace "root\ccm" -Class SMS_Client
$exec = New-Object -ComObject wscript.shell
$exec.Run("java -jar $executablePath"), 0, $true
"@

    Invoke-Command -ComputerName $server -ScriptBlock { param($script) Invoke-Expression $script } -ArgumentList $installScript
    Write-Host "Installation command sent to $server"
}

# Loop through each server and deploy the Java executable
foreach ($server in $servers) {
    Copy-Executable -server $server -sourcePath $javaExecutablePath -destPath $destinationPath
    Install-Executable -server $server -executablePath "$destinationPath\executable.jar"
}

Write-Host "Deployment completed"
