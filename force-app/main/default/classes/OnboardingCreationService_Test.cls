@IsTest
private class OnboardingCreationService_Test {

    @IsTest
    static void winningADealCreatesOneNamedOnboarding() {
        Opportunity opp = TestDataFactory.createOpenOpportunities(1)[0];

        Test.startTest();
        TestDataFactory.closeWon(new List<Opportunity>{ opp });
        Test.stopTest();

        Onboarding__c onboarding = [
            SELECT Name, Opportunity__c, Account__c, Stage__c, Target_Launch_Date__c, Kickoff_Scheduled_Reached_On__c
            FROM Onboarding__c
        ];
        Date expectedLaunch = opp.CloseDate.addDays(OnboardingSettings.launchOffsetDays);
        Assert.areEqual(opp.Id, onboarding.Opportunity__c);
        Assert.areEqual(opp.AccountId, onboarding.Account__c);
        Assert.areEqual(OnboardingStages.KICKOFF_SCHEDULED, onboarding.Stage__c);
        Assert.areEqual(expectedLaunch, onboarding.Target_Launch_Date__c);
        Assert.areEqual('Acme Rockets - Launch ' + String.valueOf(expectedLaunch), onboarding.Name);
        Assert.isNotNull(onboarding.Kickoff_Scheduled_Reached_On__c, 'Kickoff is stamped on creation');
    }

    @IsTest
    static void reopeningAndWinningAgainDoesNotCreateASecondOnboarding() {
        Opportunity opp = TestDataFactory.createOpenOpportunities(1)[0];
        TestDataFactory.closeWon(new List<Opportunity>{ opp });

        Test.startTest();
        opp.StageName = [SELECT ApiName FROM OpportunityStage WHERE IsActive = TRUE AND IsClosed = FALSE LIMIT 1].ApiName;
        update opp;
        TestDataFactory.closeWon(new List<Opportunity>{ opp });
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Onboarding__c WHERE Opportunity__c = :opp.Id]);
    }

    @IsTest
    static void openDealsDoNotGetAnOnboarding() {
        TestDataFactory.createOpenOpportunities(5);
        Assert.areEqual(0, [SELECT COUNT() FROM Onboarding__c]);
    }

    @IsTest
    static void dealWithAnOnboardingCannotBeDeleted() {
        Opportunity opp = TestDataFactory.createOpenOpportunities(1)[0];
        TestDataFactory.closeWon(new List<Opportunity>{ opp });
        try {
            delete opp;
            Assert.fail('Deleting the deal would orphan the onboarding');
        } catch (DmlException e) {
            Assert.areEqual(1, [SELECT COUNT() FROM Onboarding__c]);
        }
    }

    @IsTest
    static void changingLaunchDateRenamesTheOnboarding() {
        TestDataFactory.closeWon(TestDataFactory.createOpenOpportunities(1));
        Onboarding__c onboarding = [SELECT Id FROM Onboarding__c];
        Date newLaunch = Date.newInstance(2027, 3, 1);

        update new Onboarding__c(Id = onboarding.Id, Target_Launch_Date__c = newLaunch);

        Assert.areEqual('Acme Rockets - Launch 2027-03-01', [SELECT Name FROM Onboarding__c].Name);
    }
}