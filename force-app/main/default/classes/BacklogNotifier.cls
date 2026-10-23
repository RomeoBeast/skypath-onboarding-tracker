public without sharing class BacklogNotifier {

    @TestVisible
    private static Integer notificationsQueued = 0;

    public static void notifyManagers(List<Onboarding__c> onboardings) {
        List<Onboarding__c> backlogged = new List<Onboarding__c>();
        for (Onboarding__c onboarding : onboardings) {
            if (onboarding.OwnerId == OnboardingSettings.backlogQueueId) {
                backlogged.add(onboarding);
            }
        }
        if (backlogged.isEmpty()) {
            return;
        }

        // One alert per batch, not one per record
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(OnboardingSettings.notificationTypeId);
        notification.setTitle(backlogged.size() + ' new onboarding(s) waiting in the backlog');
        notification.setBody('All CSMs are at capacity. Latest: ' + backlogged[0].Name);
        notification.setTargetId(backlogged[0].Id);
        notificationsQueued++;
        try {
            notification.send(new Set<String>{ OnboardingSettings.managerGroupId });
        } catch (Exception e) {
            // A failed alert must not roll back the onboardings themselves
            System.debug(LoggingLevel.ERROR, 'Backlog notification failed: ' + e.getMessage());
        }
    }
}