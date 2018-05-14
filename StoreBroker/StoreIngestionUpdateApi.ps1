# Copyright (C) Microsoft Corporation.  All rights reserved.

function Update-Submission
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="AddPackages")]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [ValidateScript({if (Test-Path -Path $_ -PathType Leaf) { $true } else { throw "$_ cannot be found." }})]
        [string] $JsonPath,

        [ValidateScript({if (Test-Path -Path $_ -PathType Leaf) { $true } else { throw "$_ cannot be found." }})]
        [string] $ZipPath,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath,

        [Alias('AutoCommit')]
        [switch] $AutoSubmit,

        [string] $SubmissionId = "",

        [ValidateSet('Default', 'Immediate', 'Manual', 'SpecificDate')]
        [string] $TargetPublishMode = $script:keywordDefault,

        [DateTime] $TargetPublishDate,

        [ValidateSet('Default', 'Public', 'Private', 'Hidden', 'StopSelling')]
        [string] $Visibility = $script:keywordDefault,

        [ValidateSet('NoAction', 'Finalize', 'Halt')]
        [string] $ExistingPackageRolloutAction = $script:keywordNoAction,

        [ValidateRange(0, 100)]
        [double] $PackageRolloutPercentage = -1,

        [switch] $IsMandatoryUpdate,

        [DateTime] $MandatoryUpdateEffectiveDate,

        [ValidateScript({if ([System.String]::IsNullOrEmpty($SubmissionId) -or !$_) { $true } else { throw "Can't use -Force and supply a SubmissionId." }})]
        [switch] $Force,

        [Parameter(ParameterSetName="AddPackages")]
        [switch] $AddPackages,

        [Parameter(ParameterSetName="ReplacePackages")]
        [switch] $ReplacePackages,

        [Parameter(ParameterSetName="UpdatePackages")]
        [switch] $UpdatePackages,

        [Parameter(ParameterSetName="UpdatePackages")]
        [int] $RedundantPackagesToKeep = 1,

        [switch] $UpdateListings,

        [switch] $UpdatePublishModeAndVisibility,

        [switch] $UpdatePricingAndAvailability,

        [switch] $UpdateAppProperties,

        [switch] $UpdateGamingOptions,

        [switch] $UpdateTrailers,

        [switch] $UpdateNotesForCertification,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 1
    $isContentPathTemporary = $false

    if ((-not [String]::IsNullOrWhiteSpace($ZipPath)) -and (-not [String]::IsNullOrWhiteSpace($ContentPath)))
    {
        $message = "You should specify either ZipPath OR ContentPath.  Not both."
        Write-Log -Message $message -Level Error
        throw $message
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    if ($null -eq $CorrelationId)
    {
        # We'll assign our own unique CorrelationId for this update request
        # if one wasn't provided to us already.
        $CorrelationId = "$((Get-Date).ToString("yyyyMMddssmm.ffff"))-$ProductId"
    }

    $commonParams = @{
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    Write-Log -Message "Reading in the submission content from: $JsonPath" -Level Verbose
    if ($PSCmdlet.ShouldProcess($JsonPath, "Get-Content"))
    {
        $jsonSubmission = [string](Get-Content $JsonPath -Encoding UTF8) | ConvertFrom-Json
    }

    # Extra layer of validation to protect users from trying to submit a payload to the wrong product
    $jsonProductId = $jsonSubmission.productId
    if ([String]::IsNullOrWhiteSpace($jsonProductId))
    {
        $configPath = Join-Path -Path ([System.Environment]::GetFolderPath('Desktop')) -ChildPath 'newconfig.json'

        Write-Log -Level Warning -Message @(
            "The config file used to generate this submission did not have a ProductId defined in it.",
            "The ProductId entry in the config helps ensure that payloads are not submitted to the wrong product.",
            "Please update your app's StoreBroker config file by adding a `"productId`" property with",
            "your app's ProductId to the `"appSubmission`" section ([$ProductId]).",
            "If you're unclear on what change, needs to be done, you can re-generate your config file using",
            "   New-StoreBrokerConfigFile -ProductId $ProductId -Path `"$configPath`"",
            "and then diff the new config file against your current one to see the requested productId change.")

        # May be an older json file that still uses the AppId.  If so, do the conversion to check that way.
        $appId = $jsonSubmission.appId
        if (-not ([String]::IsNullOrWhiteSpace($appId)))
        {
            $product = Get-Product -AppId $appId @commonParams
            $jsonProductId = $product.id
        }
    }

    if ((-not [String]::IsNullOrWhiteSpace($jsonProductId)) -and ($ProductId -ne $jsonProductId))
    {
        $output = @()
        $output += "The ProductId [$jsonProductId] in the submission content [$JsonPath] does not match the intended ProductId [$ProductId]."
        $output += "You either entered the wrong ProductId at the commandline, or you're referencing the wrong submission content to upload."

        $newLineOutput = ($output -join [Environment]::NewLine)
        Write-Log -Message $newLineOutput -Level Error
        throw $newLineOutput
    }

    # Identify potentially incorrect usage of this method by checking to see if no modification
    # switch was provided by the user
    if ((-not $AddPackages) -and
        (-not $ReplacePackages) -and
        (-not $UpdateListings) -and
        (-not $UpdatePublishModeAndVisibility) -and
        (-not $UpdatePricingAndAvailability) -and
        (-not $UpdateAppProperties) -and
        (-not $UpdateGamingOptions) -and
        (-not $UpdateTrailers) -and
        (-not $UpdateNotesForCertification))
    {
        Write-Log -Level Warning -Message @(
            "You have not specified any `"modification`" switch for updating the submission.",
            "This means that the new submission will be identical to the current one.",
            "If this was not your intention, please read-up on the documentation for this command:",
            "     Get-Help Update-Submission -ShowWindow")
    }

    $commonParams['ProductId'] = $ProductId

    try
    {
        $product = Get-Product @commonParams
        $appId = ($product.externalIds | Where-Object { $_.type -eq 'StoreId' }).value

        if ([System.String]::IsNullOrEmpty($SubmissionId))
        {
            $submission = New-Submission @commonParams -ExistingPackageRolloutAction $ExistingPackageRolloutAction -Force:$Force
            $SubmissionId = $submission.id
        }
        else
        {
            $submission = Get-Submission @commonParams -SubmissionId $SubmissionId
            if (($submission.state -ne [StoreBrokerSubmissionState]::InProgress) -or
                ($submission.subState -ne [StoreBrokerSubmissionSubState]::InDraft))
            {
                $output = @()
                $output += "We can only modify a submission that is: $([StoreBrokerSubmissionState]::InProgress)/$([StoreBrokerSubmissionSubState]::InDraft) state."
                $output += "The submission that you requested to modify ($SubmissionId) is: $($submission.state)/$($submission.subState)."

                $newLineOutput = ($output -join [Environment]::NewLine)
                Write-Log -Message $newLineOutput -Level Error
                throw $newLineOutput
            }
        }

        $commonParams['SubmissionId'] = $SubmissionId

        if ($PSCmdlet.ShouldProcess("Patch-Submission"))
        {
            # If we know that we'll be doing anything with binary content, ensure that it's accessible unzipped.
            if ($UpdateListings -or $UpdateTrailers -or $AddPackages -or $ReplacePackages -or $UpdatePackages)
            {
                if ([String]::IsNullOrEmpty($ContentPath))
                {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    $isContentPathTemporary = $true
                    $ContentPath = New-TemporaryDirectory
                    Write-Log -Message "Unzipping archive (Item: $ZipPath) to (Target: $ContentPath)." -Level Verbose -Indent $indentLevel
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $ContentPath)
                    Write-Log -Message "Unzip complete." -Level Verbose -Indent $indentLevel
                }

                $null = Patch-Listings @commonParams -SubmissionData $jsonSubmission -ContentPath $ContentPath -UpdateListings:$UpdateListings -UpdateTrailers:$UpdateTrailers

                $packageParams = $commonParams.PSObject.Copy() # Get a new instance, not a reference
                $packageParams.Add('SubmissionData', $jsonSubmission)
                $packageParams.Add('ContentPath', $ContentPath)
                if ($AddPackages) { $packageParams.Add('AddPackages', $AddPackages) }
                if ($ReplacePackages) { $packageParams.Add('ReplacePackages', $ReplacePackages) }
                if ($UpdatePackages) { $packageParams.Add('UpdatePackages', $UpdatePackages); $packageParams.Add('RedundantPackagesToKeep', $RedundantPackagesToKeep) }
                $null = Patch-ProductPackages @packageParams
            }

            if ($UpdateAppProperties)
            {
                # Category / SubCategory
                $null = Patch-Properties @commonParams -SubmissionData $jsonSubmission

                # TODO: No equivalent for:
                # $jsonContent.hardwarePreferences
                # $jsonContent.hasExternalInAppProducts
                # $jsonContent.meetAccessibilityGuidelines
                # $jsonContent.canInstallOnRemovableMedia
                # $jsonContent.automaticBackupEnabled
                # $jsonContent.isGameDvrEnabled
            }

            $detailsParams = $commonParams.PSObject.Copy() # Get a new instance, not a reference
            $detailsParams.Add('SubmissionData', $jsonSubmission)
            $detailsParams.Add('UpdatePublishModeAndVisibility', $UpdatePublishModeAndVisibility)
            $detailsParams.Add('UpdateNotesForCertification', $UpdateNotesForCertification)
            $detailsParams.Add('TargetPublishMode', $TargetPublishMode)
            if ($null -ne $TargetPublishDate) { $detailsParams.Add("TargetPublishDate", $TargetPublishDate) }
            $null = Patch-Details @detailsParams

            $null = Patch-ProductAvailability $commonParams -SubmissionData $jsonSubmission -UpdatePublishModeAndVisibility:$UpdatePublishModeAndVisibility -Visibility $Visibility

            if ($UpdatePricingAndAvailability)
            {
                # TODO: Figure out how to do pricing in v2
                # $jsonContent.pricing

                # TODO: No equivalent for:
                # $jsonContent.allowTargetFutureDeviceFamilies
                # $jsonContent.allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies
                # $jsonContent.enterpriseLicensing
            }

            if ($UpdateGamingOptions)
            {
                # TODO: No equivalent
                # $jsonContent.gamingOptions

                if ($null -eq $jsonContent.gamingOptions)
                {
                    $output = @()
                    $output += "You selected to update the Gaming Options for this submission, but it appears you don't have"
                    $output += "that section in your config file.  You should probably re-generate your config file with"
                    $output += "New-StoreBrokerConfigFile, transfer any modified properties to that new config file, and then"
                    $output += "re-generate your StoreBroker payload with New-SubmissionPackage."
                    $output = $output -join [Environment]::NewLine
                    Write-Log -Message $output -Level Error
                    throw $output
                }
            }

            if ($PackageRolloutPercentage -ge 0)
            {
                $null = Patch-SubmissionRollout @packageParams -Percentage $PackageRolloutPercentage
            }

            if ($IsMandatoryUpdate)
            {
                # TODO: No equivalent
                # $jsonContent.packageDeliveryOptions.isMandatoryUpdate
                # if ($null -ne $MandatoryUpdateEffectiveDate)
                # {
                #     if ($IsMandatoryUpdate)
                #     {
                #         $PatchedSubmission.packageDeliveryOptions.mandatoryUpdateEffectiveDate = $MandatoryUpdateEffectiveDate.ToUniversalTime().ToString('o')
                #     }
                #     else
                #     {
                #         Write-Log -Message "MandatoryUpdateEffectiveDate specified without indicating IsMandatoryUpdate.  The value will be ignored." -Level Warning
                #     }
                # }
            }
        }

        Write-Log -Message @(
            "Successfully cloned the existing submission and modified its content.",
            "You can view it on the Dev Portal here:",
            "    https://dev.windows.com/en-us/dashboard/apps/$appId/submissions/$submissionId/")

        if ($AutoSubmit)
        {
            Write-Log -Message "Submitting the submission since -AutoSubmit was requested." -Level Verbose
            Submit-Submission @commonParams -Auto
        }
        else
        {
            Write-Log -Message @(
                "When you're ready to commit, run this command:",
                "  Submit-Submission -ProductId $ProductId -SubmissionId $submissionId")
        }

        # Record the telemetry for this event.
        $stopwatch.Stop()
        $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::AppId = $AppId
            [StoreBrokerTelemetryProperty]::SubmissionId = $submissionId
            [StoreBrokerTelemetryProperty]::ZipPath = (Get-PiiSafeString -PlainText $ZipPath)
            [StoreBrokerTelemetryProperty]::ContentPath = (Get-PiiSafeString -PlainText $ContentPath)
            [StoreBrokerTelemetryProperty]::AutoSubmit = $AutoSubmit
            [StoreBrokerTelemetryProperty]::Force = $Force
            [StoreBrokerTelemetryProperty]::PackageRolloutPercentage = $PackageRolloutPercentage
            [StoreBrokerTelemetryProperty]::IsMandatoryUpdate = [bool]$IsMandatoryUpdate
            [StoreBrokerTelemetryProperty]::AddPackages = $AddPackages
            [StoreBrokerTelemetryProperty]::ReplacePackages = $ReplacePackages
            [StoreBrokerTelemetryProperty]::UpdatePackages = $UpdatePackages
            [StoreBrokerTelemetryProperty]::RedundantPackagesToKeep = $RedundantPackagesToKeep
            [StoreBrokerTelemetryProperty]::UpdateListings = $UpdateListings
            [StoreBrokerTelemetryProperty]::UpdatePublishModeAndVisibility = $UpdatePublishModeAndVisibility
            [StoreBrokerTelemetryProperty]::UpdatePricingAndAvailability = $UpdatePricingAndAvailability
            [StoreBrokerTelemetryProperty]::UpdateGamingOptions = $UpdateGamingOptions
            [StoreBrokerTelemetryProperty]::UpdateTrailers = $UpdateTrailers
            [StoreBrokerTelemetryProperty]::UpdateAppProperties = $UpdateAppProperties
            [StoreBrokerTelemetryProperty]::UpdateNotesForCertification = $UpdateNotesForCertification
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        Set-TelemetryEvent -EventName Update-Submission -Properties $telemetryProperties -Metrics $telemetryMetrics

        return
    }
    catch
    {
        Write-Log -Exception $_ -Level Error
        throw
    }
    finally
    {
        if ($isContentPathTemporary -and (-not [String]::IsNullOrWhiteSpace($ContentPath)))
        {
            Write-Log -Message "Deleting temporary content directory: $ContentPath" -Level Verbose -Indent $indentLevel
            $null = Remove-Item -Force -Recurse $ContentPath -ErrorAction SilentlyContinue
            Write-Log -Message "Deleting temporary directory complete." -Level Verbose -Indent $indentLevel
        }
    }
}

