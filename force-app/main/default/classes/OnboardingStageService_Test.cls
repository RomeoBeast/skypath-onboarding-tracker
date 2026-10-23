@IsTest
private class OnboardingStageService_Test {

    @TestSetup
    static void setup() {
        TestDataFactory.closeWon(TestDataFactory.createOpenOpportunities(1));
    }

    private static Onboarding__c onboarding() {
        return [
            SELECT Id, Stage__c, QA_Rework_Count__c, Implementation_Reached_On__c, QA_Review_Reached_On__c
            FROM Onboarding__c LIMIT 1
        ];
    }

    @IsTest
    static void cannotSkipAStage() {
        try {
            update new Onboarding__c(Id = onboarding().Id, Stage__c = OnboardingStages.IMPLEMENTATION);
            Assert.fail('Skipping Gathering Info should be blocked');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('one stage at a time'), e.getMessage());
        }
    }

    @IsTest
    static void cannotLeaveGatheringInfoWithoutNotes() {
        Id onboardingId = onboarding().Id;
        update new Onboarding__c(Id = onboardingId, Stage__c = OnboardingStages.GATHERING_INFO);
        try {
            update new Onboarding__c(Id = onboardingId, Stage__c = OnboardingStages.IMPLEMENTATION);
            Assert.fail('Notes are required to leave Gathering Info');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('Gathering Info Notes'), e.getMessage());
        }
    }

    @IsTest
    static void cannotLeaveImplementationWithoutNotes() {
        Id onboardingId = onboarding().Id;
        update new Onboarding__c(Id = onboardingId, Stage__c = OnboardingStages.GATHERING_INFO, Gathering_Info_Notes__c = 'Captured');
        update new Onboarding__c(Id = onboardingId, Stage__c = OnboardingStages.IMPLEMENTATION);
        try {
            update new Onboarding__c(Id = onboardingId, Stage__c = OnboardingStages.QA_REVIEW);
            Assert.fail('Notes are required to leave Implementation');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('Implementation Notes'), e.getMessage());
        }
    }

    @IsTest
    static void qaCanSendWorkBackWithoutChangingFirstReachedDates() {
        Id onboardingId = onboarding().Id;
        Datetime firstPass = Datetime.newInstance(2026, 1, 5, 9, 0, 0);
        OnboardingStageService.clockOverride = firstPass;
        TestDataFactory.advanceTo(onboardingId, OnboardingStages.QA_REVIEW);

        // QA fails two weeks later and the work goes back
        OnboardingStageService.clockOverride = Datetime.newInstance(2026, 1, 20, 9, 0, 0);
        update new Onboarding__c(Id = onboardingId, Stage__c = OnboardingStages.IMPLEMENTATION);
        update new Onboarding__c(Id = onboardingId, Stage__c = OnboardingStages.QA_REVIEW);

        Onboarding__c result = onboarding();
        Assert.areEqual(firstPass, result.Implementation_Reached_On__c, 'First reached Implementation is unchanged');
        Assert.areEqual(firstPass, result.QA_Review_Reached_On__c, 'First reached QA is unchanged');
        Assert.areEqual(1, result.QA_Rework_Count__c, 'The QA failure is counted');
    }

    @IsTest
    static void cannotJumpBackFurtherThanImplementation() {
        Id onboardingId = onboarding().Id;
        TestDataFactory.advanceTo(onboardingId, OnboardingStages.QA_REVIEW);
        try {
            update new Onboarding__c(Id = onboardingId, Stage__c = OnboardingStages.GATHERING_INFO);
            Assert.fail('Only QA to Implementation is allowed backwards');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('one stage at a time'), e.getMessage());
        }
    }

    @IsTest
    static void stageDatesCannotBeEdited() {
        try {
            update new Onboarding__c(Id = onboarding().Id, Kickoff_Scheduled_Reached_On__c = Datetime.now().addDays(-30));
            Assert.fail('Recorded stage dates are locked');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('cannot be changed'), e.getMessage());
        }
    }
}