# SkyPath AI – Customer Onboarding Tracker

Salesforce build for the Revinfinity developer test. Every won Opportunity gets an onboarding automatically, which is assigned to the eligible CSM with the fewest active onboardings (respecting per-CSM capacity), moves through an enforced six-stage process, and records when each stage was first reached for standard reports.

The design write-up (data model, automation choices, assignment logic, assumptions log, limitations) is submitted separately.

## What's in the project
| Area | Components |
|---|---|
| Data model | `Onboarding__c`, `CSM_Capacity__c`, `Onboarding_Setting__mdt` (+ `Default` record) |
| Automation | `OpportunityTrigger`, `OnboardingTrigger` → handlers → service classes; flow `CSM_Capacity_Set_User_Key`; 6 validation rules |
| Assignment | `CsmAssignmentService`, `BacklogNotifier`, queue `CS_Onboarding_Backlog`, group `CS_Managers`, notification `Onboarding_Backlog_Alert` |
| UI | App and record page **Revinfinity \| Onboarding Tracker**, Path with guidance, compact layout |
| Reporting | `OnboardingReports` folder (3 reports), `OnboardingDashboards` folder (CS Onboarding Overview) |
| Access | Permission sets `Onboarding_CSM`, `Onboarding_Manager` |
| Tests | `CsmAssignmentService_Test`, `OnboardingCreationService_Test`, `OnboardingStageService_Test`, `TestDataFactory` |

## Prerequisites
- Salesforce CLI (`sf`)
- A Developer Edition org (or any org you control)

## Deploy
```bash
sf org login web -a skypath
sf project deploy start -o skypath
```

## Run the tests
```bash
sf apex run test -o skypath --test-level RunLocalTests --code-coverage --result-format human --wait 10
```
Includes a test that closes 200 opportunities in one transaction and checks the spread and capacity limits.

## Manual steps after deploy
These cannot be deployed because they reference users that differ per org.

1. **Assign permission sets**
   - `Onboarding_CSM` → each Customer Success Manager
   - `Onboarding_Manager` → CS managers and admins
2. **Add CS managers to the public group `CS Managers`** (Setup → Public Groups). They receive the backlog alert and can work the `CS Onboarding Backlog` queue.
3. **Register CSMs**: App Launcher → *CSM Capacities* → New, one record per CSM:
   - User: the CSM
   - Max Active Onboardings: e.g. 4 for a new hire, 10 for a senior CSM
   - Is Eligible: ticked
Admin.profile-meta.xml
## Admin how-to (no developer needed)
| Task | How |
|---|---|
| Add a CSM | Assign `Onboarding_CSM`, then create a CSM Capacity record |
| Remove a CSM temporarily | Untick **Is Eligible** on their CSM Capacity record |
| Remove a CSM permanently | Delete their CSM Capacity record |
| Change someone's capacity | Edit **Max Active Onboardings** |
| Change the default launch offset (60 days) | Setup → Custom Metadata Types → Onboarding Setting → Default |

## Demo data
```bash
# 215 open demo deals with accounts
sf apex run -o skypath -f scripts/apex/create-demo-opportunities.apex
# remove all demo data afterwards
sf apex run -o skypath -f scripts/apex/reset-demo-data.apex
```
To simulate the quarter-end bulk close, export 200 of the demo opportunity Ids and update `StageName` to `Closed Won` with Data Loader (or `sf data update bulk`).

## Assumptions in brief
- A reopened or lost deal keeps its onboarding; re-winning never creates a second one.
- Backlog items are assigned by CS managers by hand.
- Target launch date defaults to Close Date + 60 days and is corrected by the CSM.

Full reasoning is in the design write-up.
