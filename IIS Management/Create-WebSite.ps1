<#
.Synopsis
   Create-Website - Automatic website creation.
.DESCRIPTION
    Create-Website - Automatic website creation Allow to create a website, folder and its ApplicationPool.
.PARAMETER -SiteName
    Defines the display name (in IIS Manager) of the website
    Mandatory parameter. 
.PARAMETER Port
    Defines the listening port for the website
    Default is "80". 
.PARAMETER -HostName
    Defines the first URL that the website is authorized to respond
    Mandatory parameter. 
.PARAMETER -Identity
    Defines the identity type to be used for the ApplicationPool
    Possible values are "0" (LocalSystem), "1" (LocalService), "2" (NetworkService), "3" (SpecificUser) or "4" (ApplicationPoolIdentity)
    Default is "4" (ApplicationPoolIdentity). 
.PARAMETER -Runtime
    Defines the Managed Runtime to be used for the ApplicationPool
    Possible values are "v1.1", "v2.0" or "v4.0"     Default is "v2.0". 
.PARAMETER -Pipeline
    Defines the Managed Pipeline Mode to be used for the ApplicationPool
    Possible values are "Classic" or "Integrated"     Default is "Integrated". 
.EXAMPLE 
    PS F:\Scripts\IIS\Create-WebSite\Create-Website.ps1 -SiteName Test
    Creates a website named 'Test', listening on the TCP80 port (default value), responding to the specified binding.
    The associated ApplicationPool 'Test' running with the identity 'NetworkService' (default value), v2.0 .NET Framework managed runtime (default value) and 'Integrated' managed pipeline mode (default value).
.NOTES
    Core function originally designed by Fabrice Zerrouki
    V1.0 - Updated by by Riccardo Toni @ Softecspa.it for IIS8 Support and PowerShell 3.0
#>



Param(
    [Parameter(Mandatory=$true, HelpMessage="You must provide a display name for the website.")]
    $SiteName,
    $Port="80",
    [ValidatePattern("([\w-]+\.)+[\w-]+(/[\w- ;,./?%&=]*)?")]
    [Parameter(Mandatory=$true, HelpMessage="You must provide a Host Name/ Binding for the site.")]
    $HostName="*",
    [ValidateSet("0", "1", "2", "3", "4")]
    $Identity="4",
    [ValidateSet("v1.1", "v2.0", "v4.0")]
    [string]$Runtime="v2.0",
    [ValidateSet("Classic", "Integrated")]
    [string]$Pipeline="Integrated"
    )
 
switch ($Identity)
    {
        0 {$FullIdentity="LocalSystem"}
        1 {$FullIdentity="LocalService"}
        2 {$FullIdentity="NetworkService"}
        3 {$FullIdentity="SpecificUser"}
        4 {$FullIdentity="ApplicationPoolIdentity"}
    }
 
Function Ask-YesOrNo
{
param([string]$title="Confirmation needed.",[string]$message="Parameters that will be used by the script are listed above.`nIf you want to modify one or more parameter, please restart the script and specify the wanted parameters.`nAny not defined parameter uses its default value.`r`nDo you want to continue with the above parameters?`n")
$choiceYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Answer Yes."
$choiceNo = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Answer No."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($choiceYes, $choiceNo)
$nresult = $host.ui.PromptForChoice($title, $message, $options, 1)
switch ($nresult)
    {
        0 {"OK, we can continue..."}
        1 {"Bye bye!" ; exit}
    }
}
 
Write-Host "`n**********************************************************" -ForegroundColor Yellow
Write-Host "*`t`tAutomatic Website Creation" -ForegroundColor Yellow
Write-Host "*" -ForegroundColor Yellow
Write-Host "*" -ForegroundColor Yellow -nonewline; Write-Host " Parameters"
Write-Host "*" -ForegroundColor Yellow -nonewline; Write-Host " Website Name (-SiteName):`t`t" -nonewline; Write-Host "$SiteName" -ForegroundColor DarkGreen
Write-Host "*" -ForegroundColor Yellow -nonewline; Write-Host " Website Port (-Port):`t`t`t" -nonewline; Write-Host "$Port" -ForegroundColor DarkGreen
Write-Host "*" -ForegroundColor Yellow -nonewline; Write-Host " Website Hostname (-Hostname):`t`t" -nonewline; Write-Host "$HostName" -ForegroundColor DarkGreen
Write-Host "*" -ForegroundColor Yellow -nonewline; Write-Host " AppPool Identity (-Identity):`t`t" -nonewline; Write-Host "$FullIdentity ($Identity)" -ForegroundColor DarkGreen
Write-Host "*" -ForegroundColor Yellow -nonewline; Write-Host " Managed Runtime (-Runtime):`t`t" -nonewline; Write-Host "v$Runtime" -ForegroundColor DarkGreen
Write-Host "*" -ForegroundColor Yellow -nonewline; Write-Host " Managed Pipeline Mode (-Pipeline):`t" -nonewline; Write-Host "$Pipeline" -ForegroundColor DarkGreen
Write-Host "*" -ForegroundColor Yellow
Write-Host "**********************************************************" -ForegroundColor Yellow
 