# Internal helper
# Operates on an existing submissionId
function Patch-ProductPackages
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="AddPackages")]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath, # NOTE: The main wrapper should unzip the zip (if there is one), so that all internal helpers only operate on a Contentpath

        [Parameter(ParameterSetName="AddPackages")]
        [switch] $AddPackages,

        [Parameter(ParameterSetName="ReplacePackages")]
        [switch] $ReplacePackages,

        [Parameter(ParameterSetName="UpdatePackages")]
        [switch] $UpdatePackages,

        [Parameter(ParameterSetName="UpdatePackages")]
        [int] $RedundantPackagesToKeep = 1,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    if (($AddPackages -or $ReplacePackages -or $UpdatePackages) -and ($SubmissionData.applicationPackages.Count -eq 0))
    {
        $output = @()
        $output += "Your submission doesn't contain any packages, so you cannot Add, Replace or Update packages."
        $output += "Please check your input settings to New-SubmissionPackage and ensure you're providing a value for AppxPath."
        $output = $output -join [Environment]::NewLine
        Write-Log -Message $output -Level Error
        throw $output
    }

    if ((-not $AddPackages) -and (-not $ReplacePackages) -and (-not $UpdatePackages))
    {
        return
    }

    $params = @{
        'ProductId' = $ProductId
        'SubmissionId' = $SubmissionId
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    if ($ReplacePackages)
    {
        # Get all of the current packages in the submission and delete them
        $packages = Get-ProductPackage @params
        foreach ($package in $packages)
        {
            $null = Remove-ProductPackage @params -PackageId $package.id
        }
    }
    elseif ($UpdatePackages)
    {
        # TODO -- Better understand the current object model so that we can accurately determine
        # which packages are redundant.
        # TODO: BE CAREFUL ABOUT KEEPING PRE-WIN 10 PACKAGES!!!
    }

    # Regardless of which method we're following, the last thing that we'll do is get these new
    # associated with this submission
    foreach ($package in $SubmissionData.applicationPackages)
    {
        $params['FileName'] = (Split-Path -Path $package.fileName -Leaf)
        $packageSubmission = New-ProductPackage @params
        $null = Set-StoreFile -FilePath (Join-Path -Path $ContentPath -ChildPath $package.fileName) -SasUri $packageSubmission.fileSasUri -NoStatus:$NoStatus
        $packageSubmission.state = [StoreBrokerFileState]::Uploaded.ToString()
        $null = Set-ProductPackage @params -Object $packageSubmission
    }

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ContentPath = (Get-PiiSafeString -PlainText $ContentPath)
        [StoreBrokerTelemetryProperty]::AddPackages = $AddPackages
        [StoreBrokerTelemetryProperty]::ReplacePackages = $ReplacePackages
        [StoreBrokerTelemetryProperty]::UpdatePackages = $UpdatePackages
        [StoreBrokerTelemetryProperty]::RedundantPackagesToKeep = $RedundantPackagesToKeep
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-SubmissionPackage -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}

