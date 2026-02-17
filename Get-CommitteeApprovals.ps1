Import-Module PnP.PowerShell

Connect-PnPOnline -Url 'https://ezpada.sharepoint.com/sites/ats' -ClientId '450746a9-62b1-41ea-9e69-d010ac922853' -Interactive

$list = Get-PnPList -Identity 'Committee Approvals Test'

Write-Host "=== Committee Approvals Fields ===" -ForegroundColor Cyan
$fields = Get-PnPField -List $list | 
    Where-Object { -not $_.Hidden -and $_.InternalName -notlike "_*" } | 
    Select-Object -First 30 Title, InternalName, TypeAsString, 
        @{Name='Choices'; Expression={
            if ($_.TypeAsString -match 'Choice') { $_.Choices } else { $null }
        }}

$fields | Format-Table -AutoSize

Write-Host ""
Write-Host "=== Sample Item ===" -ForegroundColor Cyan
$item = Get-PnPListItem -List $list -PageSize 1 | Select-Object -First 1
$item.FieldValues.GetEnumerator() | 
    Where-Object { $_.Key -notlike "_*" -and $_.Key -notlike "ows*" } |
    ForEach-Object { 
        Write-Host "$($_.Key): $($_.Value)" 
    }

Disconnect-PnPOnline
