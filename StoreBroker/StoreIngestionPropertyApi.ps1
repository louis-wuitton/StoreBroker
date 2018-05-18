Add-Type -TypeDefinition @"
   public enum StoreBrokerProductPropertyProperty
   {
       resourceType,
       revisionToken
   }
"@

function Get-ProductProperty
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [string] $SubmissionId,

        [string] $PropertyId,

        [switch] $SinglePage,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    $singleQuery = (-not [String]::IsNullOrWhiteSpace($PropertyId))
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::PropertyId = $PropertyId
        [StoreBrokerTelemetryProperty]::SingleQuery = $singleQuery
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    $params = @{
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Get-ProductProperty"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    if ($singleQuery)
    {
        $params["UriFragment"] = "products/$ProductId/properties/$PropertyId`?" + ($getParams -join '&')
        $params["Method" ] = 'Get'
        $params["Description"] =  "Getting property $PropertyId for $ProductId"

        return Invoke-SBRestMethod @params
    }
    else
    {
        $params["UriFragment"] = "products/$ProductId/properties`?" + ($getParams -join '&')
        $params["Description"] =  "Getting properties for $ProductId"
        $params["SinglePage" ] = $SinglePage

        return Invoke-SBRestMethodMultipleResult @params
    }
}

function New-ProductProperty
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [string] $SubmissionId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('ApplicationProperty', 'AddonProperty', 'BundleProperty', 'AvatarProperty', 'IoTProperty', 'AzureProperty')]
        [string] $Type,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
        [StoreBrokerTelemetryProperty]::ResourceType = $Type
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}

        # TODO: Not sure what I should really be doing here.
        if (-not [String]::IsNullOrWhiteSpace($Type))
        {
            $hashBody[[StoreBrokerProductPropertyProperty]::resourceType] = $Type
        }
    }

    $body = Get-JsonBody -InputObject $hashBody
    Write-Log -Message "Body: $body" -Level Verbose

    $params = @{
        "UriFragment" = "products/$ProductId/properties`?" + ($getParams -join '&')
        "Method" = 'Post'
        "Description" = "Creating new property for $ProductId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "New-ProductProperty"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return Invoke-SBRestMethod @params
}

function Set-ProductProperty
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $PropertyId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('ApplicationProperty', 'AddonProperty', 'BundleProperty', 'AvatarProperty', 'IoTProperty', 'AzureProperty')]
        [string] $Type,

        [Parameter(Mandatory)]
        [string] $RevisionToken,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    if ($null -ne $Object)
    {
        $PropertyId = $Object.id
    }

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::PropertyId = $PropertyId
        [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
        [StoreBrokerTelemetryProperty]::ResourceType = $Type
        [StoreBrokerTelemetryProperty]::RevisionToken = $RevisionToken
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerProductPropertyProperty]::revisionToken] = $RevisionToken

        if (-not [String]::IsNullOrWhiteSpace($Type))
        {
            # TODO: Not sure what I should really be doing here.
            $hashBody[[StoreBrokerProductPropertyProperty]::resourceType] = $Type
        }
    }

    $body = Get-JsonBody -InputObject $hashBody
    Write-Log -Message "Body: $body" -Level Verbose

    $params = @{
        "UriFragment" = "products/$ProductId/properties/$PropertyId`?" + ($getParams -join '&')
        "Method" = 'Put'
        "Description" = "Updating property $PropertyId for $ProductId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Set-ProductProperty"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return Invoke-SBRestMethod @params
}

function Update-ProductProperty
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [PSCustomObject] $SubmissionData,

        [switch] $UpdateCategoryFromSubmissionData,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $providedSubmissionData = ($null -ne $PSBoundParameters['SubmissionData'])
    if ($providedSubmissionData -and $UpdateCategoryFromSubmissionData)
    {
        $message = 'Cannot request -UpdateCategoryFromSubmissionData without providing SubmissionData.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    if (-not $UpdateCategoryFromSubmissionData)
    {
        Write-Log -Message 'No modification parameters provided.  Nothing to do.' -Level Verbose
        return
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $params = @{
        'ProductId' = $ProductId
        'SubmissionId' = $SubmissionId
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    $property = Get-Property @params

    if ($UpdateCategoryFromSubmissionData)
    {
        [System.Collections.ArrayList]$split = $SubmissionData.applicationCategory -split '_'
        $category = $split[0]
        $split.RemoveAt(0)
        $subCategory = $split
        if ($subCategory.Count -eq 0)
        {
            $null = $subCategory.Add('NotSet')
        }

        $property.category = $category
        $property.subcategories = (ConvertTo-Json -InputObject $subCategory)
    }

    $null = Set-Property @params -Object $property

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ProvidedSubmissionData = ($null -ne $SubmissionData)
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Update-ProductProperty -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}
