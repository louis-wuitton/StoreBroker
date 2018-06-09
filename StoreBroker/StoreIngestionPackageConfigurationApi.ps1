Add-Type -TypeDefinition @"
   public enum StoreBrokerPackageConfigurationProperty
   {
       mandatoryUpdate,
       resourceType,
       revisionToken
   }
"@

Add-Type -TypeDefinition @"
   public enum StoreBrokerPackageConfigurationMandatoryUpdateProperty
   {
       effectiveDatetime,
       isSpecifiedByDeveloper
   }
"@

function Get-ProductPackageConfiguration
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $PackageConfigurationId,

        [string] $FeatureGroupId,

        [switch] $SinglePage,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    try
    {
        $singleQuery = (-not [String]::IsNullOrWhiteSpace($PackageConfigurationId))
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::PackageConfigurationId = $PackageConfigurationId
            [StoreBrokerTelemetryProperty]::SingleQuery = $singleQuery
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        if (-not [String]::IsNullOrWhiteSpace($FeatureGroupId))
        {
            $getParams += "featureGroupId=$FeatureGroupId"
        }

        $params = @{
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ProductPackageConfiguration"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        if ($singleQuery)
        {
            $params["UriFragment"] = "products/$ProductId/packageConfigurations/$PackageConfigurationId`?" + ($getParams -join '&')
            $params["Method" ] = 'Get'
            $params["Description"] =  "Getting package configuration $PackageConfigurationId for $ProductId"

            return Invoke-SBRestMethod @params
        }
        else
        {
            $params["UriFragment"] = "products/$ProductId/packageConfigurations`?" + ($getParams -join '&')
            $params["Description"] =  "Getting package configurations for $ProductId"
            $params["SinglePage" ] = $SinglePage

            return Invoke-SBRestMethodMultipleResult @params
        }
    }
    catch
    {
        throw
    }
}

function New-ProductPackageConfiguration
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

        [string] $FeatureGroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(ParameterSetName="Individual")]
        [switch] $IsMandatoryUpdate,

        [Parameter(ParameterSetName="Individual")]
        [DateTime] $MandatoryUpdateEffectiveDate,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        if (-not [String]::IsNullOrWhiteSpace($FeatureGroupId))
        {
            $getParams += "featureGroupId=$FeatureGroupId"
        }

        Test-ResourceType -Object $Object -ResourceType ([StoreBrokerResourceType]::PackageConfiguration)

        $hashBody = $Object
        if ($null -eq $hashBody)
        {
            # Convert the input into a Json body.
            $hashBody = @{}
            $hashBody[[StoreBrokerPackageConfigurationProperty]::resourceType] = [StoreBrokerResourceType]::PackageConfiguration

            if (($null -ne $PSBoundParameters['IsMandatoryUpdate']) -or ($null -ne $PSBoundParameters['MandatoryUpdateEffectiveDate']))
            {
                $hashBody[[StoreBrokerListingProperty]::mandatoryUpdate] = @{}

                # We only set the value if the user explicitly provided a value for this parameter
                # (so for $false, they'd have to pass in -IsMandatoryUpdate:$false).
                # Otherwise, there'd be no way to know when the user wants to simply keep the
                # existing value.
                if ($null -ne $PSBoundParameters['IsMandatoryUpdate'])
                {
                    $hashBody[[StoreBrokerListingProperty]::mandatoryUpdate][[StoreBrokerPackageConfigurationMandatoryUpdateProperty]::isSpecifiedByDeveloper] = $IsMandatoryUpdate
                    $telemetryProperties[[StoreBrokerTelemetryProperty]::IsMandatoryUpdate] = $IsMandatoryUpdate
                }

                if ($null -ne $PSBoundParameters['MandatoryUpdateEffectiveDate'])
                {
                    $hashBody[[StoreBrokerListingProperty]::mandatoryUpdate][[StoreBrokerPackageConfigurationMandatoryUpdateProperty]::effectiveDatetime] = $MandatoryUpdateEffectiveDate.ToUniversalTime().ToString('o')
                }
            }
        }

        $body = Get-JsonBody -InputObject $hashBody
        Write-Log -Message "Body: $body" -Level Verbose

        $params = @{
            "UriFragment" = "products/$ProductId/packageConfigurations`?" + ($getParams -join '&')
            "Method" = 'Post'
            "Description" = "Creating new package configuration for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "New-ProductPackageConfiguration"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethod @params
    }
    catch
    {
        throw
    }
}

