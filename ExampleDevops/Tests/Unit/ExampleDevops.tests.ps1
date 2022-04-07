BeforeDiscovery {
    $PesterPreference = [PesterConfiguration]::Default
    $PesterPreference.Output.Verbosity = 'Detailed'
    $PesterPreference.CodeCoverage.Enabled = $true

    # Module imports are here to accomodate InModuleScope ... scope.
    $global:moduleName = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot)) -Leaf
    $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module -FullyQualifiedName (Join-Path -Path $script:moduleRoot -ChildPath "$($global:moduleName).psd1") -Force
}

Describe 'Function Remove-Image' {

    BeforeAll {

        # Mock az cli if needed, but why - just use PS?
        # function az {}

        $params = @{
            ResourceGroup  = 'foo'
            ImageName      = 'bar'
            SubscriptionId = 'baz'
        }

        Mock -CommandName Select-AzSubscription -ModuleName $global:moduleName #-MockWith { 'foo' }
        Mock -CommandName Write-Message -ModuleName $global:moduleName
    }

    Context 'Image does not exist' {

        BeforeAll {

            Mock -CommandName Get-AzImage -ModuleName $global:moduleName -MockWith {
                $errorDetails = '{"code": 1, "message": "NotFound", "more_info": "", "status": 404}'
                $statusCode = 404
                $response = New-Object System.Net.Http.HttpResponseMessage $statusCode
                $exception = New-Object Microsoft.PowerShell.Commands.HttpResponseException "$statusCode ($($response.ReasonPhrase))", $response
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
                $errorID = 'Microsoft.Azure.Commands.Compute.Automation.GetAzureRmImage'
                $targetObject = $null
                $errorRecord = New-Object Management.Automation.ErrorRecord $exception, $errorID, $errorCategory, $targetObject
                $errorRecord.ErrorDetails = $errorDetails
                Throw $errorRecord
            }

            Remove-Image @params
        }

        It 'Does not remove the image' {

            Should -Invoke Select-AzSubscription -Times 1 -Scope 'Context' -Exactly -ModuleName $global:moduleName
            Should -Invoke Get-AzImage -Times 1 -Scope 'Context' -Exactly -ModuleName $global:moduleName
            Should -Invoke Write-Message -Times 1 -Scope 'Context' -Exactly -ModuleName $global:moduleName
        }
    }

    Context 'Image does exist' {

        BeforeAll {

            Mock -CommandName Remove-AzImage -ModuleName $global:moduleName
            Mock -CommandName Get-AzImage -ModuleName $global:moduleName -MockWith {
                New-Object -TypeName Microsoft.Azure.Commands.Compute.Automation.Models.PSImage
            }

            Remove-Image @params
        }

        It 'Removes the image' {

            Should -Invoke Remove-AzImage -Times 1 -Scope 'Context' -Exactly -ModuleName $global:moduleName
            Should -Invoke Get-AzImage -Times 1 -Scope 'Context' -Exactly -ModuleName $global:moduleName
            Should -Invoke Select-AzSubscription -Times 1 -Scope 'Context' -Exactly -ModuleName $global:moduleName
            Should -Invoke Write-Message -Times 1 -Scope 'Context' -Exactly -ModuleName $global:moduleName
        }
    }
}

InModuleScope $global:moduleName {

    Describe 'Private Function Write-Message' {

        BeforeDiscovery {
            $writeMessageCases = @(
                @{
                    MessageType    = 'Info'
                    Message        = 'This is an info message'
                    ExpectedAction = 'Write-Information'
                }
                @{
                    MessageType    = 'Verbose'
                    Message        = 'This is a very unimportant message unless you are debugging'
                    ExpectedAction = 'Write-Verbose'
                }
                @{
                    MessageType    = 'Error'
                    Message        = 'Never gonna gi-ive you up...'
                    ExpectedAction = 'Write-Error'
                }
            )
        }

        It 'Returns <MessageType> message' -ForEach $writeMessageCases {

            Mock -CommandName $ExpectedAction

            Write-Message -Message $Message -MessageType $MessageType

            Should -Invoke $ExpectedAction -Times 1 -Exactly -ParameterFilter { $Message -eq $Message }
        }
    }
}