Ask-YesOrNo
if ($nresult -eq "$false") {exit}
 
if ($Identity -eq "3") {
$AppPoolUser=Read-Host "`nPlease provide username for the ApplicationPool identity"
$AppPoolPwd=Read-Host "Please provide the password for '$AppPoolUser' user" -AsSecureString
}
 
function Read-Choice {
    Param(
        [System.String]$Message,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]$Choices,
        [System.Int32]$DefaultChoice=1,
        [System.String]$Title=[string]::Empty
    )
    [System.Management.Automation.Host.ChoiceDescription[]]$Poss=$Choices | ForEach-Object {
        New-Object System.Management.Automation.Host.ChoiceDescription "&$($_)", "Sets $_ as an answer."
    }
    $Host.UI.PromptForChoice($Title, $Message, $Poss, $DefaultChoice)
}
 
function Select-IPAddress {
    [cmdletbinding()]
    Param(
        [System.String]$ComputerName='localhost'
    )
    $IPs=Get-WmiObject -ComputerName $ComputerName -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'" | ForEach-Object {
        $_.IPAddress
    } | Where-Object {
        $_ -match "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
    }
 
    if($IPs -is [array]){
        Write-Host "`nServer $ComputerName uses these IP addresses:"
        $IPs | ForEach-Object {$Id=0} {Write-Host "${Id}: $_" -ForegroundColor Yellow; $Id++}
        $IPs[(Read-Choice -Message "`nChoose an IP Address" -Choices (0..($Id-1)) -DefaultChoice 0)]
    }
    else{$IPs}
}
$ChosenIP=Select-IPAddress
Write-Host "`nThe selected IP address is: $ChosenIP`n" -ForegroundColor DarkGreen
 
$SiteName
# Create the website directory
Write-Host "Creating application directory" -ForegroundColor Yellow
$WWWPath = "F:\inetpub\wwwroot"
$SitePath = "$WWWPath" + "\" + "$SiteName"
if (!(Test-Path $SitePath)) {
    New-Item -ItemType Directory -Path $SitePath
}
 
# Creates the website logfiles directory
Write-Host "Creating application logfiles directory" -ForegroundColor Yellow
$LogsPath = "F:\inetpub\logs\LogFiles"
$SiteLogsPath = "$LogsPath" + "\" + "$SiteName"
if (!(Test-Path $SiteLogsPath)) {
    New-Item -ItemType Directory -Path $SiteLogsPath
}
 
Import-Module "WebAdministration" -ErrorAction Stop
if ($Pipeline -eq "Integrated") {$PipelineMode="0"} else {$PipelineMode="1"}
 
# Creates the ApplicationPool
Write-Host "Creating website application pool" -ForegroundColor Yellow
New-WebAppPool –Name $SiteName -Force
Set-ItemProperty ("IIS:\AppPools\" + $SiteName) -Name processModel.identityType -Value $Identity
if ($Identity -eq "3") {
Set-ItemProperty ("IIS:\AppPools\" + $SiteName) -Name processModel.username -Value $AppPoolUser
Set-ItemProperty ("IIS:\AppPools\" + $SiteName) -Name processModel.password -Value $AppPoolPwd
}
Set-ItemProperty ("IIS:\AppPools\" + $SiteName) -Name managedRuntimeVersion -Value $Runtime
Set-ItemProperty ("IIS:\AppPools\" + $SiteName) -Name managedPipelineMode -Value $PipelineMode
 
# Creates the website
Write-Host "Creating website" -ForegroundColor Yellow
New-Website –Name $SiteName -Port $Port –HostHeader $HostName -IPAddress $ChosenIP -PhysicalPath $SitePath -ApplicationPool $SiteName -Force
Set-ItemProperty ("IIS:\Sites\" + $SiteName) -Name logfile.directory -Value $SiteLogsPath
 
Start-WebAppPool -Name $SiteName
Start-WebSite $SiteName
 
Write-Host "Website $SiteName created!" -ForegroundColor DarkGreen