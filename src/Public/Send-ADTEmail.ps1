function Send-ADTEmail {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.From')]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [System.Net.Mail.MailAddress]$From,

        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.To')]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [System.Net.Mail.MailAddress[]]$To,

        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Cc')]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [System.Net.Mail.MailAddress[]]$Cc,

        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Bcc')]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [System.Net.Mail.MailAddress[]]$Bcc,

        [Parameter()]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [String]$Subject,

        [Parameter()]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [Alias('Message')]
        [String]$Body,

        [Parameter()]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [ValidateScript({
            if ([String]::IsNullOrWhiteSpace($_)) {
                $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Attachment -ProvidedValue $_ -ExceptionMessage 'The provided value cannot be null or white space.'))
            }
            if (-not (Test-Path -LiteralPath $_ -PathType Leaf -IsValid)) {
                $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Attachment -ProvidedValue $_ -ExceptionMessage 'The provided value is not a valid file path.'))
            }
            return !!$_
        })]
        [String[]]$Attachment,

        [Parameter()]
        [Switch]$IncludeLogs,

        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Priority')]
        [System.Net.Mail.MailPriority]$Priority,

        [Parameter()]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
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
                    Write-ADTLogEntry -Message "Deferring email with properties: $(Resolve-ADTEmailLogMessage -Cmdlet $PSCmdlet)"
                    (Get-ADTSession).DeferredEmails.Add($boundParams)
                    return
                }

                Resolve-ADTEmailParameters -Cmdlet $PSCmdlet

                #TODO: Validate that the To, From, SmtpServer, and Port fields have values
                if (-not $PSBoundParameters.ContainsKey('From')) {
                    throw (New-ADTValidateScriptErrorRecord -ParameterName From -ProvidedValue $From -ExceptionMessage 'Parameter value cannot be null or white space')
                }

                Write-ADTLogEntry -Message "Attempting to send email with properties: $(Resolve-ADTEmailLogMessage -Cmdlet $PSCmdlet)"
                $message = [System.Net.Mail.MailMessage]::new()
                try {
                    # Properties that can only be modified using the Add() method
                    foreach ($property in @('AlternateViews', 'Attachments', 'Bcc', 'Cc', 'Headers', 'ReployToList', 'To')) {
                        if (-not $PSBoundParameters.ContainsKey($property)) {
                            continue
                        }

                        foreach ($value in $PSBoundParameters.$property) {
                            $message.$property.Add($value)
                        }
                    }

                    # All remaining properties
                    foreach ($property in @('Body', 'BodyEncoding', 'BodyTransferEncoding', 'DeliveryNotificationOptions', 'From', 'HeadersEncoding', 'IsBodyHtml', 'Priority', 'ReplyTo', 'Sender', 'Subject', 'SubjectEncoding')) {
                        if ($PSBoundParameters.ContainsKey($property)) {
                            $message.$property = $PSBoundParameters.$property
                        }
                    }

                    [System.Net.Mail.SmtpClient]$smtpClient = [System.Net.Mail.SmtpClient]::new($PSBoundParameters.SmtpServer)
                    try {
                        foreach ($property in @('Credentials', 'DeliveryFormat', 'DeliveryMethod', 'EnableSsl', 'Host', 'PickupDirectoryLocation', 'Port', 'TargetName', 'Timeout', 'UseDefaultCredentials')) {
                            if ($PSBoundParameters.ContainsKey($property)) {
                                $smtpClient.$property = $PSBoundParameters.$property
                            }
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
                #TODO: See if this can be better re-organized
                Initialize-ADTModuleIfUnitialized -Cmdlet $PSCmdlet
                $adtConfig = Get-ADTConfig
                if (-not $adtConfig.ContainsKey('Email')) {
                } elseif ($adtConfig.Email.ContainsKey('DeferOnFailureToSend') -and $adtConfig.Email.DeferOnFailureToSend) {
                    if ($adtSession.InstallPhase -ne 'Finalization') {
                        $adtSession.DeferredEmails.Add($PSBoundParameters)
                    }
                } elseif ($adtConfig.Email.ContainsKey('ExportOnFailureToSend') -and $adtConfig.Email.ExportOnFailureToSend) {
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