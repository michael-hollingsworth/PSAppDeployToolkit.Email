function Confirm-ADTEmailConfig {
    [CmdletBinding()]
    param (
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    } process {
        try {
            try {
                $adtConfig = Get-ADTConfig

                if (-not $adtConfig.ContainsKey('Email')) {
                    return
                }

                Confirm-ADTConfig -Config $adtConfig -ConfigTemplate @{
                    Email = @{
                        Defaults = @{
                            Bcc = [System.Net.Mail.MailAddress[]]
                            Cc = [System.Net.Mail.MailAddress[]]
                            From = [System.Net.Mail.MailAddress]
                            Priority = [System.Net.Mail.MailPriority]
                            To = [System.Net.Mail.MailAddress[]]
                            SmtpClient = @{
                                EnableSsl = [Boolean]
                                Port = [UInt16]
                                SmtpServer = [String]
                                UseDefaultCredentials = [Boolean]
                            }
                        }

                        DeferOnFailureToSend = [Boolean]
                        ExportOnFailureToSend = [Boolean]
                        ExportPath = [System.IO.Path]
                        SendExportedEmails = [Boolean]
                    }
                }

                # Change path to user accessible one if the caller isn't an admin
                if (-not (Get-ADTEnvironmentTable).IsAdmin) {
                    if (-not [String]::IsNullOrWhiteSpace($adtConfig.Email.ExportPathNoAdminRights)) {
                        $adtConfig.Email.ExportPath = $adtConfig.Email.ExportPathNoAdminRights
                    }
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