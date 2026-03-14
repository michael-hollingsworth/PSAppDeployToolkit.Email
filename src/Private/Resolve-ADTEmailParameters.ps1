function Resolve-ADTEmailParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [System.Management.Automation.PSCmdlet]$Cmdlet
    )

    begin {
        $adtSession = Initialize-ADTModuleIfUnitialized -Cmdlet $PSCmdlet -PassThruActiveSession
        $adtConfig = Get-ADTConfig
    } process {
        if ($adtConfig.ContainsKey('Email') -and $adtConfig.Email.ContainsKey('Defaults')) {
            foreach ($property in $adtConfig.Email.Defaults.Keys) {
                if (-not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($property)) {
                    $Cmdlet.MyInvocation.BoundParameters.Add($property, $adtConfig.Email.Defaults.$property)
                }
            }
        }

        if ((-not $Cmdlet.MyInvocation.BoundParameters.ContainsKey('SmtpServer')) -and (-not [String]::IsNullOrWhiteSpace($PSEmailServer))) {
            $Cmdlet.MyInvocation.BoundParameters.Add('SmtpServer', $PSEmailServer)
        }

        [System.Collections.Generic.List[String]]$attachments = [System.Collections.Generic.List[String]]::new()

        if ($Cmdlet.MyInvocation.BoundParameters.ContainsKey('Attachment')) {
            $attachments.AddRange($Cmdlet.MyInvocation.BoundParameters.Attachment)
        }

        if ($Cmdlet.MyInvocation.BoundParameters['IncludeLogs'] -and $adtSession) {
            if ((-not [String]::IsNullOrWhiteSpace($adtSession.LogPath)) -and (-not [String]::IsNullOrWhiteSpace($adtSession.LogName)) -and ($logPath = Join-Path -Path $adtSession.LogPath -ChildPath $adtSession.LogName)) {
                $attachments.Add($logPath)
            }

            foreach ($path in $adtSession.AdditionalLogFiles) {
                if (-not [String]::IsNullOrWhiteSpace($path)) {
                    $attachments.Add($path)
                }
            }
        }

        # Only include attachments that exist
        [String[]]$attachmentsToSend = foreach ($path in $attachments) {
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                $path
            }
        }

        # If none of the attachment paths provided are valid, remove the parameter.
        if (-not $attachmentsToSend.Count) {
            if ($Cmdlet.MyInvocation.BoundParameters.ContainsKey('Attachment')) {
                $Cmdlet.MyInvocation.BoundParameters.Remove('Attachment')
            }

            return
        }

        # Don't include duplicate attachments
        $Cmdlet.MyInvocation.BoundParameters['Attachment'] = $attachmentsToSend | Select-Object -Unique
    }
}