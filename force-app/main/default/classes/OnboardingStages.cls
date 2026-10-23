public inherited sharing class OnboardingStages {

    public static final String KICKOFF_SCHEDULED = 'Kickoff Scheduled';
    public static final String GATHERING_INFO = 'Gathering Info';
    public static final String IMPLEMENTATION = 'Implementation';
    public static final String QA_REVIEW = 'QA / Review';
    public static final String GO_LIVE = 'Go Live';
    public static final String POST_LAUNCH_REVIEW = 'Post-Launch Review';

    public static final List<String> ORDERED = new List<String>{
        KICKOFF_SCHEDULED, GATHERING_INFO, IMPLEMENTATION, QA_REVIEW, GO_LIVE, POST_LAUNCH_REVIEW
    };

    public static final Map<String, Schema.SObjectField> FIRST_REACHED_FIELD = new Map<String, Schema.SObjectField>{
        KICKOFF_SCHEDULED => Onboarding__c.Kickoff_Scheduled_Reached_On__c,
        GATHERING_INFO => Onboarding__c.Gathering_Info_Reached_On__c,
        IMPLEMENTATION => Onboarding__c.Implementation_Reached_On__c,
        QA_REVIEW => Onboarding__c.QA_Review_Reached_On__c,
        GO_LIVE => Onboarding__c.Go_Live_Reached_On__c,
        POST_LAUNCH_REVIEW => Onboarding__c.Post_Launch_Review_Reached_On__c
    };

    public static Boolean isBackward(String fromStage, String toStage) {
        return fromStage != null && ORDERED.indexOf(toStage) < ORDERED.indexOf(fromStage);
    }
}