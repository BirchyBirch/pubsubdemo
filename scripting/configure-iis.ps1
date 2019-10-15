
param([string]$versionNumber="0.0",
    [string]$appName="test",
    [string]$userName="IISTESTER",
    [string]$pass="testing",
    [boolean]$windowsAuth=$true,
    [boolean]$anonymousAuth=$false,
    [boolean]$netCoreWeb=$true
)
. 'd:\Development\docker-experiments\funcs.ps1'

Write-Host "------------------" -ForegroundColor Green
Write-Host "    Version: $versionNumber" -ForegroundColor Green
Write-Host "    Application: $appName" -ForegroundColor Green
Write-Host "    .NETCore: $netCoreWeb" -ForegroundColor Green
Write-Host "    UserName: $userName" -ForegroundColor Green
Write-Host "------------------" -ForegroundColor Green
$uniqueAppName = (CUST_CreateAppPool -versionNumber "$versionNumber" -appName "$appName" -userName "$userName" -pass "$pass")
$port = (CUST_CreateWebsite -appPoolName "$uniqueAppName" -appName "$appName" -windowsAuth $windowsAuth -anonymousAuth $anonymousAuth)
CUST_CreateWinService -uniqueAppName "$uniqueAppName" -appName "$appName"
Invoke-Pester -Script @{ Path =  'd:\Development\docker-experiments\pestertests.ps1'; Parameters = @{port = "$port"} }
CleanUpWebsite -siteName "$uniqueAppName" -appName "$appName"
CleanUpService -uniqueAppName "$uniqueAppName" -appName "$appName"