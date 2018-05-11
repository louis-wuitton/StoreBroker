Add-Type -TypeDefinition @"
   public enum StoreBrokerSubmissionProperty
   {
       certificationNotes,
       flightId,
       isAutoPromote,
       isManualPublish,
       releaseTimeInUtc,
       resourceType,
       revisionToken,
       sandboxId,
       scope
   }
"@

function Get-Submission
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Search")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(ParameterSetName="Search")]
        [string] $FlightId,

        [Parameter(ParameterSetName="Search")]
        [string] $SandboxId,

        [Parameter(ParameterSetName="Search")]
        [ValidateSet('InProgress', 'Published')]
        [string] $Type,

        [Parameter(ParameterSetName="Search")]
        [ValidateSet('Live', 'Preview')]  # Preview is currently limited to Azure
        [string] $Scope = 'Live',

        [Parameter(
            Mandatory,
            ParameterSetName="Known")]
        [string] $SubmissionId,

        [Parameter(ParameterSetName="Known")]
        [switch] $Detail,

        [Parameter(ParameterSetName="Known")]
        [switch] $Reports,

        [Parameter(ParameterSetName="Known")]
        [switch] $Validation,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [Parameter(ParameterSetName="Search")]
        [switch] $SinglePage,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $singleQuery = (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::FlightId = $FlightId
            [StoreBrokerTelemetryProperty]::SandboxId = $SandboxId
            [StoreBrokerTelemetryProperty]::Type = $Type
            [StoreBrokerTelemetryProperty]::Scope = $Scope
            [StoreBrokerTelemetryProperty]::GetDetail = $Detail
            [StoreBrokerTelemetryProperty]::GetReports = $Reports
            [StoreBrokerTelemetryProperty]::GetValidation = $Validation
            [StoreBrokerTelemetryProperty]::SingleQuery = $singleQuery
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        $getParams += "scope=$Scope"

        if (-not [String]::IsNullOrWhiteSpace($FlightId))
        {
            $getParams += "flightId=$FlightId"
        }

        if (-not [String]::IsNullOrWhiteSpace($SandboxId))
        {
            $getParams += "sandboxId=$SandboxId"
        }

        if (-not [String]::IsNullOrWhiteSpace($Type))
        {
            $getParams += "type=$Type"
        }

        $params = @{
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-Submission"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        if ($singleQuery)
        {
            $params["UriFragment"] = "products/$ProductId/submissions/$SubmissionId"
            $params["Method" ] = 'Get'
            $params["Description"] =  "Getting submission $SubmissionId for $ProductId"

            Write-Output (Invoke-SBRestMethod @params)

            $params = @{
                'ProductId' = $ProductId
                'SubmissionId' = $SubmissionId
                'ClientRequestId' = $ClientRequesId
                'CorrelationId' = $CorrelationId
                'AccessToken' = $AccessToken
                'NoStatus' = $NoStatus
            }

            if ($Detail)
            {
                Write-Output (Get-SubmissionDetail @params)
            }

            if ($Reports)
            {
                Write-Output (Get-SubmissionReport @params)
            }

            if ($Validation)
            {
                Write-Output (Get-SubmissionValidation @params)
            }
        }
        else
        {
            $params["UriFragment"] = "products/$ProductId/submissions`?" + ($getParams -join '&')
            $params["Description"] =  "Getting submissions for $ProductId"
            $params["SinglePage" ] = $SinglePage

            return Invoke-SBRestMethodMultipleResult @params
        }
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function New-Submission
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Retail')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName = 'Retail',
            Position = 0)]
        [Parameter(
            Mandatory,
            ParameterSetName = 'Flight',
            Position = 0)]
        [Parameter(
            Mandatory,
            ParameterSetName = 'Sandbox',
            Position = 0)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Flight',
            Position = 1)]
        [string] $FlightId,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Sandbox',
            Position = 1)]
        [string] $SandboxId,


        [Parameter(
            ParameterSetName = 'Retail',
            Position = 2)]
        [Parameter(
            ParameterSetName = 'Flight',
            Position = 3)]
        [Parameter(
            ParameterSetName = 'Sandbox',
            Position = 3)]
        [ValidateSet('Live', 'Preview')]  # Preview is currently limited to Azure
        [string] $Scope = 'Live',

        [Parameter(
            ParameterSetName = 'Retail',
            Position = 3)]
        [Parameter(
            ParameterSetName = 'Flight',
            Position = 4)]
        [Parameter(
            ParameterSetName = 'Sandbox',
            Position = 4)]
        [int] $WaitSeconds = -1, # 0 means no wait.  We'll use -1 to indicate not to send it, which causes it to use the server side default of 60 seconds.

        [Parameter(
            ParameterSetName = 'Retail',
            Position = 4)]
        [Parameter(
            ParameterSetName = 'Flight',
            Position = 5)]
        [Parameter(
            ParameterSetName = 'Sandbox',
            Position = 5)]
        [string] $ClientRequestId,

        [Parameter(ParameterSetName = 'Retail')]
        [Parameter(ParameterSetName = 'Flight')]
        [Parameter(ParameterSetName = 'Sandbox')]
        [string] $CorrelationId,

        [Parameter(ParameterSetName = 'Retail')]
        [Parameter(ParameterSetName = 'Flight')]
        [Parameter(ParameterSetName = 'Sandbox')]
        [switch] $Force,

        [Parameter(ParameterSetName = 'Retail')]
        [Parameter(ParameterSetName = 'Flight')]
        [Parameter(ParameterSetName = 'Sandbox')]
        [string] $AccessToken,

        [Parameter(ParameterSetName = 'Retail')]
        [Parameter(ParameterSetName = 'Flight')]
        [Parameter(ParameterSetName = 'Sandbox')]
        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::FlightId = $FlightId
        [StoreBrokerTelemetryProperty]::SandboxId = $SandboxId
        [StoreBrokerTelemetryProperty]::Scope = $Scope
        [StoreBrokerTelemetryProperty]::WaitSeconds = $WaitSeconds
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    # TODO: Get force working once flight is implemented
    if ($Force)
    {
        $message = "-Force is not implemented yet"
        Write-Log -Message $message -Level Error
        throw $message
    }

    if ([System.String]::IsNullOrEmpty($AccessToken))
    {
        $AccessToken = Get-AccessToken -NoStatus:$NoStatus
    }

    $getParams = @()
    if ($WaitSeconds -ge 0)
    {
        $getParams += "waitSeconds=$WaitSeconds"
    }

    # Convert the input into a Json body.
    $hashBody = @{}
    $hashBody[[StoreBrokerSubmissionProperty]::resourceType] = [StoreBrokerResourceType]::Submission
    $hashBody[[StoreBrokerSubmissionProperty]::scope] = $Scope

    if (-not [String]::IsNullOrWhiteSpace($FlightId))
    {
        $hashBody[[StoreBrokerSubmissionProperty]::flightId] = $FlightId
    }

    if (-not [String]::IsNullOrWhiteSpace($SandboxId))
    {
        $hashBody[[StoreBrokerSubmissionProperty]::sandboxId] = $SandboxId
    }

    $body = $hashBody | ConvertTo-Json
    Write-Log -Message "Body: $body" -Level Verbose

    $params = @{
        "UriFragment" = "products/$ProductId/submissions`?" + ($getParams -join '&')
        "Method" = 'Post'
        "Description" = "Creating a new submision for product: $ProductId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "New-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Remove-Submission
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias("Delete-Submission")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId"
        "Method" = "Delete"
        "Description" = "Deleting submission $SubmissionId for product: $ProductId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Remove-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    $null = Invoke-SBRestMethod @params
}

