param(

    [Parameter(Mandatory, HelpMessage="version of jenkins")]
    [string]$Version,

    [Parameter(Mandatory, HelpMessage="path to save plugins")]
    [string]$Path,

    [Parameter(Mandatory, HelpMessage="remove danger plugins")]
    [string]$Secure
)

$plugins_list = @()

$dependecies_plugins= New-Object System.Collections.Generic.HashSet[object];

$vulnerability_plugins= New-Object System.Collections.Generic.HashSet[object];

$data = Invoke-WebRequest -Uri "https://updates.jenkins.io/update-center.actual.json?version=$version" | ConvertFrom-Json


function get_vulnerability_plugins {
    foreach ($plugin in $data.warnings) {
        if($plugin.type -eq "plugin") {
            #$unsecure += $plugin.name
            [void]$Script:vulnerability_plugins.Add($plugin.name)
        }
    }
}

function get_plugins {
    foreach ($key in $data.plugins.PSObject.Properties.Name) {
        $plugin = $data.plugins."$key"

        $script:plugins_list += [PSCustomObject]@{  name = $plugin.name; version = $plugin.version }

        [void]$Script:dependecies_plugins.Add($plugin.dependencies)
    }
}

function remove_dependency_from_vulnerability_plugins {
    foreach ($item in $script:dependecies_plugins) {
        if($item.optional) {
            [void]$script:vulnerability_plugins.Remove($item.name)
        }
    }
}

function download_plugins {

    New-Item -Path "$Path\plugins-$script:Version\" -ItemType Directory

    foreach ($plugin in $script:plugins_list) {
        Invoke-WebRequest -Uri "https://updates.jenkins-ci.org/download/plugins/$($plugin.name)/$($plugin.version)/$($plugin.name).hpi" -OutFile "$Path\plugins-$script:Version\$($plugin.name).hpi"
    }
}

get_plugins

if($Secure -eq 'True'  -or $Secure -eq 'true'){
    get_vulnerability_plugins

    remove_dependency_from_vulnerability_plugins
}

$plugins_list = $plugins_list | Where-Object { -not $vulnerability_plugins.Contains($_.name) }

download_plugins
