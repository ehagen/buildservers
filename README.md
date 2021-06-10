# BuildServers

Contains samples to create BuildServers/Hosts/Nodes in Azure and On-Prem

## Sample 1: Provision a self-hosted build server for Azure DevOps with VStudio 2019 image and Azure Devops Build Agents in your own Azure Subscription

You need to supply your Azure DevOps site, Pat and agent details. After provisioning VM a configuration script is executed which creates the Azure DevOps Agent and installs Choco, Pwsh, Azure Cli, Notepad++ and Dotnet Coverage Reportgenerator. Check configure.log in root of c-drive when something fails.

Remark: The VM is configured with auto-shutdown at 19:00

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fehagen%2Fbuildservers%2Fmaster%2Fado%2Fwith-self-hosted-azure-vstudio-image%2Fazuredeploy.json" target="_blank">
    <img src="https://azuredeploy.net/deploybutton.png"/>
</a>

<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fehagen%2Fbuildservers%2Fmaster%2Fado%2Fwith-self-hosted-azure-vstudio-image%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

## Sample 2: Provision a self-hosted build server for Azure DevOps with Windows Server 2019 image and Azure Devops Build Agents in your own Azure Subscription

This Deployments uses the Visual Studio 2019 buildTools.

You need to supply your Azure DevOps site, Pat and agent details. After provisioning VM a configuration script is executed which creates the Azure DevOps Agent and installs Choco, Pwsh, Azure Cli, Notepad++, Dotnet Coverage Reportgenerator and VS Buildtools. Check configure.log in root of c-drive when something fails.

Remark: The VM is configured with auto-shutdown at 19:00

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fehagen%2Fbuildservers%2Fmaster%2Fado%2Fwith-self-hosted-azure-windows-image%2Fazuredeploy.json" target="_blank">
    <img src="https://azuredeploy.net/deploybutton.png"/>
</a>

<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fehagen%2Fbuildservers%2Fmaster%2Fado%2Fwith-self-hosted-azure-windows-image%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
