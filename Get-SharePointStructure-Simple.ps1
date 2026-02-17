# Simplified SharePoint Structure Extractor - Only specific lists
param(
    [string]$SiteUrl = "https://ezpada.sharepoint.com/sites/ats",
    [string]$OutputPath = "./sharepoint-structure.json",
    [string]$ClientId = "450746a9-62b1-41ea-9e69-d010ac922853"
)

Write-Host "=== SharePoint Structure Extractor (Simple) ===" -ForegroundColor Cyan

# Check if PnP.PowerShell is installed
if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    Write-Host "Installing PnP.PowerShell module..." -ForegroundColor Yellow
    Install-Module -Name PnP.PowerShell -Force -Scope CurrentUser -AllowClobber
}

Import-Module PnP.PowerShell

try {
    Write-Host "Connecting to SharePoint..." -ForegroundColor Green
    Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Interactive
    
    # Only analyze these specific lists
    $listsToAnalyze = @(
        @{ Name = "Requests"; Id = "8abbb77f-a11b-4bce-bde7-c87023abbd60" }
        @{ Name = "Roles"; Id = "d83f42f7-04a7-4e5e-ad36-9a6dd976c74b" }
    )
    
    $structure = @{
        SiteUrl = $SiteUrl
        ExtractedDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Lists = @{}
    }
    
    foreach ($listInfo in $listsToAnalyze) {
        Write-Host "`nAnalyzing: $($listInfo.Name)..." -ForegroundColor Cyan
        
        try {
            # Get list by ID
            $list = Get-PnPList -Identity $listInfo.Id -ErrorAction Stop
            
            # Get only key fields (not hidden)
            $fields = Get-PnPField -List $list | 
                Where-Object { 
                    -not $_.Hidden -and 
                    $_.InternalName -notlike "_*" -and
                    $_.InternalName -notlike "ows*"
                } | 
                Select-Object -First 30 Title, InternalName, TypeAsString, Required, 
                    @{Name='Choices'; Expression={
                        if ($_.TypeAsString -match 'Choice') { $_.Choices } else { $null }
                    }}
            
            # Get just 3 sample items
            $sampleItems = Get-PnPListItem -List $list -PageSize 3 -Fields "ID","Title" -ErrorAction Stop | 
                Select-Object -First 3 | 
                ForEach-Object {
                    @{
                        Id = $_.Id
                        Title = $_["Title"]
                    }
                }
            
            $structure.Lists[$listInfo.Name] = @{
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
                SampleItemCount = $sampleItems.Count
            }
            
            Write-Host "  ✓ Fields: $($fields.Count)" -ForegroundColor Green
            
        } catch {
            Write-Host "  ✗ Error: $_" -ForegroundColor Red
        }
    }
    
    # Export to JSON
    Write-Host "`nExporting to: $OutputPath" -ForegroundColor Cyan
    $structure | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "✓ Done!" -ForegroundColor Green
    
    Disconnect-PnPOnline
    
} catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
    exit 1
}
