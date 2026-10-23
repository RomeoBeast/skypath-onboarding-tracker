// Without sharing: must see every onboarding to avoid duplicates, whoever closes the deal
public without sharing class OnboardingCreationService {

    public static void createForNewlyWon(List<Opportunity> opportunities, Map<Id, Opportunity> oldMap) {
        Map<Id, Opportunity> newlyWonById = new Map<Id, Opportunity>();
        for (Opportunity opp : opportunities) {
            Boolean wasWon = oldMap != null && oldMap.get(opp.Id).IsWon;
            if (opp.IsWon && !wasWon) {
                newlyWonById.put(opp.Id, opp);
            }
        }
        if (newlyWonById.isEmpty()) {
            return;
        }

        // A deal that was re-opened and won again already has its onboarding
        for (Onboarding__c existing : [
            SELECT Opportunity__c FROM Onboarding__c WHERE Opportunity__c IN :newlyWonById.keySet() WITH SYSTEM_MODE
        ]) {
            newlyWonById.remove(existing.Opportunity__c);
        }

        List<Opportunity> wonDeals = newlyWonById.values();
        List<Onboarding__c> onboardings = new List<Onboarding__c>();
        for (Opportunity opp : wonDeals) {
            onboardings.add(new Onboarding__c(
                Opportunity__c = opp.Id,
                Opportunity_Key__c = String.valueOf(opp.Id),
                Account__c = opp.AccountId,
                Target_Launch_Date__c = opp.CloseDate.addDays(OnboardingSettings.launchOffsetDays),
                Stage__c = OnboardingStages.KICKOFF_SCHEDULED
            ));
        }

        // Partial success: one bad row fails only its own deal, not the whole Data Loader batch
        // System mode: the user closing the deal may have no access to onboarding fields
        List<Database.SaveResult> results = Database.insert(onboardings, false, AccessLevel.SYSTEM_MODE);
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                continue;
            }
            Database.Error error = results[i].getErrors()[0];
            // Another transaction created it first; the unique key did its job
            if (error.getStatusCode() == StatusCode.DUPLICATE_VALUE) {
                continue;
            }
            wonDeals[i].addError('Onboarding could not be created: ' + error.getMessage());
        }
    }
}