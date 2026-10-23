@IsTest
public class TestDataFactory {

    public static List<User> createCsms(Integer count) {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User' LIMIT 1].Id;
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Onboarding_CSM' LIMIT 1].Id;
        String uniqueSuffix = String.valueOf(System.currentTimeMillis());

        List<User> csms = new List<User>();
        for (Integer i = 0; i < count; i++) {
            csms.add(new User(
                FirstName = 'Test',
                LastName = 'CSM ' + i,
                Alias = 'tcsm' + i,
                Email = 'csm' + i + '@skypath.test',
                Username = 'csm' + i + '.' + uniqueSuffix + '@skypath.test',
                ProfileId = profileId,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            ));
        }
        // Setup records in their own runAs block to avoid mixed DML with business records
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert csms;
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (User csm : csms) {
                assignments.add(new PermissionSetAssignment(AssigneeId = csm.Id, PermissionSetId = permissionSetId));
            }
            insert assignments;
        }
        return csms;
    }

    public static List<CSM_Capacity__c> createCapacities(List<User> csms, List<Integer> maxActive) {
        List<CSM_Capacity__c> capacities = new List<CSM_Capacity__c>();
        for (Integer i = 0; i < csms.size(); i++) {
            capacities.add(new CSM_Capacity__c(
                User__c = csms[i].Id,
                Max_Active_Onboardings__c = maxActive[i],
                Is_Eligible__c = true
            ));
        }
        insert capacities;
        return capacities;
    }

    public static List<Opportunity> createOpenOpportunities(Integer count) {
        Account customer = new Account(Name = 'Acme Rockets');
        insert customer;
        String openStage = [SELECT ApiName FROM OpportunityStage WHERE IsActive = TRUE AND IsClosed = FALSE ORDER BY SortOrder LIMIT 1].ApiName;

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            opportunities.add(new Opportunity(
                Name = 'Test Deal ' + i,
                AccountId = customer.Id,
                StageName = openStage,
                CloseDate = Date.today()
            ));
        }
        insert opportunities;
        return opportunities;
    }

    public static void closeWon(List<Opportunity> opportunities) {
        String wonStage = [SELECT ApiName FROM OpportunityStage WHERE IsActive = TRUE AND IsWon = TRUE LIMIT 1].ApiName;
        for (Opportunity opp : opportunities) {
            opp.StageName = wonStage;
        }
        update opportunities;
    }

    public static void advanceTo(Id onboardingId, String targetStage) {
        Integer targetIndex = OnboardingStages.ORDERED.indexOf(targetStage);
        for (Integer i = 1; i <= targetIndex; i++) {
            update new Onboarding__c(
                Id = onboardingId,
                Stage__c = OnboardingStages.ORDERED[i],
                Gathering_Info_Notes__c = 'Requirements captured',
                Implementation_Notes__c = 'Configuration complete'
            );
        }
    }
}