# Internal helper
# Operates on an existing submissionId
function Patch-Listings
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath, # NOTE: The main wrapper should unzip the zip (if there is one), so that all internal helpers only operate on a Contentpath

        [switch] $UpdateListings,

        [switch] $UpdateTrailers,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 2

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $params = @{
        'ProductId' = $ProductId
        'SubmissionId' = $SubmissionId
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    # Determine what our current listings are.
    $currentListings = Get-Listing @params

    # We need to keep track of languages in $currentListings that don't have a match in
    # $SubmissionData (so that we can remove them), as well which languages occur in $SubmissionData
    # that aren't in $currentListings so that we can add them.  We don't simply delete all and start
    # over due to the increased time/cost that we'd have by doing so.
    [System.Collections.ArrayList]$listingsToDelete = @()
    [System.Collections.ArrayList]$clonedLangCodes = @()

    # First we delete all of the existing images
    Write-Log -Message 'Updating the cloned listings with information supplied by user data.' -Level Verbose -Indent $indentLevel
    foreach ($listing in $currentListings)
    {
        $suppliedListing = $SubmissionData.listings.($listing.languageCode).baseListing
        if ($null -eq $suppliedListing)
        {
            $listingsToDelete.Add($listing.languageCode)
            continue
        }

        if ($UpdateListings)
        {
            # Updating the existing Listing submission with the user's supplied content
            $listing.shortTitle = $suppliedListing.shortTitle
            $listing.voiceTitle = $suppliedListing.voiceTitle
            $listing.releaseNotes = $suppliedListing.releaseNotes
            $listing.keywords = $suppliedListing.keywords
            $listing.trademark = $suppliedListing.copyrightAndTrademarkInfo
            $listing.licenseTerm = $suppliedListing.licenseTerms
            $listing.features = $suppliedListing.features
            $listing.recommendedHardware = $suppliedListing.minimumHardware
            $listing.devStudio = $suppliedListing.devStudio
            #TODO: $listing.shouldOverridePackageLogos = ???
            $listing.title = $suppliedListing.title
            $listing.description = $suppliedListing.description
            $listing.shortDescription = $suppliedListing.shortDescription

            # TODO: Not currently supported by the v2 object model
            # suppliedListing.websiteUrl
            # suppliedListing.privacyPolicy
            # suppliedListing.supportContact

            $langCode = $listing.languageCode
            $clonedLangCodes.Add($langCode)

            $null = Set-Listing @params -Object $listing
            $null = Patch-ListingImages @params -LanguageCode $langCode
        }

        if ($UpdateTrailers)
        {
            $null = Patch-ListingVideos @params -LanguageCode $langCode
        }
    }

    # Now we have to see what languages exist in the user's supplied content that we didn't already
    # have cloned submissions for
    Write-Log -Message 'Now adding listings for languages that didn''t have pre-existing clones.' -Level Verbose -Indent $indentLevel
    $SubmissionData.listings |
        Get-Member -Type NoteProperty |
            ForEach-Object {
                $langCode = $_.Name
                $suppliedListing = $SubmissionData.listings.$langCode.baselisting
                if (-not $clonedLangCodes.Contains($langCode))
                {
                    if ($UpdateListings)
                    {
                        $listingParams = $params.PSObject.Copy() # Get a new instance, not a reference
                        $listingParams['LanguageCode'] = $langCode
                        $listingParams['ShortTitle'] = $suppliedListing.shortTitle
                        $listingParams['VoiceTitle'] = $suppliedListing.voiceTitle
                        $listingParams['ReleaseNotes'] = $suppliedListing.releaseNotes
                        $listingParams['Keywords'] = $suppliedListing.keywords
                        $listingParams['Trademark'] = $suppliedListing.copyrightAndTrademarkInfo
                        $listingParams['LicenseTerm'] = $suppliedListing.licenseTerms
                        $listingParams['Features'] = $suppliedListing.features
                        $listingParams['RecommendedHardware'] = $suppliedListing.minimumHardware
                        $listingParams['DevStudio'] = $suppliedListing.devStudio
                        #TODO: $listingParams['shouldOverridePackageLogos'] = ???
                        $listingParams['Title'] = $suppliedListing.title
                        $listingParams['Description'] = $suppliedListing.description
                        $listingParams['ShortDescription'] = $suppliedListing.shortDescription

                        # TODO: Not currently supported by the v2 object model
                        # suppliedListing.websiteUrl
                        # suppliedListing.privacyPolicy
                        # suppliedListing.supportContact

                        $null = New-Listing @listingParams
                        $null = Patch-ListingImages @params -LanguageCode $langCode
                    }

                    if ($UpdateTrailers)
                    {
                        $null = Patch-ListingVideos @params -LanguageCode $langCode
                    }
                }
            }

    Write-Log -Message 'Now removing listings for languages that were cloned by the submission but don''t have current user data.' -Level Verbose -Indent $indentLevel
    foreach ($langCode in $listingsToDelete)
    {
        if ($UpdateListings)
        {
            $null = Remove-Listing @params -LanguageCode $langCode
            $null = Patch-ListingImages @params -LanguageCode $langCode -RemoveOnly
        }

        if ($UpdateTrailers)
        {
            $null = Patch-ListingVideos @params -LanguageCode $langCode -RemoveOnly
        }
    }

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ContentPath = (Get-PiiSafeString -PlainText $ContentPath)
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-Listings -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}