function Set-ProductPackageConfiguration
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

        [Parameter(Mandatory)]
        [string] $PackageConfigurationId,

        [string] $FeatureGroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(ParameterSetName="Individual")]
        [switch] $IsMandatoryUpdate,

        [Parameter(ParameterSetName="Individual")]
        [DateTime] $MandatoryUpdateEffectiveDate,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $RevisionToken,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::PackageConfigurationId = $PackageConfigurationId
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
            [StoreBrokerTelemetryProperty]::RevisionToken = $RevisionToken
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        if (-not [String]::IsNullOrWhiteSpace($FeatureGroupId))
        {
            $getParams += "featureGroupId=$FeatureGroupId"
        }

        Test-ResourceType -Object $Object -ResourceType ([StoreBrokerResourceType]::PackageFlight)

        $hashBody = $Object
        if ($null -eq $hashBody)
        {
            # Convert the input into a Json body.
            $hashBody = @{}
            $hashBody[[StoreBrokerPackageConfigurationProperty]::resourceType] = [StoreBrokerResourceType]::PackageConfiguration
            $hashBody[[StoreBrokerPackageConfigurationProperty]::revisionToken] = $RevisionToken

            if (($null -ne $PSBoundParameters['IsMandatoryUpdate']) -or ($null -ne $PSBoundParameters['MandatoryUpdateEffectiveDate']))
            {
                $hashBody[[StoreBrokerListingProperty]::mandatoryUpdate] = @{}

                # We only set the value if the user explicitly provided a value for this parameter
                # (so for $false, they'd have to pass in -IsMandatoryUpdate:$false).
                # Otherwise, there'd be no way to know when the user wants to simply keep the
                # existing value.
                if ($null -ne $PSBoundParameters['IsMandatoryUpdate'])
                {
                    $hashBody[[StoreBrokerListingProperty]::mandatoryUpdate][[StoreBrokerPackageConfigurationMandatoryUpdateProperty]::isSpecifiedByDeveloper] = $IsMandatoryUpdate
                    $telemetryProperties[[StoreBrokerTelemetryProperty]::IsMandatoryUpdate] = $IsMandatoryUpdate
                }

                if ($null -ne $PSBoundParameters['MandatoryUpdateEffectiveDate'])
                {
                    $hashBody[[StoreBrokerListingProperty]::mandatoryUpdate][[StoreBrokerPackageConfigurationMandatoryUpdateProperty]::effectiveDatetime] = $MandatoryUpdateEffectiveDate.ToUniversalTime().ToString('o')
                }
            }
        }

        $body = Get-JsonBody -InputObject $hashBody
        Write-Log -Message "Body: $body" -Level Verbose

        $params = @{
            "UriFragment" = "products/$ProductId/packageConfigurations/$PackageConfigurationId`?" + ($getParams -join '&')
            "Method" = 'Put'
            "Description" = "Updating package configuration $PackageConfigurationId for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Set-ProductPackageConfiguration"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethod @params
    }
    catch
    {
        throw
    }
}

function Update-ProductPackageConfiguration
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [switch] $IsMandatoryUpdate,

        [DateTime] $MandatoryUpdateEffectiveDate,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    try
    {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        $params = @{
            'ProductId' = $ProductId
            'SubmissionId' = $SubmissionId
            'ClientRequestId' = $ClientRequestId
            'CorrelationId' = $CorrelationId
            'AccessToken' = $AccessToken
            'NoStatus' = $NoStatus
        }

        $configuration = Get-ProductPackageConfiguration @params

        if ($null -ne $PSBoundParameters['IsMandatoryUpdate'])
        {
            # TODO: Ensure that MandatoryUpdate exists as a property, then set the right sub-property
        }

        if ($null -ne $PSBoundParameters['MandatoryUpdateEffectiveDate'])
        {
            # TODO: Ensure that MandatoryUpdate exists as a property, then set the right sub-property
        }

        $null = Set-ProductPackageConfiguration @params -Object $configuration

        # Record the telemetry for this event.
        $stopwatch.Stop()
        $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        Set-TelemetryEvent -EventName Update-ProductPackageConfiguration -Properties $telemetryProperties -Metrics $telemetryMetrics
        return
    }
    catch
    {
        throw
    }
}
