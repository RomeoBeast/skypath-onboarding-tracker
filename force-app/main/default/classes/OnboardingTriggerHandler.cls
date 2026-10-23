public with sharing class OnboardingTriggerHandler extends TriggerHandler {

    protected override void beforeInsert(List<SObject> newRecords) {
        List<Onboarding__c> onboardings = (List<Onboarding__c>) newRecords;
        OnboardingStageService.trackStageChanges(onboardings, null);
        OnboardingNamingService.applyNames(onboardings, null);
        CsmAssignmentService.assignOwners(onboardings);
    }

    protected override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Onboarding__c> onboardings = (List<Onboarding__c>) newRecords;
        Map<Id, Onboarding__c> oldOnboardings = (Map<Id, Onboarding__c>) oldMap;
        OnboardingStageService.trackStageChanges(onboardings, oldOnboardings);
        OnboardingNamingService.applyNames(onboardings, oldOnboardings);
    }

    protected override void afterInsert(List<SObject> newRecords) {
        BacklogNotifier.notifyManagers((List<Onboarding__c>) newRecords);
    }
}