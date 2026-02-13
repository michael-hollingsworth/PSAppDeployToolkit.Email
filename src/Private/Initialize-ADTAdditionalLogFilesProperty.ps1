<#
.DESCRIPTION
    Callback function used to add a "AdditionalLogFiles" property to every ADT sessions when they are created
.EXAMPLE
    Initialize-ADTAdditionalLogFilesProperty
#>
function Initialize-ADTAdditionalLogFilesProperty {
    [CmdletBinding()]
    param (
    )

    Initialize-ADTSessionProperty -Name 'AdditionalLogFiles' -Value ([System.Collections.Generic.List[String]]::new())
}