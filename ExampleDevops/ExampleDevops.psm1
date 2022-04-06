function Remove-Image {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $SubscriptionId,

        [Parameter(Mandatory)]
        [string]
        $ResourceGroup,

        [Parameter(Mandatory)]
        [string]
        $ImageName
    )

    $null = Select-AzSubscription -SubscriptionId $SubscriptionId
    try
    {
        $imageExists = Get-AzImage -ResourceGroupName $ResourceGroup -ImageName $ImageName -ErrorAction Stop
    }
    catch
    {
        Write-Information $_.Exception.Message -InformationAction Continue
    }
    if ($imageExists)
    {
        Write-Information "Image $ImageName exists in $ResourceGroup, removing existing image." -InformationAction Continue
        Remove-AzImage -ResourceGroupName $ResourceGroup -ImageName $ImageName -Force -ErrorAction Stop
    }
}

function Write-Message {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Message,
        
        [Parameter(Mandatory)]
        [ValidateSet("Info","Verbose","Error")]
        [string]
        $MessageType
    )

    Switch ($MessageType)
    {
        "Info" {
            Write-Information -Message $Message -InformationAction Continue
        }

        "Verbose" {
            Write-Verbose -Message $Message
        }

        "Error" {
            Write-Error -Message $Message -ErrorAction Continue
        }
    }
}

# function removeStuff
# {
#     [CmdletBinding()]
#     param (
#         [Parameter()]
#         [array]
#         $ResourceGroups,
        
#         [Parameter()]
#         [string]
#         $ResourcePrefix
#     )

#     foreach ($rg in $ResourceGroups)
#     {
#         $img = Get-AzResource -ResourceGroupName $rg

#         if (-Not [string]::IsNullOrEmpty($ResourcePrefix))
#         {
#             $img = $img.Where({ $PSItem.Name -ilike ($ResourcePrefix + '*') })
#         }

#         if (-Not [string]::IsNullOrEmpty($img))
#         {
#             $img | Remove-AzResource -Force -ErrorAction SilentlyContinue
#         }

#         $blah = $img | Get-AzResource -ErrorAction SilentlyContinue

#         if ($blah.Count -ge 1)
#         {
#             return $false
#         }
#     }
#     Write-Output 'i love pester'
# }