# Internal helper
# Operates on an existing submissionId
function Patch-ListingImages
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath, # NOTE: The main wrapper should unzip the zip (if there is one), so that all internal helpers only operate on a Contentpath

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [switch] $RemoveOnly,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 4

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $params = @{
        'ProductId' = $ProductId
        'SubmissionId' = $SubmissionId
        'LanguageCode' = $LanguageCode
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    $currentImages = Get-ListingImage @params

    # First we delete all of the existing images
    Write-Log -Message "Removing all [$LanguageCode] listing images." -Level Verbose -Indent $indentLevel
    foreach ($image in $currentImages)
    {
        $null = Remove-ListingImage @params -ImageId $image.id
    }

    if (-not $RemoveOnly)
    {
        # Then we proceed with adding/uploading all of the current images
        Write-Log -Message "Creating [$LanguageCode] listing images." -Level Verbose -Indent $indentLevel
        foreach ($image in $SubmissionData.listings.$LanguageCode.baseListing.images)
        {
            # TODO: Determine if we should expose Orientation to the PDP and then here.
            $imageSubmission = New-ListingImage @params -FileName (Split-Path -Path $image.fileName -Leaf) -Type $image.imageType
            $null = Set-StoreFile -FilePath (Join-Path -Path $ContentPath -ChildPath $image.fileName) -SasUri $imageSubmission.fileSasUri -NoStatus:$NoStatus
            $imageSubmission.state = [StoreBrokerFileState]::Uploaded.ToString()
            $null = Set-ListingImage @params -Object $imageSubmission
        }
    }

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ContentPath = (Get-PiiSafeString -PlainText $ContentPath)
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::RemoveOnly = $RemoveOnly
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-ListingImages -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}

