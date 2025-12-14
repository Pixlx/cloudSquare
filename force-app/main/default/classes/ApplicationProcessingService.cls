public with sharing class ApplicationProcessingService {

    public static ApplicationResult processApplication(ApplicationDTO app) {
        try {

            String taxId = app.federalTaxId;
            String companyName = app.companyName;
            Account matchedAccount = null;

            System.debug('The input: ' + app);

            if(!String.isBlank(taxId)){
                //variable binding prevents SOQL injection
                List<Account> accounts = [SELECT Id FROM Account WHERE Federal_Tax_Id__c = :taxId LIMIT 1];
                if (!accounts.isEmpty()) {
                    matchedAccount = accounts[0];
                }
            }
            else if(!String.isBlank(companyName)){
                List<Account> accounts = [SELECT Id FROM Account WHERE Name = :companyName LIMIT 1];
                if (!accounts.isEmpty()) {
                    matchedAccount = accounts[0];
                }
            }
            if(matchedAccount == null){
                Lead newLead = new Lead(
                    FirstName = app?.contact?.firstName,
                    LastName = app?.contact?.LastName,
                    Company = app?.companyName,
                    Email = app?.contact?.email,
                    Phone = app?.contact?.phone,
                    Federal_Tax_Id__c = app?.federalTaxId,
                    Application_Source__c = app?.source
                );
                //to check user permissions while creating the Lead, without this apex runs in system mode
                Database.insert(newLead,true,AccessLevel.USER_MODE);
                return new ApplicationResult(true,'Lead',newLead.Id,'Application processed successfully');
            }
            else{
                Opportunity newOpportunity = new Opportunity(
                    Name = app?.companyName + ' - New Application',
                    StageName = 'Prospecting',
                    CloseDate = System.today().addDays(30),
                    AccountId = matchedAccount.Id
                );
                Database.insert(newOpportunity,true,AccessLevel.USER_MODE);
                return new ApplicationResult(true,'Opportunity',newOpportunity.Id, 'Application processed successfully');
            }

        } catch (Exception e) {
            return new ApplicationResult(false, null, null, e.getMessage());
        }
    }
}