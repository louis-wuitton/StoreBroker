function Get-Product
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Alias('ExternalId')]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an ProductId instead of an AppId." }})]
        [string] $AppId,

        [ValidateSet('Application', 'AvatarItem', 'Bundle', 'Consumable', 'ManagedConsumable', 'Durable', 'DurableWithBits', 'Subscription', 'SeasonPass', 'InternetOfThings')]
        [string[]] $Type = @('Application', 'AvatarItem', 'Bundle', 'InternetOfThings'),

        [string] $AccessToken = "",

        [switch] $GetAll,

        [switch] $NoStatus
    )
}

function Get-ProductInternal
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Alias('ExternalId')]
        [ValidateScript({if ($_.Length -eq 12) { $true } else { throw "It looks like you supplied an ProductId instead of an AppId." }})]
        [string] $AppId,

        [ValidateSet('Application', 'AvatarItem', 'Bundle', 'Consumable', 'ManagedConsumable', 'Durable', 'DurableWithBits', 'Subscription', 'SeasonPass', 'InternetOfThings')]
        [string[]] $Type = @('Application', 'AvatarItem', 'Bundle', 'InternetOfThings'),

        [string] $AccessToken = "",

        [switch] $GetAll,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
        }

        $description = "Getting information for all products"

        $uriFragment = 'products?'

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($AppId))
        {
            $getParams += "externalId=$AppId"
            $description = "Getting product information for $AppId"
        }

        $typesString = $Type -join ","
        if (-not [String]::IsNullOrWhiteSpace($typesString))
        {
            $getParams +=  "types=$typesString"
        }

        $params = @{
            "UriFragment" = 'products?' + ($getParams -join '&')
            "Description" = $description
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-Product"
            "TelemetryProperties" = $telemetryProperties
            "GetAll" = $GetAll
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethodMultipleResult2 @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function Remove-Product
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
    }

    $params = @{
        "UriFragment" = "products/$ProductId"
        "Method" = "Delete"
        "Description" = "Deleting product: $ProductId"
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Remove-Product"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    $null = Invoke-SBRestMethod @params
}

function Get-ProductPackageIdentity
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/packageidentity"
            "Method" = "Get"
            "Description" = "Getting package identity for product: $ProductId"
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ProductPackageIdentity"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethod @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function Get-ProductStoreLink
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/storelink"
            "Method" = "Get"
            "Description" = "Getting store link for product: $ProductId"
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ProductStoreLink"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethod @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function Get-ProductRelated
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [ValidateSet('AddOnChild', 'AddOnParent', 'AvailableInBundle', 'SellableBy')]
        [string] $RelationshipType,

        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/storelink"
            "Method" = "Get"
            "Description" = "Getting store link for product: $ProductId"
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ProductStoreLink"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethod @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}