# Internal helper
# Operates on an existing submissionId
function Patch-ListingVideos
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath, # NOTE: The main wrapper should unzip the zip (if there is one), so that all internal helpers only operate on a Contentpath

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [switch] $RemoveOnly,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 4

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $params = @{
        'ProductId' = $ProductId
        'SubmissionId' = $SubmissionId
        'LanguageCode' = $LanguageCode
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    $currentVideos = Get-ListingVideo @params

    # First we delete all of the existing videos
    Write-Log -Message "Removing all [$LanguageCode] listing videos." -Level Verbose -Indent $indentLevel
    foreach ($video in $currentVideos)
    {
        $null = Remove-ListingVideo @params -VideoId $video.id
    }

    if (-not $RemoveOnly)
    {
        # Then we proceed with adding/uploading all of the current videos
        Write-Log -Message "Creating [$LanguageCode] listing videos." -Level Verbose -Indent $indentLevel
        foreach ($trailer in $SubmissionData.trailerAssets)
        {
            $fileName = $trailer.videoFileName
            $trailerAssets = $trailer.trailerAssets.$LanguageCode
            if ($null -ne $trailerAssets)
            {
                $title = $trailerAssets.title
                $thumbnailFileName = $trailerAssets.imageList[0].fileName
                $thumbnailDescription = $trailerAssets.imageList[0].description

                $videoParams = $params.PSObject.Copy() # Get a new instance, not a reference
                $videoParams['FileName'] = (Split-Path -Path $fileName -Leaf)
                $videoParams['ThumbnailFileName'] = (Split-Path -Path $thumbnailFileName -Leaf)
                $videoParams['ThumbnailTitle'] = $title
                $videoParams['ThumbnailDescription'] = $description
                # TODO: $videoParams['ThumbnailOrientation'] = ???

                $videoSubmission = New-ListingVideo @videoParams
                $null = Set-StoreFile -FilePath (Join-Path -Path $ContentPath -ChildPath $fileName) -SasUri $videoSubmission.fileSasUri -NoStatus:$NoStatus
                $null = Set-StoreFile -FilePath (Join-Path -Path $ContentPath -ChildPath $thumbnailFileName) -SasUri $videoSubmission.thumbnail.fileSasUri -NoStatus:$NoStatus
                $videoSubmission.state = [StoreBrokerFileState]::Uploaded.ToString()
                $videoSubmission.thumbnail.state = [StoreBrokerFileState]::Uploaded.ToString()
                $null = Set-ListingVideo @params -Object $videoSubmission
            }
        }
    }

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ContentPath = (Get-PiiSafeString -PlainText $ContentPath)
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::RemoveOnly = $RemoveOnly
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-ListingVideos -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}

