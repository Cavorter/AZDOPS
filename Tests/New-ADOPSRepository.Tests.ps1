Remove-Module ADOPS -Force -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\..\Source\ADOPS -Force

Describe 'New-ADOPSRepository' {
    Context 'Parameters' {
        $TestCases = @(
            @{
                Name = 'Organization'
                Mandatory = $false
                Type = 'string'
            },
            @{
                Name = 'Project'
                Mandatory = $true
                Type = 'string'
            },
            @{
                Name = 'name'
                Mandatory = $true
                Type = 'string'
            }
        )
    
        It 'Should have parameter <_.Name>' -TestCases $TestCases  {
            Get-Command New-ADOPSRepository | Should -HaveParameter $_.Name -Mandatory:$_.Mandatory -Type $_.Type
        }
    }

    Context 'Running command' {
        BeforeAll {
            InModuleScope -ModuleName ADOPS {
                Mock -CommandName GetADOPSHeader -ModuleName ADOPS -MockWith {
                    @{
                        Header       = @{
                            'Authorization' = 'Basic Base64=='
                        }
                        Organization = $Organization
                    }
                } -ParameterFilter { $Organization }
                Mock -CommandName GetADOPSHeader -ModuleName ADOPS -MockWith {
                    @{
                        Header       = @{
                            'Authorization' = 'Basic Base64=='
                        }
                        Organization = 'DummyOrg'
                    }
                }
                
                Mock -CommandName InvokeADOPSRestMethod  -ModuleName ADOPS -MockWith {
                    return $InvokeSplat
                }

                Mock Get-ADOPSProject -MockWith {
                    return @'
                    {
                        "id": "34f7babc-b656-4d13-bf24-bba1782d88fe",
                        "name": "DummyProject",
                        "description": "DummyProject",
                        "url": "https://dev.azure.com/DummyOrg/_apis/projects/34f7babc-b656-4d13-bf24-bba1782d88fe",
                        "state": "wellFormed",
                        "revision": 1,
                        "visibility": "private",
                    }
'@ | ConvertFrom-Json
                } -ParameterFilter { $Name -eq 'MyRepoName' }
            }
        }

        It 'If organization is given, in should call GetADOPSHeader with organization name' {
            $r = New-ADOPSRepository -Organization 'DummyOrg' -Project 'DummyProj' -Name 'RepoName'
            Should -Invoke -CommandName GetADOPSHeader -ModuleName ADOPS -ParameterFilter { $Organization }
        }
        It 'If organization is not given, in should call GetADOPSHeader with no parameters' {
            $r = New-ADOPSRepository -Project 'DummyProj' -Name 'RepoName'
            Should -Invoke -CommandName GetADOPSHeader -ModuleName ADOPS
        }
        
        It 'Invoke should be correct, Verifying method "Post"' {
            $r = New-ADOPSRepository -Organization 'DummyOrg' -Project 'DummyProj' -Name 'RepoName'
            $r.Method | Should -Be 'Post'
        }
        It 'Invoke should be correct, Verifying URI using RepositoryId' {
            $r = New-ADOPSRepository -Organization 'DummyOrg' -Project 'DummyProj' -Name 'RepoName'
            $r.URI | Should -Be 'https://dev.azure.com/DummyOrg/_apis/git/repositories?api-version=7.1-preview.1'
        }
        It 'Invoke should be correct, Verifying body' {
            $res = '{"name":"MyRepoName","project":{"id":"34f7babc-b656-4d13-bf24-bba1782d88fe"}}'
            $r = New-ADOPSRepository -Project 'DummyProject' -Name 'MyRepoName'
            $r.body | Should -Be $res
        }
        It 'Invoke should be correct, Verifying Organization' {
            $r = New-ADOPSRepository -Organization 'DummyOrg' -Project 'DummyProj' -Name 'RepoName'
            $r.Organization | Should -Be 'DummyOrg'
        }
    }
}