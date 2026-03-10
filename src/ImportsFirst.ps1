# Throw if this psm1 file isn't being imported via our manifest.
if (-not ([System.Environment]::StackTrace.Split("`n") -like '*Microsoft.PowerShell.Commands.ModuleCmdletBase.LoadModuleManifest(*')) {
    throw [System.Management.Automation.ErrorRecord]::new(
        [System.InvalidOperationException]::new('This module must be imported via its .psd1 file, which is recommended for all modules that supply a .psd1 file.'),
        'ModuleImportError',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $MyInvocation.MyCommand.ScriptBlock.Module
    )
}

# Rethrowing caught exceptions makes the error output from Import-Module look better.
try {
    # Set up lookup table for all cmdlets used within module, using PSAppDeployToolkit's as a basis.
    $CommandTable = [System.Collections.Generic.Dictionary[System.String, System.Management.Automation.CommandInfo]](& (& 'Microsoft.PowerShell.Core\Get-Command' -Name Get-ADTCommandTable -FullyQualifiedModule @{ ModuleName = 'PSAppDeployToolkit'; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.0.6' }))

    # Set required variables to ensure module functionality.
    New-Variable -Name ErrorActionPreference -Value ([System.Management.Automation.ActionPreference]::Stop) -Option Constant -Force
    New-Variable -Name InformationPreference -Value ([System.Management.Automation.ActionPreference]::Continue) -Option Constant -Force
    New-Variable -Name ProgressPreference -Value ([System.Management.Automation.ActionPreference]::SilentlyContinue) -Option Constant -Force

    # Ensure module operates under the strictest of conditions.
    Set-StrictMode -Version 3

    # Store build information pertaining to this module's state.
    New-Variable -Name Module -Option Constant -Force -Value ([ordered]@{
        Manifest = Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName 'PSAppDeployToolkit.Email.psd1'
        Compiled = $MyInvocation.MyCommand.Name.Equals('PSAppDeployToolkit.Email.psm1')
    }).AsReadOnly()

    # Remove any previous functions that may have been defined.
    if ($Module.Compiled) {
        New-Variable -Name FunctionPaths -Option Constant -Value ($MyInvocation.MyCommand.ScriptBlock.Ast.EndBlock.Statements | & { process { if ($_ -is [System.Management.Automation.Language.FunctionDefinitionAst]) { return "Microsoft.PowerShell.Core\Function::$($_.Name)" } } })
        Remove-Item -LiteralPath $FunctionPaths -Force -ErrorAction Ignore
    }
} catch {
    throw
}