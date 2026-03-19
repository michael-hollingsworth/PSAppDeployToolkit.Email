function Resolve-ADTEmailParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.Management.Automation.PSCmdlet]$Cmdlet
    )

    begin {
        $adtSession = Initialize-ADTModuleIfUninitialized -Cmdlet $PSCmdlet -PassThruActiveSession
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
            $Cmdlet.MyInvocation.BoundParameters.Remove('Attachment')
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
        foreach ($path in $attachments) {
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                $attachments.Remove($path)
            }
        }

        # If none of the attachment paths provided are valid, remove the parameter.
        if (-not $attachments.Count) {
            return
        }

        # Don't include duplicate attachments
        $Cmdlet.MyInvocation.BoundParameters.Add('Attachment', ($attachments | Select-Object -Unique))
    }
}