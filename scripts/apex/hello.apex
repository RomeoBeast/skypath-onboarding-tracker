Integer dealCount = 215;
List<Account> accounts = new List<Account>();
for (Integer i = 1; i <= dealCount; i++) {
    accounts.add(new Account(Name = 'Demo Customer ' + String.valueOf(i).leftPad(3, '0')));
}
insert accounts;
List<Opportunity> opportunities = new List<Opportunity>();
for (Integer i = 1; i <= dealCount; i++) {
    opportunities.add(new Opportunity(
        Name = 'Demo Deal ' + String.valueOf(i).leftPad(3, '0'),
        AccountId = accounts[i - 1].Id,
        StageName = 'Negotiation/Review',
        CloseDate = Date.today(),
        Amount = 25000
    ));
}
insert opportunities;