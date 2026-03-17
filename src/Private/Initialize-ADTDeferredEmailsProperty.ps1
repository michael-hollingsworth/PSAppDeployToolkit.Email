<#
.DESCRIPTION
    Callback function used to add a "DeferredEmails" property to every ADT sessions when they are created
.EXAMPLE
    Initialize-ADTDeferredEmailsProperty
#>
function Initialize-ADTDeferredEmailsProperty {
    [CmdletBinding()]
    param (
    )

    Add-ADTSessionProperty -Name 'DeferredEmails' -Value ([System.Collections.Generic.List[Hashtable]]::new())
}