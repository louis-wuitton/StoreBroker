Add-Type -TypeDefinition @"
   public enum StoreBrokerListingProperty
   {
       description,
       devStudio,
       features,
       keywords,
       languageCode,
       licenseTerm,
       minimumHardware,
       recommendedHardware,
       releaseNotes,
       resourceType,
       revisionToken,
       shortDescription,
       shortTitle,
       shouldOverridePackageLogos,
       title,
       trademark,
       voiceTitle
   }
"@

function Get-Listing
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $FeatureGroupId,

        [switch] $SinglePage,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    $singleQuery = (-not [String]::IsNullOrWhiteSpace($LanguageCode))
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
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
        "TelemetryEventName" = "Get-Listing"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    if ($singleQuery)
    {
        $params["UriFragment"] = "products/$ProductId/listings/$LanguageCode`?" + ($getParams -join '&')
        $params["Method" ] = 'Get'
        $params["Description"] =  "Getting $LanguageCode listing for $ProductId"

        return Invoke-SBRestMethod @params
    }
    else
    {
        $params["UriFragment"] = "products/$ProductId/listings`?" + ($getParams -join '&')
        $params["Description"] =  "Getting listings for $ProductId"
        $params["SinglePage" ] = $SinglePage

        return Invoke-SBRestMethodMultipleResult @params
    }
}

function New-Listing
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
        [Alias('LangCode')]
        [string] $LanguageCode,

        [string] $FeatureGroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(ParameterSetName="Individual")]
        [string] $Title,

        [Parameter(ParameterSetName="Individual")]
        [string] $ShortTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $VoiceTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $ReleaseNotes,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $Keywords,

        [Parameter(ParameterSetName="Individual")]
        [string] $Trademark,

        [Parameter(ParameterSetName="Individual")]
        [string] $LicenseTerm,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $Features,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $MinimumHardware,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $RecommendedHardware,

        [Parameter(ParameterSetName="Individual")]
        [string] $DevStudio,

        [Parameter(ParameterSetName="Individual")]
        [switch] $ShouldOverridePackageLogos,

        [Parameter(ParameterSetName="Individual")]
        [string] $Description,

        [Parameter(ParameterSetName="Individual")]
        [string] $ShortDescription,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
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

    Test-ResourceType -Object $Object -ResourceType ([StoreBrokerResourceType]::Listing)

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerListingProperty]::resourceType] = [StoreBrokerResourceType]::Listing
        $hashBody[[StoreBrokerListingProperty]::languageCode] = $LanguageCode

        if (-not [String]::IsNullOrWhiteSpace($Title))
        {
            $hashBody[[StoreBrokerListingProperty]::title] = $Title
        }

        if (-not [String]::IsNullOrWhiteSpace($ShortTitle))
        {
            $hashBody[[StoreBrokerListingProperty]::shortTitle] = $ShortTitle
        }

        if (-not [String]::IsNullOrWhiteSpace($VoiceTitle))
        {
            $hashBody[[StoreBrokerListingProperty]::voiceTitle] = $VoiceTitle
        }

        if (-not [String]::IsNullOrWhiteSpace($ReleaseNotes))
        {
            $hashBody[[StoreBrokerListingProperty]::releaseNotes] = $ReleaseNotes
        }

        if ($null -ne $Keywords)
        {
            $hashBody[[StoreBrokerListingProperty]::keywords] = @($Keywords)
        }

        if (-not [String]::IsNullOrWhiteSpace($Trademark))
        {
            $hashBody[[StoreBrokerListingProperty]::trademark] = $Trademark
        }

        if (-not [String]::IsNullOrWhiteSpace($LicenseTerm))
        {
            $hashBody[[StoreBrokerListingProperty]::licenseTerm] = $LicenseTerm
        }

        if ($null -ne $Features)
        {
            $hashBody[[StoreBrokerListingProperty]::features] = @($Features)
        }

        if ($null -ne $MinimumHardware)
        {
            $hashBody[[StoreBrokerListingProperty]::minimumHardware] = @($MinimumHardware)
        }

        if ($null -ne $RecommendedHardware)
        {
            $hashBody[[StoreBrokerListingProperty]::recommendedHardware] = @($RecommendedHardware)
        }

        if (-not [String]::IsNullOrWhiteSpace($DevStudio))
        {
            $hashBody[[StoreBrokerListingProperty]::devStudio] = $DevStudio
        }

        # We only set the value if the user explicitly provided a value for this parameter
        # (so for $false, they'd have to pass in -ShouldOverridePackageLogos:$false).
        # Otherwise, there'd be no way to know when the user wants to simply keep the
        # existing value.
        if ($null -ne $PSBoundParameters['ShouldOverridePackageLogos'])
        {
            $hashBody[[StoreBrokerListingProperty]::shouldOverridePackageLogos] = $ShouldOverridePackageLogos
            $telemetryProperties[[StoreBrokerTelemetryProperty]::ShouldOverridePackageLogos] = $ShouldOverridePackageLogos
        }

        if (-not [String]::IsNullOrWhiteSpace($Description))
        {
            $hashBody[[StoreBrokerListingProperty]::description] = $Description
        }

        if (-not [String]::IsNullOrWhiteSpace($ShortDescription))
        {
            $hashBody[[StoreBrokerListingProperty]::shortDescription] = $ShortDescription
        }
    }

    $body = Get-JsonBody -InputObject $hashBody
    Write-Log -Message "Body: $body" -Level Verbose

    $params = @{
        "UriFragment" = "products/$ProductId/listings`?" + ($getParams -join '&')
        "Method" = 'Post'
        "Description" = "Creating new $LanguageCode listing for $ProductId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "New-Listing"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return Invoke-SBRestMethod @params
}

