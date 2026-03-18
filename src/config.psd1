@{
    Email = @{
        Defaults = @{
            # List of email addresses to BCC emails to when the -Bcc parameter isn't used with `Send-Email`.
            Bcc = @()

            # List of email addresses to CC emails to when the -Cc parameter isn't used with `Send-Email`.
            Cc = @()

            # The email address to send emails from when the -From parameter isn't used with `Send-Email`.
            From = 'Deploy-$($adtSession.InstallTitle)@MyDomain.com'

            # Priority to send emails with. Valid values are members of the [System.Net.Mail.MailPriority] enum; Normal, Low, High
            Priority = 'High'

            # List of email addresses to send emails to when the -To parameter isn't used with `Send-Email`.
            To = @()

            # SMTP client properties
            ##
            EnableSsl = $false

            ## SMTP port to send emails on
            Port = 25

            ## Address of SMTP server to route emails through
            SmtpServer = 'smtp.MyDomain.com'

            ## Whether or not to use the credentials of the calling user.
            ### In a scenario where you are sending emails to an unauthenticated SMTP server, enabling this can lead to errors when the calling user is a member of the "Protected Users" group.
            UseDefaultCredentials = $false
        }

        # Whether or not to defer emails (send them when the current ADT session closes) when `Send-Email` fails to send them.
        DeferOnFailureToSend = $true

        # Whether or not to export emails that fail to send
        ## If DeferOnFailureToSend is also set to true, the email will first be deferred and sent when the ADT session is closed. If the email fails to send there, it will be exported
        ## If `Send-Email` fails to send an email and the -Defer
        ExportOnFailureToSend = $true

        # Where to export emails that failed to send
        ## This is also the default path where emails are imported/exported from when using the Import-ADTEmail and Export-ADTEmail functions.
        ExportPath = '$env:Temp\DeferedEmails.xml'

        # Same as TempPath but used when ExportPath is False.
        ExportPathNoAdminRights = '$env:Temp\DeferedEmails.xml'

        # Whether or not to send emails that have been exported by scripts that have run in the past
        SendExportedEmails = $true
    }
}