param(

    [Parameter(Mandatory, HelpMessage="version of jenkins")]
    [string]$Version,

    [Parameter(Mandatory, HelpMessage="path to save plugins")]
    [string]$Path,

    [Parameter(Mandatory, HelpMessage="remove danger plugins")]
    [string]$Secure
)

class Plugin
{
    # Optionally, add attributes to prevent invalid values
    [ValidateNotNullOrEmpty()][string]$Name
    [string]$Version

    Plugin([string]$Name, [string]$Version) {
        $this.Name = $Name
        $this.Version = $Version
    }

    [void] DisplayInfo() {
        Write-Host "Name: $($this.Name), Version: $($this.Version)"
    }
}

function Get-Plugins {
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [object] $data
    )

    $plugins_list= @();

    foreach ($plugin in $data.PSObject.Properties.value) {

        $plugins_list += [Plugin]::new($plugin.name,$plugin.version)
    } 
    
    return $plugins_list;
}

function Get-VulnerablePlugins {

    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [object[]] $data
    )

    $plugins_list= @();

    foreach ($plugin in $data) {
        if($plugin.type -eq "plugin") {

            $plugins_list += [Plugin]::new($plugin.name,$plugin.versions[0].lastVersion)
        }
    }

    return $plugins_list;
}

function Remove-VulnerablePlugins {

    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [Plugin[]] $plugins,
        [Parameter(Mandatory=$true, Position=1)]
        [Plugin[]] $vulnerablePlugins
    )

    return $plugins_list = $plugins_list | Where-Object {
        $plugin = $_
        -not ($vulnerablePlugins | Where-Object { $_.Name -eq $plugin.Name -and $_.Version -eq $plugin.Version })
     }
}

function DownloadPlugins {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [Plugin[]] $plugins_list
    )

    $pathDirectory= "$Path\plugins-$Version"

    if (-not (Test-Path $pathDirectory)) {
        New-Item -Path $pathDirectory -ItemType Directory
    }

    foreach ($plugin in $plugins_list) {

        if (Test-Path $pathDirectory\$($plugin.name).hpi) {

            $plugin_url = "https://updates.jenkins-ci.org/download/plugins/$($plugin.name)/$($plugin.version)/$($plugin.name).hpi"

            Invoke-WebRequest -Uri $plugin_url -OutFile "$pathDirectory\$($plugin.name).hpi"

        }
    }
}


function main {

    $jenkins_data = Invoke-WebRequest -Uri "https://updates.jenkins.io/update-center.actual.json?version=$version" | ConvertFrom-Json

    $plugins_list = Get-Plugins($jenkins_data.plugins)

    if($Secure.ToLower() -eq 'true'){

        $vulnerable_plugins = Get-VulnerablePlugins($jenkins_data.warnings)

        $plugins_list = Remove-VulnerablePlugins($plugins_list, $vulnerable_plugins)
    }

    DownloadPlugins($plugins_list)
}

main
