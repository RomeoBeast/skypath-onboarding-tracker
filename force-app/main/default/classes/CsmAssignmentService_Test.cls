@IsTest
private class CsmAssignmentService_Test {

        @IsTest
    static void bulkCloseOf200SpreadsFairlyAndRespectsCapacity() {
        List<User> csms = TestDataFactory.createCsms(3);
        TestDataFactory.createCapacities(csms, new List<Integer>{ 30, 90, 90 });
        List<Opportunity> opportunities = TestDataFactory.createOpenOpportunities(200);

        Test.startTest();
        // One DML of 200 records, the same shape as a Data Loader batch
        TestDataFactory.closeWon(opportunities);
        Test.stopTest();

        Map<Id, Integer> activeByOwner = activeCountByOwner();
        Assert.areEqual(200, [SELECT COUNT() FROM Onboarding__c], 'Every won deal gets an onboarding');
        Assert.areEqual(30, activeByOwner.get(csms[0].Id), 'The 30-capacity CSM is filled exactly to the limit');
        Assert.areEqual(85, activeByOwner.get(csms[1].Id), 'Remaining load is split evenly');
        Assert.areEqual(85, activeByOwner.get(csms[2].Id), 'Remaining load is split evenly');
        Assert.isFalse(activeByOwner.containsKey(OnboardingSettings.backlogQueueId), 'Nothing goes to backlog while capacity remains');
    }


    @IsTest
    static void overflowGoesToBacklogAndNotifiesManagersOnce() {
        List<User> csms = TestDataFactory.createCsms(3);
        TestDataFactory.createCapacities(csms, new List<Integer>{ 20, 20, 10 });
        List<Opportunity> opportunities = TestDataFactory.createOpenOpportunities(60);

        Test.startTest();
        TestDataFactory.closeWon(opportunities);
        Test.stopTest();

        Map<Id, Integer> activeByOwner = activeCountByOwner();
        Assert.areEqual(20, activeByOwner.get(csms[0].Id));
        Assert.areEqual(20, activeByOwner.get(csms[1].Id));
        Assert.areEqual(10, activeByOwner.get(csms[2].Id));
        Assert.areEqual(10, activeByOwner.get(OnboardingSettings.backlogQueueId), 'Overflow lands in the backlog queue');
        Assert.areEqual(1, BacklogNotifier.notificationsQueued, 'Managers get one alert per batch, not one per record');
    }

    @IsTest
    static void csmWithFewestActiveOnboardingsIsChosen() {
        List<User> csms = TestDataFactory.createCsms(2);
        TestDataFactory.createCapacities(csms, new List<Integer>{ 10, 10 });
        List<Opportunity> opportunities = TestDataFactory.createOpenOpportunities(4);
        TestDataFactory.closeWon(new List<Opportunity>{ opportunities[0], opportunities[1], opportunities[2] });

        List<Onboarding__c> existing = [SELECT Id FROM Onboarding__c];
        for (Onboarding__c onboarding : existing) {
            onboarding.OwnerId = csms[0].Id;
        }
        update existing;

        Test.startTest();
        TestDataFactory.closeWon(new List<Opportunity>{ opportunities[3] });
        Test.stopTest();

        Onboarding__c newest = [SELECT OwnerId FROM Onboarding__c WHERE Opportunity__c = :opportunities[3].Id];
        Assert.areEqual(csms[1].Id, newest.OwnerId, 'The CSM with 0 active beats the CSM with 3');
    }

    @IsTest
    static void ineligibleAndInactiveCsmsAreSkipped() {
        List<User> csms = TestDataFactory.createCsms(3);
        List<CSM_Capacity__c> capacities = TestDataFactory.createCapacities(csms, new List<Integer>{ 10, 10, 10 });
        capacities[1].Is_Eligible__c = false;
        update capacities[1];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            update new User(Id = csms[2].Id, IsActive = false);
        }

        Test.startTest();
        TestDataFactory.closeWon(TestDataFactory.createOpenOpportunities(5));
        Test.stopTest();

        Assert.areEqual(5, activeCountByOwner().get(csms[0].Id), 'Only the eligible, active CSM receives work');
    }

    @IsTest
    static void reachingPostLaunchReviewFreesCapacity() {
        List<User> csms = TestDataFactory.createCsms(1);
        TestDataFactory.createCapacities(csms, new List<Integer>{ 1 });
        List<Opportunity> opportunities = TestDataFactory.createOpenOpportunities(2);
        TestDataFactory.closeWon(new List<Opportunity>{ opportunities[0] });
        Onboarding__c first = [SELECT Id FROM Onboarding__c];
        TestDataFactory.advanceTo(first.Id, OnboardingStages.POST_LAUNCH_REVIEW);

        Test.startTest();
        TestDataFactory.closeWon(new List<Opportunity>{ opportunities[1] });
        Test.stopTest();

        Onboarding__c second = [SELECT OwnerId FROM Onboarding__c WHERE Opportunity__c = :opportunities[1].Id];
        Assert.areEqual(csms[0].Id, second.OwnerId, 'A finished onboarding no longer counts toward capacity');
    }

    private static Map<Id, Integer> activeCountByOwner() {
        Map<Id, Integer> counts = new Map<Id, Integer>();
        for (AggregateResult row : [
            SELECT OwnerId ownerId, COUNT(Id) total FROM Onboarding__c WHERE Is_Active__c = TRUE GROUP BY OwnerId
        ]) {
            counts.put((Id) row.get('ownerId'), (Integer) row.get('total'));
        }
        return counts;
    }
}