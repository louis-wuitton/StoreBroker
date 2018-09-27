Add-Type -TypeDefinition @"
   public enum StoreBrokerPackageProperty
   {
       fileName,
       resourceType,
       revisionToken,
       state
   }
"@

function Get-ProductPackage
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Search")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(
            Mandatory,
            ParameterSetName="Known")]
        [string] $PackageId,

        [string] $FeatureGroupId,

        [Parameter(ParameterSetName="Search")]
        [switch] $SinglePage,

        [Parameter(ParameterSetName="Known")]
        [switch] $WithSasUri,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    $singleQuery = (-not [String]::IsNullOrWhiteSpace($PackageId))
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::PackageId = $PackageId
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

    if ($WithSasUri)
    {
        $getParams += "withSasUri=true"
    }

    $params = @{
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Get-ProductPackage"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    if ($singleQuery)
    {
        $params["UriFragment"] = "products/$ProductId/packages/$PackageId`?" + ($getParams -join '&')
        $params["Method" ] = 'Get'
        $params["Description"] =  "Getting package $PackageId for $ProductId"

        return Invoke-SBRestMethod @params
    }
    else
    {
        $params["UriFragment"] = "products/$ProductId/packages`?" + ($getParams -join '&')
        $params["Description"] =  "Getting packages for $ProductId"
        $params["SinglePage" ] = $SinglePage

        return Invoke-SBRestMethodMultipleResult @params
    }
}

function New-ProductPackage
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [string] $SubmissionId,

        [string] $FeatureGroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $FileName,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

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

    Test-ResourceType -Object $Object -ResourceType ([StoreBrokerResourceType]::Package)

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerPackageProperty]::resourceType] = [StoreBrokerResourceType]::Package
        $hashBody[[StoreBrokerPackageProperty]::fileName] = $FileName
    }

    $body = Get-JsonBody -InputObject $hashBody
    Write-Log -Message "Body: $body" -Level Verbose

    $params = @{
        "UriFragment" = "products/$ProductId/packages`?" + ($getParams -join '&')
        "Method" = 'Post'
        "Description" = "Creating new package for $ProductId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "New-ProductPackage"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return Invoke-SBRestMethod @params
}

