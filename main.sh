#!/bin/bash

# declare -A plugins

# declare -A vulnerable_plugins

plugins

vulnerable_plugins

function get_plugins() {
    local data="$1"

    # echo "$data" | jq -c '.[]' | while read -r plugin; do
    #     version=$(echo "$plugin" | jq -r '.version')
    #     name=$(echo "$plugin" | jq -r '.name')

    #     plugins[$name]=$version

    #     echo "${plugins[@]}"
    # done

    plugins=$(echo "$data" | jq 'to_entries | map({Name: .value.name, Version: .value.version})')
}

function get_vulnerable_plugins() {
    local data="$1"

    # echo "$data" | jq -c '.[]' | while read -r plugin; do
    #     version=$(echo "$plugin" | jq -r '.versions[0].lastVersion')
    #     name=$(echo "$plugin" | jq -r '.name')

    #     vulnerable_plugins[$name]=$version

    #     echo "${vulnerable_plugins[@]}"
    # done    

    vulnerable_plugins=$(echo "$data" | jq 'to_entries | map({Name: .value.name, Version: .value.versions[0].lastVersion})')
}

function remove_vulnerable_plugins() {

    echo "$vulnerable_plugins" | jq -r '.[] | "\(.Name) \(.Version)"' | while read -r Name Version;
        do 

            plugins=$(echo "$plugins" | jq -r --arg name "$Name" --arg version "$Version" '.[] | select(.Name != $name and .Version != $version ) | .Version')

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