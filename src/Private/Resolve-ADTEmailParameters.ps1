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
            $Cmdlet.MyInvocation.BoundParameters.Add('Attachments', ($attachments | Select-Object -Unique))
        }
    }
}