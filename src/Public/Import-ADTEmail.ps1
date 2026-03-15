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

    dynamicparam {
        Initialize-ADTModuleIfUninitialized -Cmdlet $PSCmdlet
        $adtConfig = Get-ADTConfig

        [System.Management.Automation.RuntimeDefinedParameterDictionary]$paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        $paramDictionary.Add('LiteralPath', [System.Management.Automation.RuntimeDefinedParameter]::new(
            'LiteralPath', [String], $(
                [System.Management.Automation.ParameterAttribute]@{
                    Mandatory = (-not ($adtConfig.ContainsKey('Email') -and $adtConfig.Email.ContainsKey('LiteralPath')))
                    HelpMessage = 'The LiteralPath parameter is required when not set in the ADT config under the Email.ExportPath property. This parameter specifies the path to import emails from when calling Import-ADTEmail.'
                }
                [PSDefaultValue]@{ Help = '(Get-ADTConfig).Email.ExportPath' }
                [System.Management.Automation.ValidateScriptAttribute]::new(({
                    if ([String]::IsNullOrWhiteSpace($_)) {
                        $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName LiteralPath -ProvidedValue $_ -ExceptionMessage 'The specified input was null or an empty string.'))
                    }
                    if (-not (Test-Path -LiteralPath $_ -PathType Leaf -IsValid)) {
                        $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName LiteralPath -ProvidedValue $_ -ExceptionMessage 'The specified file path is not valid.'))
                    }
                    if (Test-Path -LiteralPath $_ -PathType Container) {
                        $PSCmdlet.ThrowTerminatingError((New-ADTValidateScriptErrorRecord -ParameterName LiteralPath -ProvidedValue $_ -ExceptionMessage 'The specified file path cannot be a folder.'))
                    }
                    return !!$_
                }))
            )
        ))

        return $paramDictionary
    }

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    } process {
        try {
            try {
                # If the import path is not provided, attempt to get it from the config
                if (-not $PSBoundParameters.ContainsKey('LiteralPath')) {
                    $LiteralPath = (get-ADTConfig).Email.ExportPath
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