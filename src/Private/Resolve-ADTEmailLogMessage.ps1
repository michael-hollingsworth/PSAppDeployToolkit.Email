function Resolve-ADTEmailLogMessage {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [String[]]$Attachments,
        [String[]]$Bcc,
        [String]$Body,
        [String[]]$Cc,
        [String]$From,
        [String]$Subject,
        [String[]]$To,
        # Somewhere for the remaining arguments that we don't care about to go
        [Parameter(ValueFromRemainingArguments = $true)]
        $Remaining
    )

    [System.Text.StringBuilder]$logMessage = [System.Text.StringBuilder]::new()
    <# foreach ($property in @('From', 'To', 'Bcc', 'Cc', 'Subject', 'Body', 'Attachments')) {
        if ($PSBoundParameters.ContainsKey($property)) {
            $null = $logMessage.Append(" `r`n${property}: $($PSBoundParameters[$property] -join ';')")
        }
    } #>

    if (-not [String]::IsNullOrWhiteSpace($From)) {
        $null = $logMessage.Append(" `r`nFrom: $From")
    }
    if (-not [String]::IsNullOrWhiteSpace($To)) {
        $null = $logMessage.Append(" `r`nTo: $($To -join ';')")
    }
    if (-not [String]::IsNullOrWhiteSpace($Cc)) {
        $null = $logMessage.Append(" `r`nCc: $($Cc -join ';')")
    }
    if (-not [String]::IsNullOrWhiteSpace($Bcc)) {
        $null = $logMessage.Append(" `r`nBcc: $($Bcc -join ';')")
    }
    if (-not [String]::IsNullOrWhiteSpace($Subject)) {
        $null = $logMessage.Append(" `r`nSubject: $Subject")
    }
    if (-not [String]::IsNullOrWhiteSpace($Body)) {
        $null = $logMessage.Append(" `r`nBody: `r`n$Body")
    }
    if (-not [String]::IsNullOrWhiteSpace($Attachments)) {
        $null = $logMessage.Append(" `r`Attachments: $($Attachments -join ';')")
    }

    return $logMessage.ToString()
}