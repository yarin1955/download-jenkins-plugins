#!/bin/bash

declare -A plugins

declare -A vulnerable_plugins


function get_plugins() {
    local data="$1"

    while read -r name version; do
        plugins["$name"]="$version"
    done <<< "$(echo "$data" | jq -r '.[] | "\(.name) \(.version)"')"
}

function get_vulnerable_plugins() {
    local data="$1"

    while read -r name version; do
        vulnerable_plugins["$name"]="$version"
    done <<< "$(echo "$data" | jq -r '.[] | "\(.name) \(.versions[0].lastVersion)"')" 
}

function remove_vulnerable_plugins() {

    for pluginName in "${!vulnerable_plugins[@]}"; do
        if [[ "${plugins[$pluginName]}" == "${vulnerable_plugins[$pluginName]}"  ]]; then
            unset plugins[$pluginName]
        fi
    done
}

function main() {

    jenkins_data=$(curl -G "https://updates.jenkins.io/update-center.actual.json?version=2.462.3" | awk -F'"' '/href=.*>here/ {print $2}');

    jenkins_data=$(curl -G "$jenkins_data")

    local plugins_list=$(echo "$jenkins_data" | jq '.plugins')

    local vulnerablePlugins=$(echo "$jenkins_data" | jq '.warnings')  

    get_plugins "$plugins_list"

    get_vulnerable_plugins "$vulnerablePlugins"

    remove_vulnerable_plugins
}

main 