function Export-ADTEmail {
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
        [Alias('Message')]
        [String]$Body,

        [Parameter()]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
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

        [Parameter()]
        [ValidateScript({
            if ([String]::IsNullOrWhiteSpace($_)) {
                $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ExportPath -ProvidedValue $_ -ExceptionMessage 'The specified input was null or an empty string.'))
            }
            if (-not (Test-Path -LiteralPath $_ -IsValid)) {
                $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ExportPath -ProvidedValue $_ -ExceptionMessage 'The specified file path is not valid.'))
            }
            if (Test-Path -LiteralPath $_ -PathType Container) {
                $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName ExportPath -ProvidedValue $_ -ExceptionMessage 'The specified file path cannot be a folder.'))
            }
            return !!$_
        })]
        [String]$ExportPath
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        # If the export path is not provided, attempt to get it from the config
        if (-not $PSBoundParameters.ContainsKey('ExportPath')) {
            $adtConfig = Get-ADTConfig
            [Boolean]$configContainsExportPath = $adtConfig.ContainsKey('Email') -and $adtConfig.Email.Containskey('ExportPath') -and (-not [String]::IsNullOrWhiteSpace($adtConfig.Email.ExportPath))
            if (-not $configContainsExportPath) {
                [Hashtable]$naerParams = @{
                    Exception = [System.Management.Automation.PSArgumentNullException]::new('ExportPath')
                    Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    ErrorId = 'InvalidExportPathParameterValue'
                    TargetObject = $ExportPath
                }
                throw (New-ADTErrorRecord @naerParams)
            }

            # If the export path is a folder add the child path of 'ExportedEmails.xml'
            $ExportPath = if (Test-Path -LiteralPath $_ -PathType Container) {
                Join-Path -Path $adtConfig.Email.ExportPath -ChildPath 'ExportedEmails.xml'
            } else  {
                $adtConfig.Email.ExportPath
            }
        }

        # Combine the already exported emails with the emails we are about to export.
        [System.Collections.Generic.List[Hashtable]]$deferredEmails = if (Test-Path -LiteralPath $ExportPath -PathType Leaf) {
            Import-CliXml -LiteralPath $ExportPath
        } else {
            [System.Collections.Generic.List[Hashtable]]::new()
        }
    } process {
        [Hashtable]$boundParams = $PSBoundParameters
        if ($boundParams.ContainsKey('ExportPath')) {
            $boundParams.Remove('ExportPath')
        }
        [Hashtable]$email = Resolve-ADTEmailParameters @boundParams

        Write-ADTLogEntry -Message "Exporting email with properties: $(Resolve-ADTEmailLogMessage @email)"

        $deferredEmails.Add($email)
    } end {
        try {
            try {
                Export-CliXml -InputObject $deferredEmails -LiteralPath $ExportPath -Force
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
