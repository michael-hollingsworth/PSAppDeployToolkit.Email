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
                            EnableSsl = [Boolean]
                            Port = [UInt16]
                            SmtpServer = [String]
                            UseDefaultCredentials = [Boolean]
                        }

                        DeferOnFailureToSend = [Boolean]
                        ExportOnFailureToSend = [Boolean]
                        ExportPath = [System.IO.Path]
                        SendExportedEmails = [Boolean]
                    }
                }

                if ($adtConfig.ContainsKey('Email')) {
                    # Change path to user accessible one if the caller isn't an admin
                    if (-not (Get-ADTEnvironmentTable).IsAdmin) {
                        if ($adtConfig.Email.ContainsKey('ExportPathNoAdminRights') -and (-not [String]::IsNullOrWhiteSpace($adtConfig.Email.ExportPathNoAdminRights))) {
                            $adtConfig.Email.ExportPath = $adtConfig.Email.ExportPathNoAdminRights
                        }
                    }

                    # If the export path is a folder add the child path of 'ExportedEmails.xml'
                    if ($adtConfig.Email.ContainsKey('ExportPath') -and (Test-Path -LiteralPath $adtConfig.Email.ExportPath -PathType Container)) {
                        Write-ADTLogEntry -Message "The config property [Email.ExportPath] is the path of a directory. Changing export path from [$($adtConfig.Email.ExportPath)] to [[$($adtConfig.Email.ExportPath)]\ExportedEmails.xml]" -Severity Warning
                        $adtConfig.Email.ExportPath = Join-Path -Path $adtConfig.Email.ExportPath -ChildPath 'ExportedEmails.xml'
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