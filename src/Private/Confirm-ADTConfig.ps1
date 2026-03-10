function Confirm-ADTConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [Hashtable]$Config,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [Hashtable]$ConfigTemplate
    )

    begin {
        Initialize-ADTFunction -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    } process {
        try {
            try {
                foreach ($section in $ConfigTemplate.GetEnumerator()) {
                    if (-not $Config.ContainsKey($section.Key)) {
                        continue
                    }

                    if ($section.Value -is [Hashtable]) {
                        & $MyInvocation.MyCommand -Config $Config.$($section.Key) -ConfigTemplate $section.Value
                        continue
                    }

                    switch ($section.Value) {
                        { $_ -eq [String] } {
                            continue
                        }
                        { ($_ -eq [System.Net.Mail.MailAddress]) -or ($_ -eq [System.Net.Mail.MailAddress[]]) } {
                            foreach ($address in $Config.$($section.Key)) {
                                try {
                                    [System.Net.Mail.MailAddress]::new($address)
                                } catch {
                                    throw "Invalid ADT config. The email address [$address] in the [$($section.Key)] property is invalid."
                                }
                            }
                            continue
                        }
                        { $_ -eq [System.IO.Path] } {
                            if (-not (Test-Path -LiteralPath $Config.$($section.Key) -IsValid)) {
                                throw "Invalid ADT config. The property [$($section.Key)] with value [$($Config.$($section.Key))] is invalid. It must be a valid file/folder path."
                            }
                            continue
                        }
                        { $_.BaseType -eq [Enum] } {
                            # System.Net.Mail.MailPriority
                            try {
                                $null = [Enum]::Parse($section.Value, $Config.$($section.Key), $true)
                            } catch {
                                throw "Invalid ADT config. The property [$($section.Key)] with value [$($Config.$($section.Key))] is invalid. It must be a member of the [$($section.Value.FullName)] enum."
                            }
                            continue
                        }
                        { $_.DeclaredMethods.Name.Contains('TryParse') } {
                            # Boolean and UInt16
                            $var = $null

                            if (-not ($section.Value::TryParse($Config.$($section.Key), [ref]$var))) {
                                throw "Invalid ADT config. The property [$($section.Key)] with value [$($Config.$($section.Key))] is invalid. It must be a valid [$($section.Value.FullName)] value."
                            }
                            continue
                        }
                        { $_.DeclaredMethods.Name.Contains('Parse') } {
                            try {
                                $null = $section.Value::Parse($Config.$($section.Key))
                            } catch {
                                throw "Invalid ADT config. The property [$($section.Key)] with value [$($Config.$($section.Key))] is invalid. It must be a valid [$($section.Value.FullName)] value."
                            }
                            continue
                        }
                        { default } {
                            throw "The type [$($section.Value.FullName)] is not supported by [$($MyInvocation.MyCommand.Name)]."
                        }
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