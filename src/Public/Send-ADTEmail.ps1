function Send-Email {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.From')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress]$From,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.To')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$To,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Cc')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$Cc,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Bcc')]
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
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Priority')]
        [System.Net.Mail.MailPriority]$Priority,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'MailMessage')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailMessage]$MailMessage,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SmtpServer,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Port')]
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]$Port = 25,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.UseDefaultCredentials')]
        [Switch]$UseDefaultCredentials,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.EnableSsl')]
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
                    if (-not (Test-ADTSession)) {
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
                    Write-ADTLogEntry -Message "Deferring email with properties: $($boundParams | Out-String -Width ([Int32]::MaxValue))"
                    (Get-ADTSession).DeferredMessages.Add($boundParams)
                    return
                }

                [Hashtable]$emailProperties = Get-ADTEmailParameters @PSBoundParameters

                $logMessage = [System.Text.StringBuilder]::new("Attempting to send email with properties: `r`nFrom: $($emailProperties.From) `r`nTo: $($emailPropeties.To -join ';')")
                if ($emailPropertis.Containskey('Cc')) {
                    $null = $logMessage.Append(" `r`nCc: $($emailProperties.Cc -join ';')")
                }
                if ($emailPropertis.Containskey('Bcc')) {
                    $null = $logMessage.Append(" `r`nBcc: $($emailProperties.Bcc -join ';')")
                }
                $null = $logMessage.Append(" `r`nSubject: $($emailProperties.Subject)")
                $null = $logMessage.Append(" `r`nBody: $($emailProperties.Body)")

                Write-ADTLogEntry -Message $logMessage.ToString()

                [Hashtable]$smtpClientProperties = $emailProperties.SmtpClient
                $emailProperties.Remove('SmtpClient')

                try {
                    $message = [System.Net.Mail.MailMessage]::new($emailProperties.From, $emailProperties.To)
                    $emailProperties.Remove('From')
                    $emailProperties.Remove('To')

                    foreach ($path in $emailProperties.Attachments) {
                        $message.Attachments.Add($path)
                    }

                    $emailProperties.Remove('Attachments')

                    foreach ($property in $emailProperties.Keys) {
                        $message.$property = $emailProperties[$property]
                    }

                    try {
                        [System.Net.Mail.SmtpClient]$smtpClient = [System.Net.Mail.SmtpClient]::new($smtpClientProperties['SmtpServer'], $smtpClientProperties['Port'])
                        $null = $smtpClientProperties.Remove('SmtpServer')
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
                        $adtSession.DeferredEmails += $PSBoundParameters
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