function Send-Email {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.From')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress]$From,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.To')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$To,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Cc')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$Cc,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Bcc')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$Bcc,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Subject,
        [Parameter()]
        [Alias('Message')]
        [String]$Body,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]$Attachment,
        [Parameter()]
        [Switch]$IncludeLogs,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Priority')]
        [System.Net.Mail.MailPriority]$Priority,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SmtpServer,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.SmtpClient.Port')]
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]$Port = 25,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.SmtpClient.UseDefaultCredentials')]
        [Switch]$UseDefaultCredentials,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.SmtpClient.EnableSsl')]
        [Alias('UseSsl')]
        [Switch]$EnableSsl,
        [Switch]$Defer
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $adtConfig = Get-ADTConfig
    } process {
        try {
            try {
                if ($Defer) {
                    if (-not (Test-ADTSessionActive)) {
                        #TODO:
                        $naerParams = @{
                            Exception = [System.InvalidOperationException]::new("An ADT Session must be active to defer emails.")
                            Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                            ErrorId = 'AdtSessionRequiredToDeferEmail'
                        }
                        throw (New-ADTErrorRecord @naerParams)
                    }

                    [Hashtable]$boundParams = $PSBoundParameters
                    $boundParams.Remove('Defer')
                    [System.Text.StringBuilder]$logMessage = [System.Text.StringBuilder]::new('Deferring email with properties:')
                    foreach ($property in @('From', 'To', 'Bcc', 'Cc', 'Subject', 'Body', 'Attachments')) {
                        if ($boundParams.ContainsKey($property)) {
                            $null = $logMessage.Append(" `r`n${property}: $($boundParams[$property] -join ';')")
                        }
                    }

                    Write-ADTLogEntry -Message $logMessage.ToString()
                    (Get-ADTSession).DeferredEmails.Add($boundParams)
                    return
                }

                [Hashtable]$emailProperties = Get-ADTEmailParameters @PSBoundParameters

                $logMessage = [System.Text.StringBuilder]::new("Attempting to send email with properties: `r`nFrom: $($emailProperties.From) `r`nTo: $($emailPropeties.To -join ';')")
                foreach ($property in @('Bcc', 'Cc', 'Subject', 'Body', 'Attachments')) {
                    if ($boundParams.ContainsKey($property)) {
                        $null = $logMessage.Append(" `r`n${property}: $($boundParams[$property] -join ';')")
                    }
                }

                Write-ADTLogEntry -Message $logMessage.ToString()

                [Hashtable]$smtpClientProperties = $emailProperties.SmtpClient
                $emailProperties.Remove('SmtpClient')

                try {
                    $message = [System.Net.Mail.MailMessage]::new($emailProperties.From, $emailProperties.To)
                    $emailProperties.Remove('From')
                    $emailProperties.Remove('To')

                    # Properties that can only be modified using the Add() method
                    foreach ($property in @('Attachments', 'Bcc', 'Cc')) {
                        if ($emailProperties.ContainsKey($property)) {
                            foreach ($value in $emailProperties[$property]) {
                                $message.$property.Add($value)
                            }

                            $emailProperties.Remove($property)
                        }
                    }

                    # All remaining properties
                    foreach ($property in $emailProperties.Keys) {
                        $message.$property = $emailProperties[$property]
                    }

                    try {
                        [System.Net.Mail.SmtpClient]$smtpClient = [System.Net.Mail.SmtpClient]::new($smtpClientProperties['SmtpServer'], $smtpClientProperties['Port'])
                        $smtpClientProperties.Remove('SmtpServer')
                        $smtpClientProperties.Remove('Port')

                        foreach ($property in $smtpClientProperties.Keys) {
                            $smtpClient.$property = $smtpClientProperties[$property]
                        }

                        $smtpClient.Send($message)
                    } finally {
                        $smtpClient.Dispose()
                    }
                } finally {
                    $message.Attachments.Dispose()
                    $message.Dispose()
                }
            } catch {
                if ($adtConfig.Email.DeferOnFailureToSend) {
                    if ($adtSession.InstallPhase -ne 'Finalization') {
                        $adtSession.DeferredEmails.Add($PSBoundParameters)
                    }
                } elseif ($adtConfig.Email.ExportOnFailureToSend) {
                    Export-ADTEmail @PSBoundParameters
                }

                Write-Error -ErrorRecord $_
            }
        } catch {
            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
        }
    } end {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}