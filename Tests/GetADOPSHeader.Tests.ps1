param(
    $PSM1 = "$PSScriptRoot\..\Source\ADOPS.psm1"
)

BeforeAll {
    Remove-Module ADOPS -Force -ErrorAction SilentlyContinue
    Import-Module $PSM1 -Force
}

Describe 'GetADOPSHeader' {
    BeforeAll {
        InModuleScope -ModuleName ADOPS {
            $Script:ADOPSCredentials = @{
                'org1' = @{
                    Credential = [pscredential]::new('DummyUser1',(ConvertTo-SecureString -String 'DummyPassword1' -AsPlainText -Force))
                    Default = $false
                }
                'org2' = @{
                    Credential = [pscredential]::new('DummyUser2',(ConvertTo-SecureString -String 'DummyPassword2' -AsPlainText -Force))
                    Default = $true
                }
            }
        }
    }

    Context 'Parameters' {
        $TestCases = @(
            @{
                Name = 'Organization'
                Mandatory = $false
                Type = 'string'
            }
        )

        It 'Should have parameter <_.Name>' -TestCases $TestCases  {
            Get-Command GetADOPSHeader | Should -HaveParameter $_.Name -Mandatory:$_.Mandatory -Type $_.Type
        }
    }

    Context 'Given no input, should return the default connection' {
        It 'Should return credential value of default organization, org2' {
            InModuleScope -ModuleName ADOPS {
                (GetADOPSHeader).Header.Authorization | Should -BeLike "basic*"
            }
        }
        It 'Token should contain organization name' {
            InModuleScope -ModuleName ADOPS {
                (GetADOPSHeader).Organization | Should -Be 'org2'
            }
        }
    }

    Context 'Given an organization as input, should return that organization' {
        It 'Should return credential value of default organization, org1' {
            InModuleScope -ModuleName ADOPS {
                (GetADOPSHeader -Organization 'org1').Header.Authorization | Should -BeLike "basic*"
            }
        }
        It 'Token should contain organization name' {
            InModuleScope -ModuleName ADOPS {
                (GetADOPSHeader -Organization 'org1').Organization | Should -Be 'org1'
            }
        }
    }

    Context 'Bugfixes' {
        it '#149 - Add clear error message if user runs commands without first connecting' {
            InModuleScope -ModuleName ADOPS {
                Remove-Variable ADOPSCredentials -Scope script
                {GetADOPSHeader} | Should -Throw -ExpectedMessage 'No ADOPS credentials found. Have you used Connect-ADOPS to log in?'
            }
        }
    }
}

