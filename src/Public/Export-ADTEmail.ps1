function Export-ADTEmail {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.From')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress]$From,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.To')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$To,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Cc')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$Cc,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Bcc')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$Bcc,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Subject,
        [Parameter()]
        [Alias('Message')]
        [String]$Body,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]$Attachment,
        [Parameter()]
        [Switch]$IncludeLogs,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Priority')]
        [System.Net.Mail.MailPriority]$Priority,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SmtpServer,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Port')]
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]$Port = 25,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.UseDefaultCredentials')]
        [Switch]$UseDefaultCredentials,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.EnableSsl')]
        [Alias('UseSsl')]
        [Switch]$EnableSsl,
        [Switch]$Defer
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $adtConfig = Get-ADTConfig

        #TODO: Validate that the caller has write permissions
        if (Test-Path -LiteralPath $adtConfig.Email.ExportPath) {
            [Hashtable[]]$deferredEmails = Import-CliXml -LiteralPath $adtConfig.Email.ExportPath
        } else {
            [Hashtable[]]$deferredEmails = @()
        }
    } process {
        [Hashtable]$email = Get-ADTEmailParameters @PSBoundParameters

        Write-ADTLogEntry -Message "Exporting email with properties: `r`n $($email | Format-List | Out-String -Width ([Int32]::MaxValue))"

        $deferredEmails += $email
    } end {
        Export-CliXml -InputObject $deferredEmails -LiteralPath $adtConfig.Email.ExportPath -Force

        Complete-ADTFunction -Cmdlet
    }
}