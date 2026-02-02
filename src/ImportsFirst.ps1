$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
Set-StrictMode -Version 1.0

if (-not (Test-ADTSession)) {
    throw "This module can only be imported after an ADT Session has been initialized."
}

