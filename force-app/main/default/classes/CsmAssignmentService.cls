// Without sharing: load must be counted across every CSM's onboardings, not just the ones the running user can see
public without sharing class CsmAssignmentService {

    public static void assignOwners(List<Onboarding__c> onboardings) {
        if (onboardings.isEmpty()) {
            return;
        }
        List<CsmSlot> slots = loadSlots();
        for (Onboarding__c onboarding : onboardings) {
            CsmSlot slot = leastLoadedWithCapacity(slots);
            if (slot == null) {
                onboarding.OwnerId = OnboardingSettings.backlogQueueId;
            } else {
                onboarding.OwnerId = slot.userId;
                // Count in memory so the next record in the same batch sees the updated load
                slot.activeCount++;
            }
        }
    }

    private static List<CsmSlot> loadSlots() {
        Map<Id, CsmSlot> slotsByUserId = new Map<Id, CsmSlot>();
        // FOR UPDATE makes a second bulk job wait here instead of reading the same counts
        for (CSM_Capacity__c capacity : [
            SELECT User__c, User__r.Name, Max_Active_Onboardings__c
            FROM CSM_Capacity__c
                       WHERE Is_Eligible__c = TRUE AND User__r.IsActive = TRUE
            WITH SYSTEM_MODE
            FOR UPDATE

        ]) {
            slotsByUserId.put(
                capacity.User__c,
                new CsmSlot(capacity.User__c, capacity.User__r.Name, capacity.Max_Active_Onboardings__c.intValue())
            );
        }
        if (slotsByUserId.isEmpty()) {
            return new List<CsmSlot>();
        }

        for (AggregateResult row : [
            SELECT OwnerId ownerId, COUNT(Id) activeCount
            FROM Onboarding__c
                       WHERE Is_Active__c = TRUE AND OwnerId IN :slotsByUserId.keySet()
            WITH SYSTEM_MODE
            GROUP BY OwnerId

        ]) {
            slotsByUserId.get((Id) row.get('ownerId')).activeCount = (Integer) row.get('activeCount');
        }
        return slotsByUserId.values();
    }

    private static CsmSlot leastLoadedWithCapacity(List<CsmSlot> slots) {
        CsmSlot best;
        for (CsmSlot slot : slots) {
            if (slot.hasCapacity() && (best == null || slot.isLessLoadedThan(best))) {
                best = slot;
            }
        }
        return best;
    }

    private class CsmSlot {
        private final Id userId;
        private final String userName;
        private final Integer maxActive;
        private Integer activeCount = 0;

        private CsmSlot(Id userId, String userName, Integer maxActive) {
            this.userId = userId;
            this.userName = userName;
            this.maxActive = maxActive;
        }

        private Boolean hasCapacity() {
            return activeCount < maxActive;
        }

        // Fewest active wins; ties go to the most spare capacity, then by name, so results are repeatable
        private Boolean isLessLoadedThan(CsmSlot other) {
            if (activeCount != other.activeCount) {
                return activeCount < other.activeCount;
            }
            Integer spare = maxActive - activeCount;
            Integer otherSpare = other.maxActive - other.activeCount;
            if (spare != otherSpare) {
                return spare > otherSpare;
            }
            return userName < other.userName;
        }
    }
}