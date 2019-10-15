Function Get-RandomPort
{
    return Get-Random -Max 32767 -Min 10001;
}

Function Test-PortInUse
{
    Param(
        [Parameter(Mandatory=$true)]
        [Int] $portToTest
    );
    $count = netstat -aon | find `":$portToTest `" /c;
    return [bool]($count -gt 0);
}

Function Get-RandomUsablePort
{
    Param(
        [Int] $maxTries = 100
    );
    $result = -1;
    $tries = 0;
    DO
    {
        $randomPort = Get-RandomPort;
        if (-Not (Test-PortInUse($randomPort)))
        {
            $result = $randomPort;
        }
        $tries += 1;
    } While (($result -lt 0) -and ($tries -lt $maxTries));
    return $result;
}

function CUST_CreateAppPool ([string]$versionNumber,[string]$appName,[string]$userName,[string]$pass) {
    Write-Host "Begin Application Pool Setup" -ForegroundColor DarkCyan
    $sanitizeVersion = $versionNumber.Replace('.','_')
    $poolName = "$appName-$sanitizeVersion"
    $poolExists = Test-Path "IIS:\AppPools\$poolName"
    Write-Host "    App pool already exists: $poolExists" -ForegroundColor Green
    if ($poolExists){
        Remove-WebAppPool -Name "$poolName"
        Write-Host "    Removing: $poolName" -ForegroundColor Green
    }
    New-WebAppPool -Name "$poolName" |Out-Null
    Write-Host "    Setting login account: $userName" -ForegroundColor Green
    Set-ItemProperty "IIS:\AppPools\$poolName" -Name processModel -Value @{userName="$userName";password="$pass";identitytype=3}
    if ($netCoreWeb){
        Write-Host "    Enabling .netCore hosting: $poolName" -ForegroundColor Green
        Set-ItemProperty "IIS:\AppPools\$poolName" -Name managedRuntimeVersion  -Value ""
    }    
    Write-Host "Application Pool Setup Complete" -ForegroundColor DarkCyan
    Write-Output "$poolName";
}
function CUST_unzipSite([string]$webDir){
    Write-Host "    Unzipping website" -ForegroundColor Green
    $sitePackage = (Get-ChildItem "*website.7z" |Select-Object -First 1)    
    Write-Host "    Found Site Package: $($sitePackage.FullName)"
    Copy-Item "$($sitePackage.FullName)" "$webDir"
    $7zip = "C:\Program Files\7-Zip\7z.exe"
    & "$7zip" "x" "$webDir/$($sitePackage.Name)" "-o$webDir" |Out-Null
    Write-Host "    Unzipped to: $webDir" -ForegroundColor Green
}

function CUST_CreateWebsite([string]$appPoolName,
    [string]$appName,
    [boolean]$windowsAuth,
    [boolean]$anonymousAuth){
    $siteExists = Test-Path "IIS:\Sites\$appPoolName"
    Write-Host "Begin Website Setup" -ForegroundColor DarkCyan
    if ($siteExists){
        Write-Host "    Remove Site: $appPoolName" -ForegroundColor Green
        Remove-Website "$appPoolName" |Out-Null
    }
    $webDir = "D:\Apps\$appName\$appPoolName\Site"
    $dirExists = Test-Path "$webDir"
    if ($dirExists){
        Write-Host "    Remove Directory: $webDir" -ForegroundColor Green
        Remove-Item "$webDir" -Recurse |Out-Null
    }
    mkdir -Path "$webdir" -Force |Out-Null
    CUST_unzipSite -webDir "$webdir"
    New-Website -Name "$appPoolName" -ApplicationPool "$appPoolName" -PhysicalPath "$webdir" |Out-Null
    New-WebBinding -Name "$appPoolName" -IPAddress "*" -HostHeader "$appPoolName.ccbtesting.test"|Out-Null
    $port = Get-RandomUsablePort
    New-WebBinding -Name "$appPoolName" -IPAddress "*" -Port $port|Out-Null
    if ($windowsAuth){
        Write-Host "    Enabling windows auth" -ForegroundColor Green
        Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name Enabled -Value True -Location "$appPoolName"|Out-Null
    }
    if (-not $anonymousAuth){
        Write-Host "    Disabling anonymous auth" -ForegroundColor Green
        Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name Enabled -Value False -Location "$appPoolName"|Out-Null
    }
    Write-Host "Website Setup Complete" -ForegroundColor DarkCyan
    Write-Output $port
}

function CleanUpWebsite([string]$siteName, [string]$appName) {    
    Write-Host "Cleaning up deployed website" -ForegroundColor DarkCyan
    Write-Host "    Stop Website: $siteName" -ForegroundColor Green
    Stop-Website -Name "$siteName"
    Write-Host "    Remove Website: $siteName" -ForegroundColor Green
    Remove-Website -Name "$siteName"
    Write-Host "    Stop AppPool: $siteName" -ForegroundColor Green
    Stop-WebAppPool -Name "$siteName"
    Write-Host "    Remove AppPool: $siteName" -ForegroundColor Green
    Remove-WebAppPool -Name "$siteName"
    Write-Host "    Remove Directory: $siteName" -ForegroundColor Green
    Write-Host "    Waiting for use to stop: $siteName" -ForegroundColor Green
    Start-Sleep -Seconds 2
    Remove-Item "D:\Apps\$appName\$siteName\Site" -Force -Recurse
    Write-Host "Website Cleaned up" -ForegroundColor DarkCyan
}

function CUST_CreateWinService([string]$uniqueAppName,[string]$appName){    
    $svcDir = "D:\Apps\$appName\$uniqueAppName\Service"
    $dirExists = Test-Path "$svcDir"
    if ($dirExists){
        Write-Host "    Remove Directory: $svcDir" -ForegroundColor Green
        Remove-Item "$svcDir" -Recurse |Out-Null
    }
    Write-Host "    Create Directory: $svcDir" -ForegroundColor Green
    mkdir -Path "$svcDir" -Force |Out-Null
    New-Service -Name "$uniqueAppName" -BinaryPathName "$svcDir"
}

function CleanUpService([string]$uniqueAppName,[string]$appName){
    Write-Host "Cleaning up Win Service" -ForegroundColor DarkCyan
    $svc = Get-Service -Name "$uniqueAppName"
    Stop-Service -Name "$uniqueAppName"
    $svc.WaitForStatus("Stopped",5)    
    sc.exe delete "$uniqueAppName" |Out-Null
    Write-Host "Win Service Cleaned Up" -ForegroundColor DarkCyan
}