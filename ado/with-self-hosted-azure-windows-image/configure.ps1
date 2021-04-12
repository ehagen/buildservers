<#
.SYNOPSIS
Configure VM with Azure DevOps Agents, Choco, Pwsh, Azure Cli and Visual Studio 2019 Buildtools

.DESCRIPTION
Configures Azure Visual Studio VM with Azure DevOps Agents, Chocolately, Powershell Core, Azure Cli and Visual Studio 2019 Buildtools.
If Agent is already installed, it will be removed before installing again. Work folders will not be touched.

.PARAMETER AgentUrl
Url of the Azure Devops installation like https://dev.azure.com/mycompany

.PARAMETER AgentName
Name of Agent in Pool

.PARAMETER AgentPool
Pool name for the agent to join

.PARAMETER AgentToken
Agent token / PAT / Personal access token to install the Agent

.PARAMETER AgentServiceAccount
Account of Windows Service, Specify the Windows user name in the format: domain\userName or userName@domain.com

.PARAMETER AgentServiceAccountPwd
Windows Service Logon Password

.PARAMETER AgentCount
Number of Agent to Install, As a rule of thumb we use 1 Agent per 2 cores

.Example
./configure.ps1 -AgentUrl 'https://dev.azure.com/mycompany' -Token '<token/pat>' -AgentCount 2

#>
param
(
    [string] $AgentUrl = $(Throw "Agent Url is required."),
    [string] $AgentName = 'AdoAgent',
    [string] $AgentPool = 'Default',
    [string] $AgentToken = $(Throw "Agent Token is required."),
    [string] $AgentServiceAccount = 'NT Authority\System',
    [string] $AgentServiceAccountPwd,
    [string] $AgentCount = 1
)

$ErrorActionPreference = "SilentlyContinue"
Start-Transcript -Path /configure.log -Append

Write-Host ""
Write-Host "Environment Info:"
Write-Host "     Computer: $([system.environment]::MachineName)"
Write-Host "           Os: $([System.Environment]::OSVersion.VersionString)"
Write-Host "       WhoAmI: $([Environment]::UserName)"
Write-Host "   Powershell: $($psversiontable.PsVersion)"
Write-Host "Currentfolder: $(Get-Location)"
Write-Host ""

New-Item "c:\temp" -ItemType directory -ErrorAction Ignore | Out-Null

Write-Host "Install VS BuildTools" -ForegroundColor Cyan
(New-Object System.Net.WebClient).DownloadFile('https://aka.ms/vs/16/release/vs_buildtools.exe', 'C:\temp\vs_buildtools.exe')
$params = @(
    '--quiet',
    '--wait',
    '--norestart',
    '--nocache',
    '--installPath'
    'C:\BuildTools',
    '--add Microsoft.VisualStudio.Workload.AzureBuildTools',
    '--add Microsoft.VisualStudio.Workload.MSBuildTools',
    '--add Microsoft.VisualStudio.Workload.WebBuildTools',
    '--add Microsoft.VisualStudio.Workload.NetCoreBuildTools',
    '--add Microsoft.VisualStudio.Workload.NodeBuildTools',
    '--remove Microsoft.VisualStudio.Component.Windows10SDK.10240',
    '--remove Microsoft.VisualStudio.Component.Windows10SDK.10586',
    '--remove Microsoft.VisualStudio.Component.Windows10SDK.14393',
    '--remove Microsoft.VisualStudio.Component.Windows81SDK'
)
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;
if ($myWindowsPrincipal.IsInRole($adminRole))
{
    Write-Host "With admin priv..."
}
$p = Start-Process -Wait -PassThru -FilePath 'C:\temp\vs_buildtools.exe' -Args $params
if ($p.ExitCode -ne 0)
{
    Write-Warning "Install vs_buildtools failed with error $($p.ExitCode)"
}

Write-Host "Install Choco" -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force;
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

Write-Host "Install Pwsh" -ForegroundColor Cyan
choco install powershell-core --confirm --limit-output --timeout 216000

Write-Host "Install Azure Cli" -ForegroundColor Cyan
choco install azure-cli --confirm --limit-output --timeout 216000

Write-Host "Install Notepad PlusPlus" -ForegroundColor Cyan
choco install Install notepadplusplus --confirm --limit-output --timeout 216000

Write-Host "Downloading Azure Pipelines agent..." -ForegroundColor Cyan
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$AgentToken"))
$package = Invoke-RestMethod -Headers @{Authorization = ("Basic $base64AuthInfo") } "$AgentUrl/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
$packageUrl = $package[0].Value.downloadUrl 
Write-Host $packageUrl
if ($null -eq $packageUrl)
{
    Throw "Unable to download Agent from Azure DevOps ($AgentUrl), is your token correct and still valid!"
}
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($packageUrl, "\temp\agent.zip")

Write-Host "Installing Azure Devops Agents..." -ForegroundColor Cyan

foreach ($agentId in 1..$AgentCount)
{
    $agentRoot = "\azp$AgentId"
    $agentLocation = "\azp$AgentId"
    $AgentFullName = "$AgentName-$AgentId-$($env:computername)"

    if (Test-Path $agentLocation)
    {
        Write-Host "Removing Azure Pipelines agent $AgentFullName ..."
        Set-Location $agentLocation
        .\config.cmd remove --unattended `
            --auth PAT `
            --token $AgentToken
    }

    New-Item $agentRoot -ItemType directory -ErrorAction Ignore | Out-Null
    New-Item "$AgentRoot\agent" -ItemType directory -ErrorAction Ignore | Out-Null
    Set-Location $agentLocation
    
    Write-Host "Installing Azure Pipelines agent $AgentFullName ..."   -ForegroundColor Cyan
    Expand-Archive -Path "\temp\agent.zip" -DestinationPath $agentLocation -Force
  
    Write-Host "Configuring Azure Pipelines agent $AgentFullName ..." -ForegroundColor Cyan

    $params = @(
        "--unattended",
        "--agent", $AgentFullName,
        "--url", $AgentUrl,
        "--auth", "PAT",
        "--token", $AgentToken,
        "--pool", $AgentPool,
        "--work", "_work",
        "--runAsService",
        "--replace"
    )
    if ($AgentServiceAccount)
    {
        $params += @('--windowsLogonAccount', $AgentServiceAccount)
    }
    if ($AgentServiceAccountPwd)
    {
        $params += @('--windowsLogonPassword', $AgentServiceAccountPwd)
    }

    .\config.cmd $params

    Write-Host "Running Azure Pipelines agent $AgentFullName ..." -ForegroundColor Cyan
}

Stop-Transcript