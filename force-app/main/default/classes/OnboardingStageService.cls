public inherited sharing class OnboardingStageService {

    @TestVisible
    private static Datetime clockOverride;

    public static void trackStageChanges(List<Onboarding__c> onboardings, Map<Id, Onboarding__c> oldMap) {
        Datetime now = clockOverride ?? Datetime.now();
        for (Onboarding__c onboarding : onboardings) {
            if (onboarding.Stage__c == null) {
                onboarding.Stage__c = OnboardingStages.KICKOFF_SCHEDULED;
            }
            String previousStage = oldMap?.get(onboarding.Id)?.Stage__c;
            if (onboarding.Stage__c == previousStage) {
                continue;
            }

            onboarding.Current_Stage_Entered_On__c = now;

            // First reached is set once and never moved, even after going back
            Schema.SObjectField firstReachedField = OnboardingStages.FIRST_REACHED_FIELD.get(onboarding.Stage__c);
            if (onboarding.get(firstReachedField) == null) {
                onboarding.put(firstReachedField, now);
            }

            if (OnboardingStages.isBackward(previousStage, onboarding.Stage__c)) {
                onboarding.QA_Rework_Count__c = (onboarding.QA_Rework_Count__c ?? 0) + 1;
            }
        }
    }
}