function Remove-Listing
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias("Delete-Listing")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [string] $FeatureGroupId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
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
        "UriFragment" = "products/$ProductId/listings/$LanguageCode" + ($getParams -join '&')
        "Method" = "Delete"
        "Description" = "Deleting the $LanguageCode listing for $ProductId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Remove-Listing"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    $null = Invoke-SBRestMethod @params
}

function Set-Listing
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
        [Alias('LangCode')]
        [string] $LanguageCode,

        [string] $FeatureGroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(ParameterSetName="Individual")]
        [string] $Title,

        [Parameter(ParameterSetName="Individual")]
        [string] $ShortTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $VoiceTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $ReleaseNotes,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $Keywords,

        [Parameter(ParameterSetName="Individual")]
        [string] $Trademark,

        [Parameter(ParameterSetName="Individual")]
        [string] $LicenseTerm,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $Features,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $MinimumHardware,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $RecommendedHardware,

        [Parameter(ParameterSetName="Individual")]
        [string] $DevStudio,

        [Parameter(ParameterSetName="Individual")]
        [switch] $ShouldOverridePackageLogos,

        [Parameter(ParameterSetName="Individual")]
        [string] $Description,

        [Parameter(ParameterSetName="Individual")]
        [string] $ShortDescription,

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

    if ($null -ne $Object)
    {
        $LanguageCode = $Object.languageCode
    }

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
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

    Test-ResourceType -Object $Object -ResourceType ([StoreBrokerResourceType]::Listing)

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerListingProperty]::resourceType] = [StoreBrokerResourceType]::Listing
        $hashBody[[StoreBrokerListingProperty]::revisionToken] = $RevisionToken
        $hashBody[[StoreBrokerListingProperty]::languageCode] = $LanguageCode

        # Very specifically choosing to NOT use [String]::IsNullOrWhiteSpace for any
        # of these checks, because we need a way to be able to clear these notes out.
        #So, a $null means do nothing, while empty string / whitespace means clear out the value.
        if ($null -ne $Title)
        {
            $hashBody[[StoreBrokerListingProperty]::title] = $Title
        }

        if ($null -ne $ShortTitle)
        {
            $hashBody[[StoreBrokerListingProperty]::shortTitle] = $ShortTitle
        }

        if ($null -ne $VoiceTitle)
        {
            $hashBody[[StoreBrokerListingProperty]::voiceTitle] = $VoiceTitle
        }

        if ($null -ne $ReleaseNotes)
        {
            $hashBody[[StoreBrokerListingProperty]::releaseNotes] = $ReleaseNotes
        }

        if ($null -ne $Keywords)
        {
            $hashBody[[StoreBrokerListingProperty]::keywords] = @($Keywords)
        }

        if ($null -ne $Trademark)
        {
            $hashBody[[StoreBrokerListingProperty]::trademark] = $Trademark
        }

        if ($null -ne $LicenseTerm)
        {
            $hashBody[[StoreBrokerListingProperty]::licenseTerm] = $LicenseTerm
        }

        if ($null -ne $Features)
        {
            $hashBody[[StoreBrokerListingProperty]::features] = @($Features)
        }

        if ($null -ne $MinimumHardware)
        {
            $hashBody[[StoreBrokerListingProperty]::minimumHardware] = @($MinimumHardware)
        }

        if ($null -ne $RecommendedHardware)
        {
            $hashBody[[StoreBrokerListingProperty]::recommendedHardware] = @($RecommendedHardware)
        }

        if ($null -ne $DevStudio)
        {
            $hashBody[[StoreBrokerListingProperty]::devStudio] = $DevStudio
        }

        # We only set the value if the user explicitly provided a value for this parameter
        # (so for $false, they'd have to pass in -ShouldOverridePackageLogos:$false).
        # Otherwise, there'd be no way to know when the user wants to simply keep the
        # existing value.
        if ($null -ne $PSBoundParameters['ShouldOverridePackageLogos'])
        {
            $hashBody[[StoreBrokerListingProperty]::shouldOverridePackageLogos] = $ShouldOverridePackageLogos
            $telemetryProperties[[StoreBrokerTelemetryProperty]::ShouldOverridePackageLogos] = $ShouldOverridePackageLogos
        }

        if ($null -ne $Description)
        {
            $hashBody[[StoreBrokerListingProperty]::description] = $Description
        }

        if ($null -ne $ShortDescription)
        {
            $hashBody[[StoreBrokerListingProperty]::shortDescription] = $ShortDescription
        }
    }

    $body = Get-JsonBody -InputObject $hashBody

    $params = @{
        "UriFragment" = "products/$ProductId/listings/$LanguageCode`?" + ($getParams -join '&')
        "Method" = 'Put'
        "Description" = "Updating $LanguageCode listing for $ProductId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Set-Listing"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return Invoke-SBRestMethod @params
}
