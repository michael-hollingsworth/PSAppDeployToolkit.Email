function Export-ADTEmail {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Cc')]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [System.Net.Mail.MailAddress[]]$Cc,

        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Bcc')]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [System.Net.Mail.MailAddress[]]$Bcc,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [String]$Subject,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
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

        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.EnableSsl')]
        [Alias('UseSsl')]
        [Switch]$EnableSsl,

        [Parameter()]
        [Switch]$PassThru
    )

    dynamicparam {
        Initialize-ADTModuleIfUninitialized -Cmdlet $PSCmdlet
        $adtConfig = Get-ADTConfig
        [Boolean]$configContainsEmailDefaults = $adtConfig.ContainsKey('Email') -and $adtConfig.Email.ContainsKey('Defaults')

        [System.Management.Automation.RuntimeDefinedParameterDictionary]$paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        $paramDictionary.Add('Attachment', [System.Management.Automation.RuntimeDefinedParameter]::new(
            'Attachment', [String[]], $(
                [System.Management.Automation.ParameterAttribute]@{
                    Mandatory = $false
                    ValueFromPipeline = $true
                    ValueFromPipelineByPropertyName = $true
                    HelpMessage = "Specifies the path and file names of files to be attached to the email message. You can use this parameter or pipe the paths and file names to Send-ADTEmail."
                }
                [System.Management.Automation.AliasAttribute]::new('Attachments', 'PSPath')
                [System.Management.Automation.ValidateScriptAttribute]::new({
                    if ([String]::IsNullOrWhiteSpace($_)) {
                        $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Attachment -ProvidedValue $_ -ExceptionMessage 'The provided value cannot be null or white space.'))
                    }
                    if ($Defer) {
                        if (-not (Test-Path -LiteralPath $_ -PathType Leaf -IsValid)) {
                            $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Attachment -ProvidedValue $_ -ExceptionMessage 'The provided value is not a valid file path.'))
                        }
                    } else {
                        if (-not (Test-Path -LiteralPath $_ -PathType Leaf)) {
                            $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName Attachment -ProvidedValue $_ -ExceptionMessage 'The specified path does not exist.'))
                        }
                    }
                    return !!$_
                })
            )
        ))

        $paramDictionary.Add('ExportPath', [System.Management.Automation.RuntimeDefinedParameter]::new(
            'ExportPath', [String], $(
                [System.Management.Automation.ParameterAttribute]@{
                    Mandatory = (-not ($adtConfig.ContainsKey('Email') -and $adtConfig.Email.ContainsKey('ExportPath')))
                    HelpMessage = 'The ExportPath parameter is required when not set in the ADT config under the Email.ExportPath property. This parameter specifies the path to export emails to when calling Export-ADTEmail.'
                }
                [PSDefaultValue]@{ Help = '(Get-ADTConfig).Email.ExportPath' }
                [System.Management.Automation.ValidateScriptAttribute]::new(({
                    if ([String]::IsNullOrWhiteSpace($_)) {
                        $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ExportPath -ProvidedValue $_ -ExceptionMessage 'The specified input was null or an empty string.'))
                    }
                    if (-not (Test-Path -LiteralPath $_ -PathType Leaf -IsValid)) {
                        $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ExportPath -ProvidedValue $_ -ExceptionMessage 'The specified file path is not valid.'))
                    }
                    if (Test-Path -LiteralPath $_ -PathType Container) {
                        $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ExportPath -ProvidedValue $_ -ExceptionMessage 'The specified file path cannot be a folder.'))
                    }
                    return !!$_
                }))
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
                [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpaceAttribute]::new()
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
                [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpaceAttribute]::new()
            )
        ))

        $paramDictionary.Add('To', [System.Management.Automation.RuntimeDefinedParameter]::new(
            'To', [System.Net.Mail.MailAddress[]], $(
                [System.Management.Automation.ParameterAttribute]@{
                    Mandatory = (-not ($configContainsEmailDefaults -and $adtConfig.Email.Defaults.ContainsKey('To')))
                    ValueFromPipelineByPropertyName = $true
                    HelpMessage = "The To parameter is required when not set in the ADT config under the Email.Defaults.To property. This parameter specifies the recipient's email address. Enter names (optional) and the email address, such as `Name <someone@fabrikam.com>`."
                }
                [PSDefaultValue]@{ Help = '(Get-ADTConfig).Email.Defaults.To' }
                [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpaceAttribute]::new()
            )
        ))

        return $paramDictionary
    }

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        # If the export path is not provided, attempt to get it from the config
        [String]$literalPath = if ($PSBoundParameters.ContainsKey('ExportPath')) {
            $PSBoundParameters.Remove('ExportPath')
            $ExportPath
        } else {
            (Get-ADTConfig).Email.ExportPath
        }

        # Combine the already exported emails with the emails we are about to export.
        [System.Collections.Generic.List[Hashtable]]$exportedEmails = if (Test-Path -LiteralPath $literalPath -PathType Leaf) {
            Import-CliXml -LiteralPath $literalPath
        } else {
            [System.Collections.Generic.List[Hashtable]]::new()
        }

        if ($PSBoundParameters.ContainsKey('PassThru')) {
            $PSBoundParameters.Remove('PassThru')
        }

        [Int32]$startIndex = $exportedEmails.Count
    } process {
        Resolve-ADTEmailParameters -Cmdlet $PSCmdlet

        Write-ADTLogEntry -Message "Exporting email with properties: $(Resolve-ADTEmailLogMessage -Cmdlet $PSCmdlet)"

        $exportedEmails.Add($PSBoundParameters)
    } end {
        try {
            try {
                Export-CliXml -InputObject $exportedEmails -LiteralPath $literalPath -Force

                if ($PassThru) {
                    return $exportedEmails[$startIndex..($exportedEmails.Count -1)]
                }
            } catch {
                Write-Error -ErrorRecord $_
            }
        } catch {
            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
        } finally {
            Complete-ADTFunction -Cmdlet $PSCmdlet
        }
    }
}
