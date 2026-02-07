function Get-ADTEmailParameters {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress]$From,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$To,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress[]]$Cc,
        [Parameter()]
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
        [System.Net.Mail.MailPriority]$Priority,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SmtpServer,
        [Parameter()]
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]$Port = 25,
        [Parameter()]
        [Switch]$UseDefaultCredentials,
        [Parameter()]
        [Alias('UseSsl')]
        [Switch]$EnableSsl,
        [Switch]$Defer
    )

    begin {
        if (Test-ADTSessionActive) {
            $adtSession = Get-ADTSession
        }
        $adtConfig = Get-ADTConfig
    } process {
        [Hashtable]$emailProperties = @{ Subject = $Subject }

        if (-not [String]::IsNullOrWhiteSpace($Body)) {
            $emailProperties.Add('Body', $Body)
        }

        [String[]]$adtEmailConfigProperties = @(
            'Bcc',
            'Cc',
            'From',
            'Priority',
            'To'
        )

        foreach ($property in $adtEmailConfigProperties) {
            if ($PSBoundParameters.ContainsKey($property)) {
                $emailProperties.Add($property, $PSBoundParameters[$property])
            } elseif ($adtConfig.Email.Defaults.ContainsKey($property)) {
                $emailProperties.Add($property, $adtConfig.Email[$property])
            }
        }

        [Hashtable]$smtpClientProperties = [Hashtable]::new()
        [String[]]$adtsmtpClientProperties = @(
            'Port',
            'SmtpServer',
            'UseDefaultCredentials',
            'EnableSsl'
        )

        foreach ($property in $adtsmtpClientProperties) {
            if ($PSBoundParameters.ContainsKey($property)) {
                $smtpClientProperties.Add($property, $PSBoundParameters[$property])
            } elseif ($adtConfig.Email.Defaults.SmtpClient.ContainsKey($property)) {
                $smtpClientProperties.Add($property, $adtConfig.Email[$property])
            }
        }

        if ($IncludeLogs) {
            if ((-not [String]::IsNullOrWhiteSpace($adtSession.LogPath)) -and (-not [String]::IsNullOrWhiteSpace($adtSession.LogName)) -and ($logPath = Join-Path -Path $adtSession.LogPath -ChildPath $adtSession.LogName)) {
                $Attachment += $logPath
            }

            if ($adtSession.AdditionalLogFiles.Count) {
                [String[]]$Attachment += $adtSession.AdditionalLogFiles
            }
        }

        if ($Attachment) {
            # Only include attachments that exist
            [String[]]$attachmentsToSend = foreach ($path in $Attachment) {
                if (Test-Path -LiteralPath $path -PathType Leaf) {
                    $path
                }
            }

            # Don't include duplicate attachments
            $emailProperties.Attachments = $attachmentsToSend | Select-Object -Unique
        }

        if ($smtpClientProperties.Keys.Count) {
            $emailProperties.Add('SmtpClient', $smtpClientProperties)
        }

        return $emailProperties
    }
}