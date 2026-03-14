function Resolve-ADTEmailLogMessage {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [System.Management.Automation.PSCmdlet]$Cmdlet
    )

    [System.Text.StringBuilder]$logMessage = [System.Text.StringBuilder]::new()

    if (-not [String]::IsNullOrWhiteSpace($Cmdlet.MyInvocation.BoundParameters['From'])) {
        $null = $logMessage.Append(" `r`nFrom: $($Cmdlet.MyInvocation.BoundParameters.From)")
    }
    if (-not [String]::IsNullOrWhiteSpace($Cmdlet.MyInvocation.BoundParameters['To'])) {
        $null = $logMessage.Append(" `r`nTo: $($Cmdlet.MyInvocation.BoundParameters.To -join ';')")
    }
    if (-not [String]::IsNullOrWhiteSpace($Cmdlet.MyInvocation.BoundParameters['Cc'])) {
        $null = $logMessage.Append(" `r`nCc: $($Cmdlet.MyInvocation.BoundParameters.Cc -join ';')")
    }
    if (-not [String]::IsNullOrWhiteSpace($Cmdlet.MyInvocation.BoundParameters['Bcc'])) {
        $null = $logMessage.Append(" `r`nBcc: $($Cmdlet.MyInvocation.BoundParameters.Bcc -join ';')")
    }
    if (-not [String]::IsNullOrWhiteSpace($Cmdlet.MyInvocation.BoundParameters['Subject'])) {
        $null = $logMessage.Append(" `r`nSubject: $($Cmdlet.MyInvocation.BoundParameters.Subject)")
    }
    if (-not [String]::IsNullOrWhiteSpace($Cmdlet.MyInvocation.BoundParameters['Body'])) {
        $null = $logMessage.Append(" `r`nBody: `r`n$($Cmdlet.MyInvocation.BoundParameters.Body)")
    }
    if (-not [String]::IsNullOrWhiteSpace($Cmdlet.MyInvocation.BoundParameters['Attachments'])) {
        $null = $logMessage.Append(" `r`Attachments: $($Cmdlet.MyInvocation.BoundParameters.Attachments -join ';')")
    }

    [String]$message = $logMessage.ToString()

    if ([String]::IsNullOrWhiteSpace($message)) {
        return
    }

    return $message
}