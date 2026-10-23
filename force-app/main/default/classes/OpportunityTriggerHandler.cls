public with sharing class OpportunityTriggerHandler extends TriggerHandler {

    protected override void afterInsert(List<SObject> newRecords) {
        OnboardingCreationService.createForNewlyWon((List<Opportunity>) newRecords, null);
    }

    protected override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        OnboardingCreationService.createForNewlyWon((List<Opportunity>) newRecords, (Map<Id, Opportunity>) oldMap);
    }
}