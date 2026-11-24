@{
    Email = @{
        # Default properties auto populate the parameters of `Send-ADTEmail`, when they aren't provided.
        ## These properties support variable expansion. Variables which aren't escaped (eg. $unescaped) are expanded when the config is initially loaded. PSADT does not allow subexpressions (eg. $($adtSession.InstallName)) in config properties that are expanded during the module's initialization.
        ## Variables which are escaped (eg. `$escaped) are expanded at the time `Send-ADTEmail` is called. Escaped subexpressions are allowed (eg. `$(`$adtSession.InstallName)).
        ## Only the following variables are available for expansion when they are escaped:
        ##     - Properties of the current ADT Session (i.e., `$(`$adtSession.<PROPERTY>))
        ##     - Properties of the ADT config (i.e., `$(`$adtConfig.<PROPERTY>))
        ##     - Environment variables (i.e., `$env:<VARIABLE>)
        ##     - Global variables (i.e., `$global:<VARIABLE>)
        ##     - Variables made available via `Export-ADTEnvironmentTableToSessionState`
        Defaults = @{
            # List of email addresses to BCC emails to when the -Bcc parameter isn't used with `Send-Email`.
            Bcc = @()

            # List of email addresses to CC emails to when the -Cc parameter isn't used with `Send-Email`.
            Cc = @()

            # The email address to send emails from when the -From parameter isn't used with `Send-Email`.
            From = 'Deploy-`$(`$adtSession.InstallName)@MyDomain.com'

            # Priority to send emails with. Valid values are members of the [System.Net.Mail.MailPriority] enum; Normal, Low, High
            Priority = 'High'

            # List of email addresses to send emails to when the -To parameter isn't used with `Send-Email`.
            To = @()

            # Specify whether the SmtpClient uses Secure Sockets Layer (SSL) to encrypt the connection to the SMTP server.
            EnableSsl = $false

            # Specify the port used for SMTP transactions.
            Port = 25

            # Specify the name or IP address of the host used for SMTP transactions.
            SmtpServer = 'smtp.MyDomain.com'

            # Specify whether or not to use the credentials of the calling user.
            ## In a scenario where you are sending emails to an unauthenticated SMTP server, enabling this can lead to errors when the calling user is a member of the "Protected Users" group.
            UseDefaultCredentials = $false
        }

        # Whether or not to send an email when a deployment session closes with a non-success exit code.
        ## Closing an ADT session with a user-defined `[ExitCode]` enum will NOT result in an email being sent.
        ## The theory is that if you are exiting with a custom exit code, you are also providing specialized logic to handle those scenarios, with more detailed emails than just an error record.
        ## This also applies to the custom `ScriptSuccessExitCodes` deployment session property. If a deployment session closes with one of the exit codes specified in `$adtSession.ScriptSuccessExitCodes`, an email will not be automatically sent.
        ## For example, `Close-ADTSession -ExitCode ([ExitCode]::ApplicationNotFound)` will not automatically send an email but `Close-ADTSession -ExitCode 69012` will.
        SendEmailOnErrorExit = $true

        # Whether or not to defer emails (send them when the current ADT session closes) when `Send-Email` fails to send them.
        DeferOnFailureToSend = $true

        # Whether or not to export emails that fail to send
        ## If DeferOnFailureToSend is also set to true, the email will first be deferred and sent when the ADT session is closed. If the email fails to send there, it will be exported
        ## If `Send-Email` fails to send an email and the -Defer
        ExportOnFailureToSend = $true

        # Specify the default location to export emails that failed to send.
        ## This is also the default path where emails are imported/exported from when using the Import-ADTEmail and Export-ADTEmail functions.
        ExportPath = '$env:Temp\DeferedEmails.xml'

        # Same as TempPath but used when ExportPath is False.
        ExportPathNoAdminRights = '$env:Temp\DeferedEmails.xml'

        # Specify whether or not to send emails that have been exported by scripts that have run in the past
        SendExportedEmails = $true
    }
}
