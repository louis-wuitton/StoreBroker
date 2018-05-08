Add-Type -TypeDefinition @"
   public enum StoreBrokerListingVideoProperty
   {
       fileName,
       resourceType,
       revisionToken,
       state,
       thumbnail
   }
"@

Add-Type -TypeDefinition @"
   public enum StoreBrokerListingVideoThumbnailProperty
   {
       fileName,
       description,
       state,
       title
   }
"@
function Get-ListingVideos
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

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
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        $params = @{
            "UriFragment" = "products/$ProductId/listings/$LanguageCode/videos`?" + ($getParams -join '&')
            "Description" = "Getting listing videos for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ListingVideos"
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

function New-ListingVideo
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject[]] $Object,

        [Parameter(ParameterSetName="Individual")]
        [string] $FileName,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded', 'InProcessing', 'Processed', 'ProcessFailed')]
        [string] $State,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailFileName,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailDescription,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded', 'InProcessing', 'Processed', 'ProcessFailed')]
        [string] $ThumbnailState,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
            [StoreBrokerTelemetryProperty]::State = $State
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        Test-ResourceType -Object $Object -ResourceType [StoreBrokerResourceType]::ListingVideo

        $hashBody = $Object
        if ($null -eq $hashBody)
        {
            # Convert the input into a Json body.
            $hashBody = @{}
            $hashBody[[StoreBrokerListingVideoProperty]::resourceType] = [StoreBrokerResourceType]::ListingVideo

            if (-not [String]::IsNullOrWhiteSpace($FileName))
            {
                $hashBody[[StoreBrokerListingVideoProperty]::fileName] = $FileName
            }

            if (-not [String]::IsNullOrWhiteSpace($State))
            {
                $hashBody[[StoreBrokerListingVideoProperty]::state] = $State
            }

            if ((-not [String]::IsNullOrWhiteSpace($ThumbnailFileName)) -or
                (-not [String]::IsNullOrWhiteSpace($ThumbnailTitle)) -or
                (-not [String]::IsNullOrWhiteSpace($ThumbnailDescription)) -or
                (-not [String]::IsNullOrWhiteSpace($ThumbnailState)))
            {
                $hashBody[[StoreBrokerListingVideoProperty]::thumbnail] = @{}
                if (-not [String]::IsNullOrWhiteSpace($ThumbnailFileName))
                {
                    $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::fileName] = $ThumbnailFileName
                }

                if (-not [String]::IsNullOrWhiteSpace($ThumbnailTitle))
                {
                    $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::title] = $ThumbnailTitle
                }

                if (-not [String]::IsNullOrWhiteSpace($ThumbnailDescription))
                {
                    $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::description] = $ThumbnailDescription
                }

                if (-not [String]::IsNullOrWhiteSpace($ThumbnailState))
                {
                    $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::state] = $ThumbnailState
                }
            }
        }

        $body = $hashBody | ConvertTo-Json

        $uriFragment = "products/$ProductId/listings/$LanguageCode/videos`?" + ($getParams -join '&')
        $description = "Creating new $LanguageCode listing videos for $ProductId"
        $isbulkOperation = $ListingObject.Count -gt 1
        if ($isbulkOperation)
        {
            $uriFragment = "products/$ProductId/listings/$LanguageCode/videos/bulk`?" + ($getParams -join '&')
            $description = "Bulk creating $LanguageCode listing videos for $ProductId"
        }

        $params = @{
            "UriFragment" = $uriFragment
            "Method" = 'Post'
            "Description" = $description
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "New-ListingVideo"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        $result = Invoke-SBRestMethod @params
        if ($isbulkOperation)
        {
            $finalResult = @()
            $finalResult += $result.value

            if ($null -ne $result.nextLink)
            {
                $params = @{
                    "UriFragment" = $result.nextLink
                    "Description" = "Getting remaining results"
                    "ClientRequestId" = $ClientRequestId
                    "CorrelationId" = $CorrelationId
                    "AccessToken" = $AccessToken
                    "TelemetryEventName" = "New-ListingVideo"
                    "TelemetryProperties" = $telemetryProperties
                    "NoStatus" = $NoStatus
                }

                $finalResult += Invoke-SBRestMethodMultipleResult @params
            }

            return $finalResult
        }
        else
        {
            return $result
        }
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}
function Remove-ListingVideo
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias("Delete-ListingVideo")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [Parameter(Mandatory)]
        [string] $VideoId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::VideoId = $VideoId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    $params = @{
        "UriFragment" = "products/$ProductId/listings/$LanguageCode/images/$ImageId`?" + ($getParams -join '&')
        "Method" = "Delete"
        "Description" = "Deleting image $ImageId from the $LanguageCode listing for $ProductId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Remove-ListingImage"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    $null = Invoke-SBRestMethod @params
}

function Set-ListingVideo
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [string] $ImageId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(ParameterSetName="Individual")]
        [string] $FileName,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded', 'InProcessing', 'Processed', 'ProcessFailed')]
        [string] $State,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailFileName,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailDescription,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded', 'InProcessing', 'Processed', 'ProcessFailed')]
        [string] $ThumbnailState,

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

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
            [StoreBrokerTelemetryProperty]::State = $State
            [StoreBrokerTelemetryProperty]::RevisionToken = $RevisionToken
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        Test-ResourceType -Object $Object -ResourceType [StoreBrokerResourceType]::ListingVideo

        $hashBody = $Object
        if ($null -eq $hashBody)
        {
            # Convert the input into a Json body.
            $hashBody = @{}
            $hashBody['revisionToken'] = $RevisionToken

            # Very specifically choosing to NOT use [String]::IsNullOrWhiteSpace for any
            # of these checks, because we need a way to be able to clear these notes out.
            #So, a $null means do nothing, while empty string / whitespace means clear out the value.
            if ($null -ne $FileName)
            {
                $hashBody['fileName'] = $FileName
            }

            if ($null -ne $State)
            {
                $hashBody['state'] = $State
            }

            if (($null -ne $ThumbnailFileName) -or ($null -ne $ThumbnailTitle) -or ($null -ne $ThumbnailDescription) -or ($null -ne $ThumbnailState))
            {
                $hashBody['thumbnail'] = @{}
                if ($null -ne $ThumbnailFileName)
                {
                    $hashBody['thumbnail']['fileName'] = $ThumbnailFileName
                }

                if ($null -ne $ThumbnailTitle)
                {
                    $hashBody['thumbnail']['title'] = $ThumbnailTitle
                }

                if ($null -ne $ThumbnailDescription)
                {
                    $hashBody['thumbnail']['description'] = $ThumbnailDescription
                }

                if ($null -ne $ThumbnailState)
                {
                    $hashBody['thumbnail']['state'] = $ThumbnailState
                }
            }
        }

        $body = $hashBody | ConvertTo-Json

        $params = @{
            "UriFragment" = "products/$ProductId/listings/$LanguageCode/Videos/$VideoId`?" + ($getParams -join '&')
            "Method" = 'Put'
            "Description" = "Updating listing video $VideoId for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Set-ListingVideo"
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

function Get-ListingVideo
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [Parameter(Mandatory)]
        [string] $VideoId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
            [StoreBrokerTelemetryProperty]::VideoId = $VideoId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        $params = @{
            "UriFragment" = "products/$ProductId/listings/$LanguageCode/videos/$VideoId`?" + ($getParams -join '&')
            "Method" = 'Get'
            "Description" = "Getting listing video $VideoId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ListingVideo"
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
