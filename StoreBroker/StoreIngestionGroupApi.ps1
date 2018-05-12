Add-Type -TypeDefinition @"
   public enum StoreBrokerGroupProperty
   {
       name,
       resourceType,
       revisionToken,
       type
   }
"@

function Get-Group
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string] $GroupId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $SinglePage,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $singleQuery = (-not [String]::IsNullOrWhiteSpace($GroupId))
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::SingleQuery = $singleQuery
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Get-Group"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    if ($singleQuery)
    {
        $params["UriFragment"] = "groups/$GroupId"
        $params["Method" ] = 'Get'
        $params["Description"] = "Getting group $GroupId"

        return Invoke-SBRestMethod @params
    }
    else
    {
        $params["UriFragment"] = "groups"
        $params["Description"] = "Getting all groups"
        $params["SinglePage" ] = $SinglePage

        return Invoke-SBRestMethodMultipleResult @params
    }
}

# NOTE: Only usable by Azure at present time.
function New-Group
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $Name,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $Type,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
            [StoreBrokerTelemetryProperty]::Type = $Type
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Test-ResourceType -Object $Object -ResourceType [StoreBrokerResourceType]::Group

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerGroupProperty]::resourceType] = [StoreBrokerResourceType]::Group
        $hashBody[[StoreBrokerGroupProperty]::type] = $Type
        $hashBody[[StoreBrokerGroupProperty]::name] = $Name
    }

    $body = Get-JsonBody -InputObject $hashBody
    Write-Log -Message "Body: $body" -Level Verbose

    $params = @{
        "UriFragment" = "groups"
        "Method" = 'Post'
        "Description" = "Creating new group"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "New-Group"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return Invoke-SBRestMethod @params
}

# NOTE: Only usable by Azure at present time.
function Set-Group
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(Mandatory)]
        [string] $GroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $Name,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $Type,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $RevisionToken,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
        [StoreBrokerTelemetryProperty]::Type = $Type
        [StoreBrokerTelemetryProperty]::RevisionToken = $RevisionToken
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Test-ResourceType -Object $Object -ResourceType [StoreBrokerResourceType]::Group

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerGroupProperty]::resourceType] = [StoreBrokerResourceType]::Group
        $hashBody[[StoreBrokerGroupProperty]::revisionToken] = $RevisionToken
        $hashBody[[StoreBrokerGroupProperty]::type] = $Type
        $hashBody[[StoreBrokerGroupProperty]::name] = $Name
    }

    $body = Get-JsonBody -InputObject $hashBody
    Write-Log -Message "Body: $body" -Level Verbose

    $params = @{
        "UriFragment" = "groups/$GroupId"
        "Method" = 'Put'
        "Description" = "Updating group $GroupId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Set-Group"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return Invoke-SBRestMethod @params
}
