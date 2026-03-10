<#
.DESCRIPTION
    Adds a custom property to the current ADT session.
.EXAMPLE
    Initialize-ADTSessionProperty -Name 'DeferredEmails -Value ([System.Collections.Generic.List[Hashtable]]::new())
#>
function Initialize-ADTSessionProperty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSAppDeployToolkit.Foundation.ValidateNotNullOrWhiteSpace()]
        [String]$Name,
        [Parameter(Mandatory = $true, Position = 1)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        $Value
    )

    begin {
        # Initialize function.
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $adtSession = Get-ADTSession
    } process {
        try {
            try {
                if ($adtSession.PSObject.Properties.Name.Contains($Name)) {
                    return
                }

                Write-ADTLogEntry -Message "Adding [$Name] property to the current ADT session."
                Add-Member -InputObject $adtSession -MemberType NoteProperty -Name $Name -Value $Value
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