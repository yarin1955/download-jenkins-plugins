#!/bin/bash

declare -A plugins

declare -A vulnerable_plugins

#!/bin/bash

# Initialize variables
version="latest"   # Variable to store version number
path=$(pwd)     # Variable to store path
secure=0     # Boolean for secure flag

# Parse flags with getopts
while getopts "v:p:s" opt; do
  case $opt in
    v)  # Version flag, expects a value
      version="$OPTARG"
      ;;
    p)  # Path flag, expects a folder path
      path="$OPTARG"
      ;;
    s)  # Secure flag, boolean, no value
      secure=1
      ;;
    \?)  # Invalid option
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)  # Missing argument
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Shift to remove processed flags
shift $((OPTIND - 1))

# Handle version flag
if [ -n "$version" ]; then
  echo "Version provided: $version"
else
  echo "No version provided."
fi

# Handle path flag
if [ -n "$path" ]; then
  echo "Path provided: $path"
else
  echo "No path provided."
fi

# Handle secure flag
if [ $secure -eq 1 ]; then
  echo "Secure mode is ON"
else
  echo "Secure mode is OFF"
fi


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
    done <<< "$(echo "$data" | jq -r '.[] | "\(.name) \(.versions[0].lastVersion // "null")"')" 
}

function remove_vulnerable_plugins() {
    for pluginName in "${!vulnerable_plugins[@]}"; do

        if [[ "${plugins[$pluginName]}" == "${vulnerable_plugins[$pluginName]}" || "${vulnerable_plugins[$pluginName]//[[:space:]]/}" == "null" ]]; then
            unset plugins[$pluginName]
        fi
    done
}


function download_plugins() {

    if [ ! -d "plugins" ]; then
        mkdir -m 755 plugins
    fi

    for pluginName in "${!plugins[@]}"; do
        
        URL="https://updates.jenkins-ci.org/download/plugins/${pluginName}/${plugins[$pluginName]//[[:space:]]/}/${pluginName}.hpi"

        curl -L -o ${path}/plugins/${pluginName}.hpi "$URL"

        echo "Name: $pluginName, Version: ${plugins[$pluginName]//[[:space:]]/}" >> plugins_versions.text
    done  
}

function main() {

    jenkins_data=$(curl -G "https://updates.jenkins.io/update-center.actual.json?version=$version" | awk -F'"' '/href=.*>here/ {print $2}');

    jenkins_data=$(curl -G "$jenkins_data")

    local plugins_list=$(echo "$jenkins_data" | jq '.plugins')

    local vulnerablePlugins=$(echo "$jenkins_data" | jq '.warnings')  

    get_plugins "$plugins_list"

    get_vulnerable_plugins "$vulnerablePlugins"

    if [ $secure -eq 1 ]; then
        remove_vulnerable_plugins
    fi

    download_plugins
}

main 