# download-jenkins-plugins
download jenkins plugins based by jenkin version and security threats

Prerequisites for bash: 
- jq

## usage
Command-line Flags
- -v [version]: Specifies the Jenkins version (default: latest).
- -p [path]: Sets the directory path where plugins will be saved (default: current directory).
- -s: Secure mode. If enabled, vulnerable plugins are removed before downloading.

example:
```
bash:
./main.sh -v 2.361.1 -p /custom/path -s

powershell:
.\main.ps1 -version 2.361.1 -path C:\JenkinsPlugins -secure true
```
