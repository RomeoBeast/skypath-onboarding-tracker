// Without sharing: CSMs may not see every Account, but the name must still be built
public without sharing class OnboardingNamingService {

    private static final Integer MAX_NAME_LENGTH = 80;

    public static void applyNames(List<Onboarding__c> onboardings, Map<Id, Onboarding__c> oldMap) {
        List<Onboarding__c> toName = new List<Onboarding__c>();
        Set<Id> accountIds = new Set<Id>();
        for (Onboarding__c onboarding : onboardings) {
            Onboarding__c old = oldMap?.get(onboarding.Id);
            Boolean needsName = old == null
                || onboarding.Account__c != old.Account__c
                || onboarding.Target_Launch_Date__c != old.Target_Launch_Date__c
                || onboarding.Name != old.Name;
            if (needsName) {
                toName.add(onboarding);
                accountIds.add(onboarding.Account__c);
            }
        }
        if (toName.isEmpty()) {
            return;
        }

        Map<Id, Account> accountsById = new Map<Id, Account>([SELECT Name FROM Account WHERE Id IN :accountIds WITH SYSTEM_MODE]);
        for (Onboarding__c onboarding : toName) {
            String customer = accountsById.containsKey(onboarding.Account__c)
                ? accountsById.get(onboarding.Account__c).Name
                : 'No Account';
            String launch = onboarding.Target_Launch_Date__c == null ? 'TBD' : String.valueOf(onboarding.Target_Launch_Date__c);
            String suffix = ' - Launch ' + launch;
            onboarding.Name = customer.left(MAX_NAME_LENGTH - suffix.length()) + suffix;
        }
    }
}