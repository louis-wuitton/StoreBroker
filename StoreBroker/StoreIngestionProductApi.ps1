function Get-Product
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Known")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName="Known")]
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(ParameterSetName="Search")]
        [Alias('ExternalId')]
        [ValidateScript({if ($_.Length -eq 12) { $true } else { throw "It looks like you supplied an ProductId instead of an AppId." }})]
        [string] $AppId,

        [Parameter(ParameterSetName="Search")]
        [ValidateSet('Application', 'AvatarItem', 'Bundle', 'Consumable', 'ManagedConsumable', 'Durable', 'DurableWithBits', 'Subscription', 'SeasonPass', 'InternetOfThings')]
        [string[]] $Type = @('Application', 'AvatarItem', 'Bundle', 'InternetOfThings'),

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $SinglePage,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    if ($PSCmdlet.ParameterSetName -eq "Known")
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $params = @{
            "UriFragment" = "products/$ProductId"
            "Method" = "Get"
            "Description" = "Getting product: $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-Product"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethod @params
    }
    else
    {
        $params = @{
            "AppId" = $AppId
            "Type" = $Type
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "SinglePage" = $SinglePage
            "NoStatus" = $NoStatus
        }

        return Get-Products @params
    }
}

function Get-Products
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Alias('ExternalId')]
        [ValidateScript({if ($_.Length -eq 12) { $true } else { throw "It looks like you supplied an ProductId instead of an AppId." }})]
        [string] $AppId,

        [ValidateSet('Application', 'AvatarItem', 'Bundle', 'Consumable', 'ManagedConsumable', 'Durable', 'DurableWithBits', 'Subscription', 'SeasonPass', 'InternetOfThings')]
        [string[]] $Type = @('Application', 'AvatarItem', 'Bundle', 'InternetOfThings'),

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $SinglePage,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $description = "Getting information for all products"

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
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-Products"
            "TelemetryProperties" = $telemetryProperties
            "SinglePage" = $SinglePage
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethodMultipleResult @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function New-Product
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject[]] $Object,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [ValidateSet('Application', 'AvatarItem', 'Bundle', 'Consumable', 'ManagedConsumable', 'Durable', 'DurableWithBits', 'Subscription', 'SeasonPass', 'InternetOfThings')]
        [string] $Type,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    # Convert the input into a Json body.
    $hashBody = @{}
    $hashBody[[StoreBrokerPropertyNames]::id] = $ProductId
    $hashBody[[StoreBrokerPropertyNames]::resourceType] = $Type
    $hashBody[[StoreBrokerPropertyNames]::name] = $Name

    $body = $hashBody | ConvertTo-Json

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::Name = $Name
        [StoreBrokerTelemetryProperty]::ResourceType = $Type
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/"
        "Method" = "Post"
        "Description" = "Creating a new product called: $Name"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "New-Product"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Remove-Product
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias("Delete-Product")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId"
        "Method" = "Delete"
        "Description" = "Deleting product: $ProductId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
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
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/packageIdentity"
            "Method" = "Get"
            "Description" = "Getting package identity for product: $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
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
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/storelink"
            "Method" = "Get"
            "Description" = "Getting store link for product: $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
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
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [ValidateSet('AddOnChild', 'AddOnParent', 'AvailableInBundle', 'SellableBy')]
        [string] $RelationshipType,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $SinglePage,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/related"
            "Description" = "Getting related products for product: $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ProductRelated"
            "TelemetryProperties" = $telemetryProperties
            "SinglePage" = $SinglePage
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethodMultipleResult @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}
