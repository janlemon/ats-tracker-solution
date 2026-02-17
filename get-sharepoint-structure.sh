#!/bin/bash
# SharePoint REST API - Get List Structure
# Alternative to PowerShell - uses curl and SharePoint REST API

SITE_URL="https://ezpada.sharepoint.com/sites/ats"
OUTPUT_FILE="./sharepoint-structure.json"

# List IDs from environment variables
declare -A LISTS=(
    ["Requests"]="8abbb77f-a11b-4bce-bde7-c87023abbd60"
    ["Roles"]="d83f42f7-04a7-4e5e-ad36-9a6dd976c74b"
)

echo "=== SharePoint REST API Structure Extractor ==="
echo "Site: $SITE_URL"
echo ""
echo "This script will show you the REST API URLs to call."
echo "You need to get an access token first."
echo ""

# Function to show how to get access token
show_token_instructions() {
    cat << EOF
To get an access token, run this in PowerShell:

# Install if needed
Install-Module MSAL.PS -Force -Scope CurrentUser

# Get token
\$token = Get-MsalToken -ClientId "450746a9-62b1-41ea-9e69-d010ac922853" \\
    -TenantId "your-tenant-id" \\
    -Scopes "https://ezpada.sharepoint.com/.default" \\
    -Interactive

# Copy this:
\$token.AccessToken

Then set it here:
export SHAREPOINT_TOKEN="your-token-here"

EOF
}

# Check if token is set
if [ -z "$SHAREPOINT_TOKEN" ]; then
    echo "Error: SHAREPOINT_TOKEN environment variable not set"
    echo ""
    show_token_instructions
    exit 1
fi

echo "Fetching list structures..."
echo ""

# Start JSON output
echo "{" > $OUTPUT_FILE
echo "  \"SiteUrl\": \"$SITE_URL\"," >> $OUTPUT_FILE
echo "  \"ExtractedDate\": \"$(date '+%Y-%m-%d %H:%M:%S')\"," >> $OUTPUT_FILE
echo "  \"Lists\": {" >> $OUTPUT_FILE

first=true
for list_name in "${!LISTS[@]}"; do
    list_id="${LISTS[$list_name]}"
    
    echo "Fetching: $list_name (ID: $list_id)"
    
    # Add comma if not first
    if [ "$first" = false ]; then
        echo "," >> $OUTPUT_FILE
    fi
    first=false
    
    # Get list fields
    api_url="${SITE_URL}/_api/web/lists(guid'${list_id}')/fields?\$filter=Hidden eq false and ReadOnlyField eq false&\$select=Title,InternalName,TypeAsString,Required,Choices"
    
    echo "    \"$list_name\": {" >> $OUTPUT_FILE
    
    # Fetch data
    response=$(curl -s -X GET "$api_url" \
        -H "Authorization: Bearer $SHAREPOINT_TOKEN" \
        -H "Accept: application/json;odata=verbose")
    
    # Extract fields (simplified)
    echo "      \"Id\": \"$list_id\"," >> $OUTPUT_FILE
    echo "      \"Fields\": $response" >> $OUTPUT_FILE
    echo -n "    }" >> $OUTPUT_FILE
    
    echo "  ✓ Done"
done

echo "" >> $OUTPUT_FILE
echo "  }" >> $OUTPUT_FILE
echo "}" >> $OUTPUT_FILE

echo ""
echo "✓ Structure saved to: $OUTPUT_FILE"
