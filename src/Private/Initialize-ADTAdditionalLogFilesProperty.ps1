<#
.DESCRIPTION
    Callback function used to add a "AdditionalLogFiles" property to every ADT sessions when they are created
.EXAMPLE
    
#>
function Initialize-ADTAdditionalLogFilesProperty {
    [CmdletBinding()]
    param (
    )

    begin {
        # Initialize function.
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $adtSession = Get-ADTSession
    } process {
        try {
            try {
                if ($adtSession.PSObject.Properties.Name.Contains('AdditionalLogFiles')) {
                    return
                }

                Write-ADTLogEntry -Message 'Adding [AdditionalLogFiles] property to the current ADT session.'
                Add-Member -InputObject $adtSession -MemberType NoteProperty -Name 'AdditionalLogFiles' -Value ([System.Collections.Generic.List[String]]::new())
            } catch {
                # Re-writing the ErrorRecord with Write-Error ensures the correct PositionMessage is used.
                Write-Error -ErrorRecord $_
            }
        } catch {
            # Process the caught error, log it and throw depending on the specified ErrorAction.
            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
        }
    } end {
        # Finalize function.
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}