function Set-ProductPackage
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
        [string] $PackageId,

        [string] $FeatureGroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded')]
        [string] $State = 'PendingUpload',

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
        if ($null -ne $Object)
        {
            $PackageId = $Object.id
        }

        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::PackageId = $PackageId
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
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

        if (-not [String]::IsNullOrWhiteSpace($FeatureGroupId))
        {
            $getParams += "featureGroupId=$FeatureGroupId"
        }

        Test-ResourceType -Object $Object -ResourceType ([StoreBrokerResourceType]::Package)

        $hashBody = $Object
        if ($null -eq $hashBody)
        {
            # Convert the input into a Json body.
            $hashBody = @{}
            $hashBody[[StoreBrokerPackageProperty]::resourceType] = [StoreBrokerResourceType]::Package
            $hashBody[[StoreBrokerPackageProperty]::revisionToken] = $RevisionToken
            $hashBody[[StoreBrokerPackageProperty]::state] = $State
        }

        $body = Get-JsonBody -InputObject $hashBody
        Write-Log -Message "Body: $body" -Level Verbose

        $params = @{
            "UriFragment" = "products/$ProductId/packages/$PackageId`?" + ($getParams -join '&')
            "Method" = 'Put'
            "Description" = "Updating package $PackageId for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Set-ProductPackage"
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

function Remove-ProductPackage
{
    [Alias('Delete-ProductPackage')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [string] $PackageId,

        [string] $FeatureGroupId,

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
            [StoreBrokerTelemetryProperty]::PackageId = $PackageId
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
            "UriFragment" = "products/$ProductId/packages/$PackageId`?" + ($getParams -join '&')
            "Method" = 'Delete'
            "Description" = "Removing package $PackageId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Remove-ProductPackage"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        $null = Invoke-SBRestMethod @params
    }
    catch
    {
        throw
    }
}

function Get-VersionsToKeep
{
<# 
    .SYNOPSIS
        Determine the versions of the packages to keep when user speficy Update-Packages for packages submissions

    .NOTES
        Here is how we determine which packages to keep:
        For each package we map each package's bundle with a unique key. The key is constructed by:
            1. Concatnating all the target platforms followed by min version. So it looks something like:
               targetplatform1_minversion1_targetplatform2_minversion2......
               We save this as a variable called $uniquePackageTypeKey
            2. Looking at all the architectures from the bundleContents. If the bundleContent is 
               empty then we simply use grab the architecture field from the package object. Concatnate
               $uniquePackageTypeKey with the package's architecture. 
               Otherwise, we look through the app bundles. Each bundle has a unique architecture. Thus for each 
               bundle we create a key by concatnating $uniquePackageTypeKey with the bundle's architecture.
            3. Map each of the keys we derived from above with the package's version, and save the mapping in a 
               dictionary. We want to make sure that the number of packages we want to keep for each key is less 
               than or equal to $RedundantPackagesToKeep
#>
    param(
        [Parameter(Mandatory)]
        [Object[]] $Package,

        [Parameter(Mandatory)]
        [int] $RedundantPackagesToKeep
    )

    # Maximum number of packages allowed in one flight group according to Windows Store
    Set-Variable -Name MaxPackagesPerGroup -Value 25 -Option Constant -Scope Local -Force
    
    if ($RedundantPackagesToKeep -gt $MaxPackagesPerGroup)
    {
        Write-Log "You have specified a value for number of packages to keep that exceeded the maximum possible number of packages to keep" -Level Warning
        $RedundantPackagesToKeep = $MaxPackagesPerGroup
    }

    $uniquePackageTypeToVersionMapping = @{}
    foreach ($pkg in $Package)
    {
        if ($null -eq $pkg.architecture)
        {
            $message =  "Package $($pkg.version) doesn't have a valid architecture!"
            Write-Log -Message $message -Level Error
            throw $message
        }

        if ($null -eq $pkg.targetPlatforms)
        {
            $message =  "Package $($pkg.version) doesn't have a valid target platform!"
            Write-Log -Message $message -Level Error
            throw $message
        }

        $uniquePackageTypeKey = [string]::Empty
        $null = $pkg.targetPlatforms | Sort-Object -Property name -CaseSensitive:$false
        # Concatnating all the target platforms followed by min version
        foreach ($targetPlatform in $pkg.targetPlatforms)
        {
            $uniquePackageTypeKey += "$($targetPlatform.name)_"
            if ($null -ne $targetPlatform.minVersion)
            {
                $uniquePackageTypeKey += "$($targetPlatform.minVersion)_"
            }
        }

        $appBundles = $pkg.bundleContents | Where-Object contentType -eq 'Application'
        # Checking the architectures of all the application bundles
        if ($null -eq $appBundles -or $appBundles.Count -eq 0)
        {
            $uniquePackageTypeKey += $pkg.architecture
            if ($null -eq $uniquePackageTypeToVersionMapping[$uniquePackageTypeKey])
            {
                $uniquePackageTypeToVersionMapping[$uniquePackageTypeKey] = @()
            }
            $uniquePackageTypeToVersionMapping[$uniquePackageTypeKey] += [System.Version]::Parse($pkg.version)
        }
        else 
        {
            foreach ($bundle in $appBundles)
            {
                $tempUniqueKey =$uniquePackageTypeKey + $bundle.architecture
                if ($null -eq $uniquePackageTypeToVersionMapping[$tempUniqueKey])
                {
                    $uniquePackageTypeToVersionMapping[$tempUniqueKey] = @()
                }
                $uniquePackageTypeToVersionMapping[$tempUniqueKey] += [System.Version]::Parse($pkg.version)
            }
        }
    }
    
    $versionsToKeepMap = @{}

    foreach ($entry in $uniquePackageTypeToVersionMapping.Keys)
    {
        [array]::Sort($uniquePackageTypeToVersionMapping[$entry])
        [array]::Reverse($uniquePackageTypeToVersionMapping[$entry])
        # We map each package type with the versions of the packages, and for each package type, the maximum number of packages to keep is defined by RedendantPackagesToKeep
        foreach ($version in $uniquePackageTypeToVersionMapping[$entry][0..($RedundantPackagesToKeep - 1)])
        {
            $versionsToKeepMap[$version.ToString()] = $true
        }
    }

    $versionsToKeep = @()
    $versionsToKeepMap.Keys | ForEach-Object { $versionsToKeep += $_ }
    return $versionsToKeep
}

function Update-ProductPackage
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
        [string] $PackageRootPath, # NOTE: The main wrapper should unzip the zip (if there is one), so that all internal helpers only operate on a PackageRootPath

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

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    try
    {
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
            Write-Log -Message 'No modification parameters provided.  Nothing to do.' -Level Verbose
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
                $null = Remove-ProductPackage @params -PackageId ($package.id)
            }
        }
        elseif ($UpdatePackages)
        {
            $packages = Get-ProductPackage @params
            if ($null -eq $packages)
            {
                $message =  "Cannot update the packages because the cloned submission is missing its packages."
                Write-Log -Message $message -Level Error
                throw $message
            }
           
            $versionsToKeep = Get-VersionsToKeep -Package $packages -RedundantPackagesToKeep $RedundantPackagesToKeep
            $numberOfPackagesToRemove = 0
            foreach ($package in $packages)
            {
                if (-not $versionsToKeep.Contains($package.version))
                {
                    $null = Remove-ProductPackage @params -PackageId ($package.id)
                    $numberOfPackagesToRemove ++
                }
            }

            Write-Log -Message "Cloned submission had [$($packages.Length)] package(s). New submission specified [$($SubmissionData.applicationPackages.Length)] package(s). User requested to keep [$RedundantPackagesToKeep] redundant package(s). [$numberofPackagesToRemove] package(s) were removed." -Level Verbose
        }

        # Regardless of which method we're following, the last thing that we'll do is get these new
        # packages associated with this submission.
        foreach ($package in $SubmissionData.applicationPackages)
        {
            $packageSubmission = New-ProductPackage @params -FileName (Split-Path -Path $package.fileName -Leaf)
            $null = Set-StoreFile -FilePath (Join-Path -Path $PackageRootPath -ChildPath $package.fileName) -SasUri $packageSubmission.fileSasUri -NoStatus:$NoStatus
            $packageSubmission.state = [StoreBrokerFileState]::Uploaded.ToString()
            $null = Set-ProductPackage @params -Object $packageSubmission
        }

        # Record the telemetry for this event.
        $stopwatch.Stop()
        $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::PackageRootPath = (Get-PiiSafeString -PlainText $PackageRootPath)
            [StoreBrokerTelemetryProperty]::AddPackages = ($AddPackages -eq $true)
            [StoreBrokerTelemetryProperty]::ReplacePackages = ($ReplacePackages -eq $true)
            [StoreBrokerTelemetryProperty]::UpdatePackages = ($UpdatePackages -eq $true)
            [StoreBrokerTelemetryProperty]::RedundantPackagesToKeep = $RedundantPackagesToKeep
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        Set-TelemetryEvent -EventName Update-ProductPackage -Properties $telemetryProperties -Metrics $telemetryMetrics
        return
    }
    catch
    {
        throw
    }
}
