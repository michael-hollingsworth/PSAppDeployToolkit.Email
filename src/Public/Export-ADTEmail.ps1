function Export-ADTEmail {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.From')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress]$From,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.To')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$To,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Cc')]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$Cc,
        [Parameter()]
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Bcc')]
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
        [PSDefaultValue(Help = '(Get-ADTConfig).Email.Defaults.Priority')]
        [System.Net.Mail.MailPriority]$Priority,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
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
        [Hashtable]$email = Resolve-ADTEmailParameters @PSBoundParameters

        Write-ADTLogEntry -Message "Exporting email with properties: `r`n $($email | Format-List | Out-String -Width ([Int32]::MaxValue))"

        $deferredEmails += $email
    } end {
        Export-CliXml -InputObject $deferredEmails -LiteralPath $adtConfig.Email.ExportPath -Force

        Complete-ADTFunction -Cmdlet
    }
}