function Resolve-ADTEmailParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.Management.Automation.PSCmdlet]$Cmdlet
    )

    begin {
        $adtConfig = if (Test-ADTModuleInitialized) { Get-ADTConfig }
        $adtSession = if (Test-ADTSessionActive) { Get-ADTSession }
    } process {
        if ($adtConfig -and $adtConfig.ContainsKey('Email') -and $adtConfig.Email.ContainsKey('Defaults')) {
            Export-ADTEnvironmentTableToSessionState -SessionState $PSCmdlet.SessionState

            # Don't auto-populate the CC and BCC values if -To is specified
            $configProperties = $adtConfig.Email.Defaults.Keys
            if ($Cmdlet.MyInvocation.BoundParameters.ContainsKey('To')) {
                $configProperties = $configProperties | & { process { if ($_ -notin @('To', 'CC', 'BCC')) { return $_ } } }
            }

            foreach ($property in $configProperties) {
                if (-not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($property)) {
                    # Expand config strings using the current ADT Session's properties.
                    ## This is primarily used to dynamically set the From property based on the script name/application being deployed.
                    $Cmdlet.MyInvocation.BoundParameters.Add($property, $PSCmdlet.SessionState.InvokeCommand.ExpandString($adtConfig.Email.Defaults.$property))
                }
            }
        }

        if ((-not $Cmdlet.MyInvocation.BoundParameters.ContainsKey('SmtpServer')) -and (-not [String]::IsNullOrWhiteSpace($PSEmailServer))) {
            $Cmdlet.MyInvocation.BoundParameters.Add('SmtpServer', $PSEmailServer)
        }

        [System.Collections.Generic.List[String]]$attachments = [System.Collections.Generic.List[String]]::new()

        if ($Cmdlet.MyInvocation.BoundParameters.ContainsKey('Attachments')) {
            $attachments.AddRange($Cmdlet.MyInvocation.BoundParameters.Attachments)
            $Cmdlet.MyInvocation.BoundParameters.Remove('Attachments')
        }

        if ($Cmdlet.MyInvocation.BoundParameters['IncludeLogs'] -and $adtSession) {
            if ((-not [String]::IsNullOrWhiteSpace($adtSession.LogPath)) -and (-not [String]::IsNullOrWhiteSpace($adtSession.LogName)) -and ($logPath = Join-Path -Path $adtSession.LogPath -ChildPath $adtSession.LogName) -and (Test-Path -LiteralPath $logPath -PathType Leaf)) {
                $attachments.Add($logPath)
            }

            foreach ($path in $adtSession.AdditionalLogFiles) {
                if ((-not [String]::IsNullOrWhiteSpace($path)) -and (Test-Path -LiteralPath $path -PathType Leaf)) {
                    $attachments.Add($path)
                }
            }
        }

        if (-not $attachments.Count) {
            # Don't include duplicate attachments
            $Cmdlet.MyInvocation.BoundParameters.Add('Attachments', ($attachments | Select-ADTUniqueObject))
        }
    }
}
