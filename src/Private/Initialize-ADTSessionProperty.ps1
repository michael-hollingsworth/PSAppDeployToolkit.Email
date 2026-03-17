<#
.DESCRIPTION
    Adds a custom property to the current ADT session.
.EXAMPLE
    Initialize-ADTSessionProperty -Name 'DeferredEmails -Value ([System.Collections.Generic.List[Hashtable]]::new())
#>
function Add-ADTSessionProperty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSAppDeployToolkit.Attributes.ValidateNotNullOrWhiteSpace()]
        [String]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        $Value,

        [Parameter()]
        [Switch]$Force
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $adtSession = Get-ADTSession
    } process {
        try {
            try {
                Write-ADTLogEntry -Message "Adding [$Name] property to the current ADT session."
                Add-Member -InputObject $adtSession -MemberType NoteProperty -Name $Name -Value $Value -Force:(!!$Force)
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