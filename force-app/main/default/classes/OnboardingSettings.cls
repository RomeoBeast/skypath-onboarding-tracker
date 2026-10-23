// Resolves configuration by developer name so no record IDs are hardcoded
public without sharing class OnboardingSettings {

    public class OnboardingConfigException extends Exception {}

    private static Onboarding_Setting__mdt config {
        get {
            if (config == null) {
                config = Onboarding_Setting__mdt.getInstance('Default');
                if (config == null) {
                    throw new OnboardingConfigException('Onboarding Setting "Default" record is missing.');
                }
            }
            return config;
        }
        set;
    }

    public static Integer launchOffsetDays {
        get { return config.Launch_Offset_Days__c.intValue(); }
    }

    public static Id backlogQueueId {
        get {
            if (backlogQueueId == null) {
                backlogQueueId = requireId(
                    [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :config.Backlog_Queue_Developer_Name__c LIMIT 1],
                    'Backlog queue'
                );
            }
            return backlogQueueId;
        }
        private set;
    }

    public static Id managerGroupId {
        get {
            if (managerGroupId == null) {
                managerGroupId = requireId(
                    [SELECT Id FROM Group WHERE Type = 'Regular' AND DeveloperName = :config.Manager_Group_Developer_Name__c LIMIT 1],
                    'CS manager group'
                );
            }
            return managerGroupId;
        }
        private set;
    }

    public static Id notificationTypeId {
        get {
            if (notificationTypeId == null) {
                notificationTypeId = requireId(
                    [SELECT Id FROM CustomNotificationType WHERE DeveloperName = :config.Notification_Type_Developer_Name__c LIMIT 1],
                    'Backlog notification type'
                );
            }
            return notificationTypeId;
        }
        private set;
    }

    // Falls back to the org default so a fresh org without the holiday calendar still works
    public static Id businessHoursId {
        get {
            if (businessHoursId == null) {
                List<BusinessHours> named = [
                    SELECT Id FROM BusinessHours WHERE Name = :config.Business_Hours_Name__c AND IsActive = TRUE LIMIT 1
                ];
                businessHoursId = named.isEmpty()
                    ? [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1].Id
                    : named[0].Id;
            }
            return businessHoursId;
        }
        private set;
    }

    private static Id requireId(List<SObject> rows, String description) {
        if (rows.isEmpty()) {
            throw new OnboardingConfigException(description + ' not found. Check the Onboarding Setting "Default" record.');
        }
        return rows[0].Id;
    }
}