function Send-ADTDeferredEmails {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Switch]$DoNotExportOnFail
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $adtSession = Get-ADTSession
        $adtConfig = Get-ADTConfig
    } process {
        try {
            try {
                if (-not $adtSession.DeferredEmails.Count) {
                    return
                }

                Write-ADTLogEntry -Message "Sending [$($adtSession.DeferredEmails.Count)] deferred email(s)."

                [Hashtable]$emailsToSend = $adtSession.DeferredEmails
                foreach ($deferredEmail in $emailsToSend) {
                    try {
                        Send-ADTEmail @deferredEmail
                        $adtSession.DeferredEmails.Remove($deferredEmail)
                    } catch {
                        Write-ADTLogEntry -Message "Failed to send defered email: `r`n$(Resolve-ADTErrorRecord -ErrorRecord $_)"
                    }
                }

                if (-not $adtSession.DeferredEmails.Count) {
                    return
                }

                if (-not $adtConfig.Email.ExportOnFailureToSend) {
                    Write-ADTLogEntry -Message "Failed to send [$($adtSession.DeferredEmails.Count)] emails." -Severity Error
                    return
                }

                Write-ADTLogEntry -Message "Failed to send [$($adtSession.DeferredEmails.Count)] email(s). Exporting emails to [$($adtConfig.Email.ExportPath)]" -Severity Error

                foreach ($email in $adtSession.DeferredEmails) {
                    Export-ADTEmail @email
                }
            } catch {
                Write-Error -ErrorRecord $_
            }
        } catch {
            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
        }
    } end {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}
