$plugins_list = @()

$dependecies_plugins= New-Object System.Collections.Generic.HashSet[object];

$vulnerability_plugins= New-Object System.Collections.Generic.HashSet[object];

$data = Invoke-WebRequest -Uri "https://updates.jenkins.io/update-center.actual.json?version=2.361.4" | ConvertFrom-Json


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

function remove_dependency_from_vulnerability_plugins() {
    foreach ($item in $script:dependecies_plugins) {
        if($item.optional) {
            [void]$script:vulnerability_plugins.Remove($item.name)
        }
    }
}

get_plugins

get_vulnerability_plugins

remove_dependency_from_vulnerability_plugins

$plugins_list = $plugins_list | Where-Object { -not $vulnerability_plugins.Contains($_.name) }





