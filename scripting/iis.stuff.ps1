function CreateAppPool ([string]$appName, 
                        [pscredential]$credential, 
                        [string]$runtimeVersion,
                        [string]$pipelineMode,
                        [bool]$loadUserProfile,
                        [bool]$forceRelogin=$false) {
    Write-Host "Begin Application Pool Setup" -ForegroundColor DarkCyan    
    $iisPath = "IIS:\AppPools\$appName"
    $poolExists = Test-Path "$iisPath"
    
    if ($poolExists){
        Write-Host "    App pool already exists: [$appName]" -ForegroundColor Green
    }else{
        New-WebAppPool -Name "$appName" |Out-Null
        Write-Host "    Created App Pool: [$appName]" -ForegroundColor Yellow
    }
    
    if ($credential -ne $null){
        $currentUserName = (Get-ItemProperty "$iisPath" -Name "processModel.userName").Value
        $mustChange = $false;
        $cred =  $credential.GetNetworkCredential();
        if ($currentUserName -ne $credential.UserName){
            $mustChange = $true;
            Write-Host "    Changing login account: [$($cred.UserName)] was [$currentUserName]" -ForegroundColor Yellow
        }
        if ($forceRelogin){
            $mustChange = $true;
            Write-Host "    Relogin as  login account: [$($cred.UserName)] because forceRelogin was [$forceRelogin]" -ForegroundColor Yellow
        }
        if ($mustChange){
            
            Write-Host "    Changing login account: $($cred.UserName)" -ForegroundColor Yellow
            Set-ItemProperty "$iisPath" -Name processModel -Value @{userName="$($cred.UserName)";password="$($cred.Password)";identitytype=3}
        }else{
            Write-Host "    Account already logged in" -ForegroundColor Green
        }        
    }else{
        Write-Host "    No login information  provided, skipping" -ForegroundColor Green
    }
    $currentLoadUserProfile = (Get-ItemProperty "$iisPath" -Name "processModel.loadUserProfile").Value
    if ($currentLoadUserProfile -ne $loadUserProfile){
        Write-Host "    Changing load user profile to: [$loadUserProfile] was [$currentLoadUserProfile]" -ForegroundColor Yellow
        Set-ItemProperty "$iisPath" -Name "processModel.loadUserProfile" -Value $loadUserProfile
    }else{
        Write-Host "    load user profile already set to: [$loadUserProfile]" -ForegroundColor Green
    }

    $currentManagedPipeline = (Get-ItemProperty "$iisPath" -Name "managedPipelineMode")
    if ($currentManagedPipeline -ne $pipelineMode){
        Write-Host "    Changing managed pipeline mode to: [$pipelineMode] was [$currentManagedPipeline]" -ForegroundColor Yellow
        Set-ItemProperty "$iisPath" -Name "managedPipelineMode" -Value $pipelineMode
    }else{
        Write-Host "    managed pipeline mode already set to: [$pipelineMode]" -ForegroundColor Green
    }
    
    $currentRuntimeVersion = (Get-ItemProperty "$iisPath" -Name "managedRuntimeVersion").Value
    if ($runtimeVersion -ne $currentRuntimeVersion){
        Write-Host "    Changing runtime version to: [$runtimeVersion] was [$currentRuntimeVersion]" -ForegroundColor Yellow
        Set-ItemProperty "$iisPath" -Name managedRuntimeVersion  -Value "$runtimeVersion"
    }else{
        Write-Host "    Runtime version already set to: [$runtimeVersion]" -ForegroundColor Green
    }

    Write-Host "Application Pool Setup Complete" -ForegroundColor DarkCyan
}

function CreateWebsite([string]$appPoolName,
    [string]$appName,
    [string]$path,
    [string]$webBinding,
    [boolean]$windowsAuth,
    [boolean]$anonymousAuth){
    
    Write-Host "Begin Website Setup" -ForegroundColor DarkCyan
    if (Test-Path "$path"){
        Write-Host "    Webdir already exists: [$path]" -ForegroundColor Green        
    }else{
        Write-Host "    Webdir doesnt exist, creating: [$path]" -ForegroundColor Yellow        
        mkdir -Path "$path" -Force |Out-Null
    }
    $sitePath = "IIS:\Sites\$appName"
    $siteExists = Test-Path "$sitePath"
    if ($siteExists){
        Write-Host "    Site already exists: [$appName]" -ForegroundColor Green
    }
    else{
        Write-Host "    Creating site: [$appName]" -ForegroundColor Yellow
        New-Website -Name "$appName" -ApplicationPool "$appPoolName" -PhysicalPath "$path" |Out-Null
    }    
    
    $binding = Get-WebBinding -Name "$appName" |Where-Object {$_.bindingInformation -eq '*:80:'+$webBinding}
    if ($null -ne $binding){
        Write-Host "    Binding already exists: [$webBinding]" -ForegroundColor Green
    }else{
        Write-Host "    Creating Binding for: [$webBinding]" -ForegroundColor Yellow
        New-WebBinding -Name "$appName" -IPAddress "*" -HostHeader "$webBinding" -Port 80 -Protocol "http"
    }
    
    $currentWindowsAuth = (Get-WebConfigurationProperty -Filter  "/system.webServer/security/authentication/windowsAuthentication" -location "$sitePath" -Name Enabled).Value
    if ($windowsAuth -ne $currentWindowsAuth){
        Write-Host "    Changing Windows Auth to [$windowsAuth] was [$currentWindowsAuth]" -ForegroundColor Yellow        
        Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name Enabled -Value "$windowsAuth" -Location "$sitePath"
    }else{
        Write-Host "    Windows Auth already set:[$windowsAuth]" -ForegroundColor Green        
    }
    $currentAnonymousAuth = (Get-WebConfigurationProperty -Filter  "/system.webServer/security/authentication/anonymousAuthentication" -location "$sitePath" -Name Enabled).Value
    if ($currentAnonymousAuth -ne $anonymousAuth){
        Write-Host "    Changing Anonymous Auth to [$anonymousAuth] was [$currentAnonymousAuth]" -ForegroundColor Yellow
        Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name Enabled -Value "$anonymousAuth" -Location "$sitePath"|Out-Null
    }else{
        Write-Host "    Anonymous Auth already set: [$anonymousAuth]" -ForegroundColor Green
    }
    Write-Host "Website Setup Complete" -ForegroundColor DarkCyan
}

$u = 'iisconfig' #pass credentials from TC
$pw = ConvertTo-SecureString 'testing' -AsPlainText -Force #pass credentials from TC
$cre = New-Object System.Management.Automation.PSCredential ("$u", $pw)
CreateAppPool -appName "testing" -credential $cre -runtimeVersion "v4.0" -pipelineMode "Integrated" -loadUserProfile $true
CreateWebsite -appPoolName "testing" -appName "testsite" -path "C:\tests\testsite" -webBinding "chris.test.com" -windowsAuth $true -anonymousAuth $false