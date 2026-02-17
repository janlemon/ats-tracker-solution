# PowerShell Script to download SharePoint list structure
# This will help understand the schema for creating Power Automate flows

# Required module: PnP.PowerShell
# Install if needed: Install-Module -Name PnP.PowerShell -Force -Scope CurrentUser

param(
    [string]$SiteUrl = "https://ezpada.sharepoint.com/sites/ats",
    [string]$OutputPath = "./sharepoint-structure.json",
    [string]$ClientId = "450746a9-62b1-41ea-9e69-d010ac922853",
    [string]$ClientSecret = "",
    [string]$TenantId = ""
)

Write-Host "=== SharePoint Structure Extractor ===" -ForegroundColor Cyan
Write-Host "Site: $SiteUrl" -ForegroundColor Yellow

# Check if PnP.PowerShell is installed
if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    Write-Host "PnP.PowerShell module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name PnP.PowerShell -Force -Scope CurrentUser -AllowClobber
}

Import-Module PnP.PowerShell

try {
    # Connect to SharePoint
    Write-Host "`nConnecting to SharePoint..." -ForegroundColor Green
    
    if ($ClientSecret -and $TenantId) {
        # Use App Registration with Client Secret
        Write-Host "Using App Registration authentication (Client ID: $ClientId)" -ForegroundColor Yellow
        $secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
        Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -ClientSecret $secureSecret -WarningAction SilentlyContinue
    }
    elseif ($ClientId) {
        # Use interactive authentication with Client ID
        Write-Host "Using interactive authentication with Client ID: $ClientId" -ForegroundColor Yellow
        Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Interactive
    }
    else {
        # Use default interactive authentication
        Write-Host "Using default interactive authentication" -ForegroundColor Yellow
        Connect-PnPOnline -Url $SiteUrl -Interactive
    }
    
    # Define the lists we want to analyze (from environment variables)
    $listIds = @{
        "Requests" = "8abbb77f-a11b-4bce-bde7-c87023abbd60"
        "Roles" = "d83f42f7-04a7-4e5e-ad36-9a6dd976c74b"
        "CommitteeApprovals" = "" # Add ID if known
        "Messages" = "" # Add ID if known
    }
    
    $structure = @{
        SiteUrl = $SiteUrl
        ExtractedDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Lists = @{}
    }
    
    # Get all lists to find the ones we need
    Write-Host "`nRetrieving all lists..." -ForegroundColor Green
    $allLists = Get-PnPList | Where-Object { -not $_.Hidden }
    
    foreach ($list in $allLists) {
        Write-Host "`nAnalyzing list: $($list.Title)" -ForegroundColor Cyan
        Write-Host "  ID: $($list.Id)" -ForegroundColor Gray
        
        # Get list fields
        $fields = Get-PnPField -List $list.Title | Where-Object { 
            -not $_.Hidden -and 
            $_.Group -ne "_Hidden" -and
            $_.InternalName -notlike "_*"
        } | Select-Object Title, InternalName, TypeAsString, Required, @{
            Name='Choices'; 
            Expression={
                if ($_.TypeAsString -eq 'Choice' -or $_.TypeAsString -eq 'MultiChoice') {
                    $_.Choices
                } else {
                    $null
                }
            }
        }
        
        # Get sample items (max 5)
        Write-Host "  Fetching sample items..." -ForegroundColor Gray
        $sampleItems = Get-PnPListItem -List $list.Title -PageSize 5 | Select-Object -First 5 | ForEach-Object {
            $item = @{
                Id = $_.Id
                Fields = @{}
            }
            
            foreach ($field in $fields) {
                $fieldValue = $_[$field.InternalName]
                
                # Handle special field types
                if ($fieldValue -is [Microsoft.SharePoint.Client.FieldUserValue]) {
                    $item.Fields[$field.InternalName] = @{
                        DisplayName = $fieldValue.LookupValue
                        Email = $fieldValue.Email
                    }
                }
                elseif ($fieldValue -is [Microsoft.SharePoint.Client.FieldLookupValue]) {
                    $item.Fields[$field.InternalName] = @{
                        LookupId = $fieldValue.LookupId
                        LookupValue = $fieldValue.LookupValue
                    }
                }
                else {
                    $item.Fields[$field.InternalName] = $fieldValue
                }
            }
            
            $item
        }
        
        # Add to structure
        $structure.Lists[$list.Title] = @{
            Id = $list.Id.ToString()
            Title = $list.Title
            ItemCount = $list.ItemCount
            Fields = $fields | ForEach-Object {
                @{
                    Title = $_.Title
                    InternalName = $_.InternalName
                    Type = $_.TypeAsString
                    Required = $_.Required
                    Choices = $_.Choices
                }
            }
            SampleItems = $sampleItems
        }
        
        Write-Host "  ✓ Found $($fields.Count) fields" -ForegroundColor Green
        Write-Host "  ✓ Retrieved $($sampleItems.Count) sample items" -ForegroundColor Green
    }
    
    # Export to JSON
    Write-Host "`nExporting structure to: $OutputPath" -ForegroundColor Cyan
    $structure | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "`n✓ Structure exported successfully!" -ForegroundColor Green
    Write-Host "`nSummary:" -ForegroundColor Yellow
    Write-Host "  Total lists analyzed: $($structure.Lists.Count)" -ForegroundColor White
    
    foreach ($listName in $structure.Lists.Keys) {
        $listInfo = $structure.Lists[$listName]
        Write-Host "  - $listName`: $($listInfo.Fields.Count) fields, $($listInfo.ItemCount) items" -ForegroundColor White
    }
    
    # Disconnect
    Disconnect-PnPOnline
    
} catch {
    Write-Host "`n✗ Error: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "`nDone! You can now review the structure in: $OutputPath" -ForegroundColor Green