# Internal helper
# Operates on an existing submissionId
function Patch-Properties
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 4

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

    [System.Collections.ArrayList]$split = $SubmissionData.applicationCategory -split '_'
    $category = $split[0]
    $split.RemoveAt(0)
    $subCategory = $split
    if ($subCategory.Count -eq 0)
    {
        $subCategory.Add('NotSet')
    }

    $property.category = $category
    $property.subcategories = (ConvertTo-Json -InputObject $subCategory)

    $null = Set-Property @params -Object $property

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-Properties -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}

# Internal helper
# Operates on an existing submissionId
function Patch-Details
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [switch] $UpdatePublishModeAndVisibility,

        [ValidateSet('Default', 'Immediate', 'Manual', 'SpecificDate')]
        [string] $TargetPublishMode = $script:keywordDefault,

        [DateTime] $TargetPublishDate,

        [switch] $UpdateNotesForCertification,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 4

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $params = @{
        'ProductId' = $ProductId
        'SubmissionId' = $SubmissionId
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    $detail = Get-SubmissionDetail @params

    if ($UpdatePublishModeAndVisibility)
    {
        $detail.isManualPublish = ($SubmissionData.targetPublishMode -eq $script:keywordManual)
        $detail.releaseTimeInUtc = $SubmissionData.targetPublishDate

        # TODO: There is no equivalent of changing to "Immediate" from a specific date/time,
        # so, we'll hack that by changing it to now which will be the past (and hence immediate)
        # by the time this gets submitted.
        if ($SubmissionData.targetPublishMode -eq $script:keywordImmediate)
        {
            $detail.releaseTimeInUtc = (Get-Date).ToUniversalTime().ToString('o')
        }
    }

    # If users pass in a different value for any of the publish/values at the commandline,
    # they override those coming from the config.
    if ($TargetPublishMode -ne $script:keywordDefault)
    {
        if (($TargetPublishMode -eq $script:keywordSpecificDate) -and ($null -eq $TargetPublishDate))
        {
            $output = "TargetPublishMode was set to '$script:keywordSpecificDate' but TargetPublishDate was not specified."
            Write-Log -Message $output -Level Error
            throw $output
        }

        $detail.isManualPublish = ($SubmissionData.targetPublishMode -eq $script:keywordManual)

        # TODO: There is no equivalent of changing to "Immediate" from a specific date/time,
        # so, we'll hack that by changing it to now which will be the past (and hence immediate)
        # by the time this gets submitted.
        if ($SubmissionData.targetPublishMode -eq $script:keywordImmediate)
        {
            $detail.releaseTimeInUtc = (Get-Date).ToUniversalTime().ToString('o')
        }
    }

    if ($null -ne $TargetPublishDate)
    {
        if ($TargetPublishMode -ne $script:keywordSpecificDate)
        {
            $output = "A TargetPublishDate was specified, but the TargetPublishMode was [$TargetPublishMode],  not '$script:keywordSpecificDate'."
            Write-Log -Message $output -Level Error
            throw $output
        }

        $PatchedSubmission.targetPublishDate = $TargetPublishDate.ToUniversalTime().ToString('o')
    }

    if ($UpdateNotesForCertification)
    {
        $details.certificationNotes = $SubmissionData.notesForCertification
    }

    $null = Set-SubmissionDetail @params -Object $detail

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::UpdatePublishModeAndVisibility = $UpdatePublishModeAndVisibility
        [StoreBrokerTelemetryProperty]::TargetPublishMode = $TargetPublishMode
        [StoreBrokerTelemetryProperty]::UpdateNotesForCertification = $UpdateNotesForCertification
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-Details -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}

