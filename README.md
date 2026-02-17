# ATS Tracker - Power Platform Solution

Power Platform solution for ATS (Algorithmic Trading System) request management and approval workflow.

## Related Repositories

- 🎨 **Canvas App (React)**: [ATS-CodeApp](https://github.com/janlemon/ATS-CodeApp) - React-based frontend application
- 🔧 **Power Platform Solution**: This repository - Workflows, environment variables, and solution components

## Description

This solution provides a complete system for managing and tracking ATS requests through multiple review stages (IT, Market Risk, Compliance, Committee) with automated notifications and approvals.

## Components

### Canvas App

- **ATS Tracker** - React-based CodeComponent Power App for request management
- Located in: `extracted/CanvasApps/crbbf_atstracker_65250_CodeAppPackages/`
- Source code repository: [ATS-CodeApp](https://github.com/janlemon/ATS-CodeApp)

### Power Automate Flows

1. **Flow-ATSSubmitted-NotifyReviewers** - Notifies reviewers when new ATS request is submitted
2. **Flow-ATSTeamApproval-Notify** - Notifies Compliance team when IT/Market Risk/Committee approves

### Environment Variables

- `jlem_ATS_Environment` - DEV | PROD environment selector
- `jlem_ENV_ATS_Tracker_SharePointSite` - SharePoint site URL
- `jlem_ENV_ATS_SharePointList_Requests` - Requests list GUID
- `jlem_ENV_ATS_SharePointList_Roles` - Roles list GUID
- `jlem_ENV_ATS_SharePointList_CommitteeApprovals` - Committee approvals list GUID
- `jlem_ENV_ATS_Tracker_SharePointList_Messages` - Messages list GUID

### Connection References

- `jlem_ConnRef_ATS_Tracker_Sharepoint` - SharePoint connection
- `jlem_ConnRefATSTrackerOutlook` - Office 365 Outlook connection

## Structure

```
Solution_ATSProjects/
├── extracted/                          # Extracted solution components
│   ├── CanvasApps/                     # Canvas app (submodule)
│   ├── Workflows/                      # Power Automate flows
│   ├── environmentvariabledefinitions/ # Environment variables
│   ├── solution.xml                    # Solution manifest
│   └── customizations.xml              # Customizations
├── Get-SharePointStructure.ps1         # PowerShell script to download SP structure
├── Get-SharePointStructure-Simple.ps1  # Simplified version for specific lists
└── get-sharepoint-structure.sh         # Bash alternative using REST API
```

## Deployment

### Prerequisites

- Power Platform CLI (`pac`)
- PowerShell with PnP.PowerShell module (for SharePoint scripts)
- Access to target Power Platform environment
- SharePoint site with required lists

### Import Solution

1. Authenticate to Power Platform:

   ```bash
   pac auth create --environment <your-environment-url>
   ```

2. Import solution:

   ```bash
   pac solution import --path <solution-zip> --force-overwrite
   ```

3. Configure connections and environment variables in Power Platform admin center

### Export Solution

```bash
pac solution export --name ATSTracker --path ATSTracker.zip --managed false
```

### Extract Solution for Version Control

```bash
unzip -q ATSTracker.zip -d extracted
```

## Development Workflow

1. Make changes in Power Platform portal (canvas app, flows, etc.)
2. Export solution using `pac solution export`
3. Extract to `extracted/` folder
4. Commit changes to Git
5. For Canvas app changes, also update the submodule repository

## SharePoint Structure

Use the provided PowerShell scripts to download the SharePoint list structure for reference:

```powershell
.\Get-SharePointStructure-Simple.ps1 -ClientId "<your-client-id>"
```

## Environment Configuration

### DEV Environment

- Emails sent to: `jan.lemon@ezpada.com`
- Environment variable: `ATS_Environment = DEV`

### PROD Environment

- Emails sent to actual user emails from Roles list
- Environment variable: `ATS_Environment = PROD`

## Version History

- **1.0.0.3** - Current version
  - Initial canvas app
  - Submit notification flow
  - Team approval notification flow

## License

Proprietary - Ezpada Group

## Contact

Jan Lemon - j.lemon@email.cz