function Stop-Submission
{
    [Alias('Cancel-Submission')]
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/cancel"
        "Method" = 'Post'
        "Description" = "Cancelling submission $SubmissionId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Stop-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Get-SubmissionDetail
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

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
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/submissions/$SubmissionId/detail"
            "Method" = 'Get'
            "Description" = "Getting details of submission $SubmissionId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-SubmissionDetail"
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

function Set-SubmissionDetail
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        # $null means leave as-is, empty string means clear it out.
        [Parameter(ParameterSetName="Individual")]
        [string] $CertificationNotes = $null,

        [Parameter(ParameterSetName="Individual")]
        [DateTime] $ReleaseDate,

        [Parameter(ParameterSetName="Individual")]
        [switch] $ManualPublish,

        # This is only relevant for sandboxes
        [Parameter(ParameterSetName="Individual")]
        [switch] $AutoPromote,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
        [StoreBrokerTelemetryProperty]::UpdateCertificationNotes = ($null -ne $CertificationNotes)
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Test-ResourceType -Object $Object -ResourceType [StoreBrokerResourceType]::PackageFlight

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerSubmissionProperty]::resourceType] = [StoreBrokerResourceType]::SubmissionDetail

        if ($null -ne $ReleaseDate)
        {
            $hashBody[[StoreBrokerSubmissionProperty]::releaseTimeInUtc] = $ReleaseDate.ToUniversalTime().ToString('o')
        }

        # Very specifically choosing to NOT use [String]::IsNullOrWhiteSpace here, because
        # we need a way to be able to clear these notes out.  So, a $null means do nothing,
        # while empty string / whitespace means clear out the notes.
        if ($null -ne $CertificationNotes)
        {
            $hashBody[[StoreBrokerSubmissionProperty]::certificationNotes] = $CertificationNotes
        }

        # We only set the value if the user explicitly provided a value for this parameter
        # (so for $false, they'd have to pass in -ManualPublish:$false).
        # Otherwise, there'd be no way to know when the user wants to simply keep the
        # existing value.
        if ($null -ne $PSBoundParameters['ManualPublish'])
        {
            $hashBody[[StoreBrokerSubmissionProperty]::isManualPublish] = $ManualPublish
            $telemetryProperties[[StoreBrokerTelemetryProperty]::IsManualPublish] = $ManualPublish
        }

        # We only set the value if the user explicitly provided a value for this parameter
        # (so for $false, they'd have to pass in -AutoPromote:$false).
        # Otherwise, there'd be no way to know when the user wants to simply keep the
        # existing value.
        if ($null -ne $PSBoundParameters['AutoPromote'])
        {
            $hashBody[[StoreBrokerSubmissionProperty]::isAutoPromote] = $AutoPromote
            $telemetryProperties[[StoreBrokerTelemetryProperty]::IsAutoPromote] = $AutoPromote
        }
    }

    $body = $hashBody | ConvertTo-Json
    Write-Log -Message "Body: $body" -Level Verbose

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/detail"
        "Method" = 'Put'
        "Description" = "Updating detail for submission: $SubmissionId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Set-SubmissionDetail"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

# This is only relevant for sandboxes
function Push-Submission
{
    [Alias('Promote-Submission')]
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/promote"
        "Method" = 'Post'
        "Description" = "Promoting submission $SubmissionId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Push-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Publish-Submission
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/publish"
        "Method" = 'Post'
        "Description" = "Publishing submission $SubmissionId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Publish-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Get-SubmissionReport
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

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
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/submissions/$SubmissionId/reports"
            "Description" = "Getting reports of submission $SubmissionId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-SubmissionReport"
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

function Submit-Submission
{
    [Alias('Commit-Submission')]
    [Alias('Copmlete-Submission')]
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $Auto,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::Auto = $Auto
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if ($Auto)
    {
        $getParams += "auto=$Auto"
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/submit`?" + ($getParams -join '&')
        "Method" = 'Post'
        "Description" = "Submitting submission $SubmissionId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Submit-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Get-SubmissionValidation
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

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
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/submissions/$SubmissionId/validation"
            "Method" = 'Get'
            "Description" = "Getting validation of submission $SubmissionId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-SubmissionValidation"
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