# Internal helper
# Operates on an existing submissionId
function Patch-ProductAvailability
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [switch] $UpdatePublishModeAndVisibility,

        [ValidateSet('Default', 'Public', 'Private', 'Hidden', 'StopSelling')]
        [string] $Visibility = $script:keywordDefault,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 4

    if (($Visibility -eq 'Default') -and (-not $UpdatePublishModeAndVisibility))
    {
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

    $availability = Get-ProductAvailability @params

    if ($UpdatePublishModeAndVisibility)
    {
        $availability.visibility = $jsonContent.visibility
    }

    # If users pass in a different value for any of the publish/values at the commandline,
    # they override those coming from the config.
    if ($Visibility -ne 'Default')
    {
        $availability.visibility = $Visibility
    }

    # Hidden (API v1) == StopSelling (API v2)
    if ($availability.visibility -eq 'Hidden')
    {
        $availability.visibility = 'StopSelling'
    }

    $null = Set-ProductAvailability @params -Object $availability

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::UpdatePublishModeAndVisibility = $UpdatePublishModeAndVisibility
        [StoreBrokerTelemetryProperty]::Visbility = $Visibility
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-ProductAvailability -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}


# Internal helper
# Operates on an existing submissionId
function Patch-SubmissionRollout
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [int] $Percentage = -1,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 4

    if ($Percentage -le 0)
    {
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

    $rollout = Get-SubmissionRollout @params

    $rollout.state = 'Initialized'
    $rollout.percentage = $Percentage
    $rollout.enabled = $true

    $null = Set-SubmissionRollout @params -Object $rollout

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::Percentage = $Percentage
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-SubmissionRollout -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}
