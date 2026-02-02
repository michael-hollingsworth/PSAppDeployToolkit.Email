function Confirm-ADTEmailConfig {
    [CmdletBinding()]
    param (
    )

    begin {
        # Initialize function.
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $adtConfig = Get-ADTConfig

        if (-not $adtConfig.ContainsKey('Email')) {
            return
        }

        [Hashtable[]]$properties = @(
            @{
                Name = 'Bcc'
                Type = [System.Net.Mail.MailAddress[]]
            },
            @{
                Name = 'Cc'
                Type = [System.Net.Mail.MailAddress[]]
            },
            @{
                Name = 'DeferOnFailureToSend'
                Type = [Boolean]
            },
            @{
                Name = 'EnableSsl'
                Type = [Boolean]
            },
            @{
                Name = 'ExportOnFailureToSend'
                Type = [Boolean]
            },
            @{
                Name = 'ExportPath'
                Type = [System.IO.Path]
            },
            @{
                Name = 'From'
                Type = [System.Net.Mail.MailAddress]
            },
            @{
                Name = 'Port'
                Type = [Int32]
            },
            @{
                Name = 'Priority'
                Type = [System.Net.Mail.MailPriority]
            },
            @{
                Name = 'SendExportedEmails'
                Type = [Boolean]
            },
            @{
                Name = 'SmtpServer'
                Type = [String]
            },
            @{
                Name = 'To'
                Type = [System.Net.Mail.MailAddress[]]
            },
            @{
                Name = 'UseDefaultCredentials'
                Type = [Boolean]
            }
        )
    } process {
        try {
            try {
                foreach ($property in $properties) {
                    if (-not $adtConfig.Email.ContainsKey($property.Name)) {
                        continue
                    }

                    switch ($property.Type) {
                        { $_ -eq [String] } {
                            continue
                        }
                        { ($_ -eq [System.Net.Mail.MailAddress]) -or ($_ -eq [System.Net.Mail.MailAddress[]]) } {
                            foreach ($address in $adtConfig.Email.$($property.Name)) {
                                try {
                                    [System.Net.Mail.MailAddress]::new($address)
                                } catch {
                                    throw "Invalid ADT config. The email address [$address] in the [$($property.Name)] property is invalid."
                                }
                            }
                            continue
                        }
                        { $_ -eq [System.IO.Path] } {
                            if (-not (Test-Path -LiteralPath $adtConfig.Email.$($property.Name) -IsValid)) {
                                throw "Invalid ADT config. The property [ $($property.Name)] with value [$($adtConfig.Email.$($property.Name))] is invalid. It must be a valid file/folder path."
                            }
                            continue
                        }
                        { $_.BaseType -eq [Enum] } {
                            # System.Net.Mail.MailPriority
                            try {
                                $null = [Enum]::Parse($property.Type, $adtConfig.Email.$($property.Name), $true)
                            } catch {
                                throw "Invalid ADT config. The property [$($property.Name)] with value [$($adtConfig.Email.$($property.Name))] is invalid. It must be a member of the [$($property.Type.FullName)] enum."
                            }
                            continue
                        }
                        { $_.DeclaredMethods.Name.Contains('TryParse') } {
                            # Boolean and Int32
                            $var = $null

                            if (-not ($property.Type::TryParse($adtConfig.Email.$($property.Name), [ref]$var))) {
                                throw "Invalid ADT config. The property [$($property.Name)] with value [$($adtConfig.Email.$($property.Name))] is invalid. It must be a valid [$($property.Type.FullName)] value."
                            }
                            continue
                        }
                        { $_.DeclaredMethods.Name.Contains('Parse') } {
                            try {
                                $null = $property.Type::Parse($adtConfig.Email.$($property.Name))
                            } catch {
                                throw "Invalid ADT config. The property [$($property.Name)] with value [$($adtConfig.Email.$($property.Name))] is invalid. It must be a valid [$($property.Type.FullName)] value."
                            }
                            continue
                        }
                        { default } {
                            throw "The type [$($property.Type.FullName)] is not supported by [Test-ADTEmailConfig]."
                        }
                    }
                }

                return $true
            } catch {
                # Re-writing the ErrorRecord with Write-Error ensures the correct PositionMessage is used.
                Write-Error -ErrorRecord $_
            }
        } catch {
            # Process the caught error, log it and throw depending on the specified ErrorAction.
            Invoke-ADTFunctionErrorHandler -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -ErrorRecord $_
        }
    } end {
        # Finalize function.
        Complete-ADTFunction -Cmdlet $PSCmdlet
    }
}