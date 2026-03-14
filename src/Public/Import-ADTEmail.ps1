function Import-ADTEmail {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.ExportPath')]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
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
        [Alias('PSPath', 'LP')]
        [String]$LiteralPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'ImportToDeferredEmails')]
        [Switch]$ImportToDeferredEmails,

        [Parameter(ParameterSetName = 'ImportToDeferredEmails')]
        [Switch]$PassThru
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    } process {
        try {
            try {
                # If the import path is not provided, attempt to get it from the config
                if (-not $PSBoundParameters.ContainsKey('LiteralPath')) {
                    Initialize-ADTModuleIfUninitialized -Cmdlet $PSCmdlet
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
                    $LiteralPath = if (Test-Path -LiteralPath $_ -PathType Container) {
                        Join-Path -Path $adtConfig.Email.ExportPath -ChildPath 'ExportedEmails.xml'
                    } else  {
                        $adtConfig.Email.ExportPath
                    }
                }

                [Hashtable[]]$importedEmails = Import-CliXml -LiteralPath $LiteralPath

                if (-not $importedEmails.Count) {
                    return
                }

                if (-not $ImportToDeferredEmails) {
                    return $importedEmails
                }

                $adtSession = Get-ADTSession
                $adtSession.DeferredEmails.AddRange($importedEmails)

                if ($PassThru) {
                    return $importedEmails
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