function Send-ADTEmail {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Cc')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.Net.Mail.MailAddress[]]$Cc,

        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Bcc')]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [System.Net.Mail.MailAddress[]]$Bcc,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [Alias('sub')]
        [String]$Subject,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [Alias('Message')]
        [String]$Body,

        [Parameter()]
        [Switch]$IncludeLogs,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Priority')]
        [System.Net.Mail.MailPriority]$Priority,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Port')]
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]$Port = 25,

        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.UseDefaultCredentials')]
        [Switch]$UseDefaultCredentials,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.EnableSsl')]
        [Alias('UseSsl')]
        [Switch]$EnableSsl,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('BodyAsHtml', 'BAH')]
        [Switch]$IsBodyHtml,

        [Switch]$Defer
    )

    dynamicparam {
        Initialize-ADTModuleIfUninitialized -Cmdlet $PSCmdlet
        $adtConfig = Get-ADTConfig
        [Boolean]$configContainsEmailDefaults = $adtConfig.ContainsKey('Email') -and $adtConfig.Email.ContainsKey('Defaults')

        [System.Management.Automation.RuntimeDefinedParameterDictionary]$paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        $paramDictionary.Add('Attachments', [System.Management.Automation.RuntimeDefinedParameter]::new(
            'Attachments', [String[]], $(
                [System.Management.Automation.ParameterAttribute]@{
                    Mandatory = $false
                    ValueFromPipeline = $true
                    ValueFromPipelineByPropertyName = $true
                    HelpMessage = 'Specifies the path and file names of files to be attached to the email message. You can use this parameter or pipe the paths and file names to Send-ADTEmail.'
                }
                [System.Management.Automation.AliasAttribute]::new('Attachment', 'PSPath')
                [System.Management.Automation.ValidateScriptAttribute]::new({
                    if ([String]::IsNullOrWhiteSpace($_)) {
                        $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Attachments -ProvidedValue $_ -ExceptionMessage 'The provided value cannot be null or white space.'))
                    }
                    if ($Defer) {
                        if (-not (Test-Path -LiteralPath $_ -PathType Leaf -IsValid)) {
                            $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Attachments -ProvidedValue $_ -ExceptionMessage 'The provided value is not a valid file path.'))
                        }
                    } else {
                        if (-not (Test-Path -LiteralPath $_ -PathType Leaf)) {
                            $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Attachments -ProvidedValue $_ -ExceptionMessage 'The specified path does not exist.'))
                        }
                    }
                    return !!$_
                })
            )
        ))

        $paramDictionary.Add('From', [System.Management.Automation.RuntimeDefinedParameter]::new(
            'From', [System.Net.Mail.MailAddress], $(
                [System.Management.Automation.ParameterAttribute]@{
                    Mandatory = (-not ($configContainsEmailDefaults -and $adtConfig.Email.Defaults.ContainsKey('From')))
                    ValueFromPipelineByPropertyName = $true
                    HelpMessage = "The From parameter is required when not set in the ADT config under the Email.Defaults.From property. This parameter specifies the sender's email address. Enter a name (optional) and email address, such as `Name <someone@fabrikam.com>`."
                }
                [PSDefaultValue]@{ Help = '(Get-ADTConfig).Email.Defaults.From' }
                [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpaceAttribute]::new()
            )
        ))

        $paramDictionary.Add('SmtpServer', [System.Management.Automation.RuntimeDefinedParameter]::new(
            'SmtpServer', [String], $(
                [System.Management.Automation.ParameterAttribute]@{
                    Mandatory = ((-not ($configContainsEmailDefaults -and $adtConfig.Email.Defaults.ContainsKey('SmtpServer')) -and [String]::IsNullOrWhiteSpace($PSEmailServer)))
                    ValueFromPipelineByPropertyName = $true
                    HelpMessage = "The SmtpServer parameter is required when not set in the ```$PSEmailServer` preference variable or the ADT config under the `Email.Defaults.SmtpServer` property. This parameter specified the name of the SMTP server that sends the email message."
                }
                [PSDefaultValue]@{ Help = '(Get-ADTConfig).Email.Defaults.SmtpServer or $PSEmailServer' }
                [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpaceAttribute]::new()
            )
        ))

        $paramDictionary.Add('To', [System.Management.Automation.RuntimeDefinedParameter]::new(
            'To', [System.Net.Mail.MailAddress[]], $(
                [System.Management.Automation.ParameterAttribute]@{
                    Mandatory = (-not ($configContainsEmailDefaults -and $adtConfig.Email.Defaults.ContainsKey('To')))
                    ValueFromPipelineByPropertyName = $true
                    HelpMessage = "The To parameter is required when not set in the ADT config under the Email.Defaults.To property. This parameter specifies the recipient's email address. Enter names (optional) and the email address, such as `Name <someone@fabrikam.com>`."
                }
                [System.Management.Automation.AliasAttribute]::new('ComputerName')
                [PSDefaultValue]@{ Help = '(Get-ADTConfig).Email.Defaults.To' }
                [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpaceAttribute]::new()
            )
        ))

        return $paramDictionary
    }

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    } process {
        try {
            try {
                if ($Defer) {
                    if (-not (Test-ADTSessionActive)) {
                        [Hashtable]$naerParams = @{
                            Exception = [System.InvalidOperationException]::new('An ADT Session must be active to defer emails.')
                            Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                            ErrorId = 'AdtSessionRequiredToDeferEmail'
                        }
                        throw (New-ADTErrorRecord @naerParams)
                    }

                    $PSBoundParameters.Remove('Defer')
                    Write-ADTLogEntry -Message "Deferring email with properties: $(Resolve-ADTEmailLogMessage -Cmdlet $PSCmdlet)"
                    (Get-ADTSession).DeferredEmails.Add($PSBoundParameters)
                    return
                }

                Resolve-ADTEmailParameters -Cmdlet $PSCmdlet

                Write-ADTLogEntry -Message "Attempting to send email with properties: $(Resolve-ADTEmailLogMessage -Cmdlet $PSCmdlet)"
                [System.Net.Mail.MailMessage]$message = [System.Net.Mail.MailMessage]::new()
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
                Write-Error -ErrorRecord $_
            }
        } catch {
            $adtConfig = Get-ADTConfig
            if (-not $adtConfig.ContainsKey('Email')) {
                Write-ADTLogEntry -Message "Failed to send email. `r`n$(Resolve-ADTErrorRecord -ErrorRecord $_)" -Severity Error
            } elseif ($adtConfig.Email.ContainsKey('DeferOnFailureToSend') -and $adtConfig.Email.DeferOnFailureToSend) {
                if ($adtSession.InstallPhase -ne 'Finalization') {
                    Write-ADTLogEntry -Message "Failed to send email. Deferring email send. `r`n $(Resolve-ADTErrorRecord -ErrorRecord $_)" -Severity Error
                    $adtSession.DeferredEmails.Add($PSBoundParameters)
                } else {
                    Write-ADTLogEntry -Message "Failed to send email. `r`n$(Resolve-ADTErrorRecord -ErrorRecord $_)" -Severity Error
                }
            } elseif ($adtConfig.Email.ContainsKey('ExportOnFailureToSend') -and $adtConfig.Email.ExportOnFailureToSend) {
                Write-ADTLogEntry -Message "Failed to send email. Exporting email. `r`n $(Resolve-ADTErrorRecord -ErrorRecord $_)" -Severity Error
                Export-ADTEmail @PSBoundParameters
            }

            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_ -Silent
        }
    } end {
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}