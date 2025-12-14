@IsTest
private class ApplicationProcessingServiceTest {
    
   private static final String APPLICATION_OBJECT_API_NAME = 'Application__c';

    private static final String TEST_ACCOUNT_NAME = 'Test Matching Account Corp';
    private static final String TEST_TAX_ID = '123456789';

    @TestSetup
    static void makeData() {
        Account a = new Account(
            Name = TEST_ACCOUNT_NAME,
            Federal_Tax_Id__c = TEST_TAX_ID
        );
        insert a;
    }

    @IsTest
    static void testLeadCreation_NoMatch() {

        String uniqueAccountName = 'Acme Corp';
        String uniqueTaxId = 'BG123456789';
        String appSource = 'Community';
        String FirstName = 'John';
        String LastName = 'Doe';

        ApplicationDTO testApplication = new ApplicationDTO();

        testApplication.companyName = uniqueAccountName;
        testApplication.federalTaxId = uniqueTaxId;
        testApplication.contact = new ContactDTO();
        testApplication.contact.firstName = FirstName;
        testApplication.contact.lastName = LastName;
        testApplication.contact.phone = '4425995659';
        testApplication.contact.email = 'test@test.com';

        
        Test.startTest();
        ApplicationFormController.submitApplication(testApplication);
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Opportunity], 'An Opportunity should not have been created.');

        List<Lead> createdLeads = [SELECT Company, Federal_Tax_Id__c, Application_Source__c FROM Lead WHERE Company = :uniqueAccountName];
        
        System.assertEquals(1, createdLeads.size(), 'A new Lead record should have been created.');
        System.assertEquals(uniqueTaxId, createdLeads[0].Federal_Tax_Id__c, 'Lead Tax ID should match application.');
        System.assertEquals(appSource, createdLeads[0].Application_Source__c, 'Lead Source should match application.');

    }
    
    @IsTest
    static void testOpportunityCreation_TaxIdMatch() {
          
        ApplicationDTO testApplication = new ApplicationDTO();
        testApplication.companyName = 'New App for Existing Account';
        testApplication.federalTaxId = TEST_TAX_ID;
        
        Test.startTest();
        ApplicationProcessingService.processApplication(testApplication);
        Test.stopTest();

        Account matchingAccount = [SELECT Id FROM Account WHERE Federal_Tax_Id__c = :TEST_TAX_ID LIMIT 1];

        List<Opportunity> createdOpportunities = [SELECT AccountId, Name FROM Opportunity WHERE AccountId = :matchingAccount.Id];

        System.assertEquals(1, createdOpportunities.size(), 'A new Opportunity record should have been created.');
        System.assertEquals(matchingAccount.Id, createdOpportunities[0].AccountId, 'Opportunity should be linked to the matched Account.');
    }

    @IsTest
    static void testOpportunityCreation_NameMatch() {
        
        String externalAppId = 'APP-OPP-NAME-003';

        ApplicationDTO testApplication = new ApplicationDTO();
        testApplication.companyName = TEST_ACCOUNT_NAME;
        testApplication.federalTaxId = null;
        
        Test.startTest();
        ApplicationProcessingService.processApplication(testApplication);
        Test.stopTest();


        Account matchingAccount = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
        
        System.assertEquals(1, [SELECT count() FROM Account], 'No new Account should have been created.');

        List<Opportunity> createdOpportunities = [SELECT AccountId, Name FROM Opportunity WHERE AccountId = :matchingAccount.Id];

        System.assertEquals(1, createdOpportunities.size(), 'A new Opportunity record should have been created.');
        System.assertEquals(matchingAccount.Id, createdOpportunities[0].AccountId, 'Opportunity should be linked to the matched Account.');

    }

    @IsTest
    static void testWebService_Class(){

        //create the test JSON
        ApplicationDTO testApplication = new ApplicationDTO();

        testApplication.companyName = 'Acme Corp';
        testApplication.federalTaxId = 'BG123456789';
        testApplication.contact = new ContactDTO();
        testApplication.contact.firstName = 'John';
        testApplication.contact.lastName = 'Doe';
        testApplication.contact.phone = '4425995659';
        testApplication.contact.email = 'test@test.com';

        String body = JSON.serialize(testApplication);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestUri = '/services/apexrest/external/applications/'; 
        req.httpMethod = 'POST';
        // Set the request body
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ApplicationWebhook.handlePost();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Expected 200 OK for success');
        
        // Check the response body
        String responseBody = res.responseBody.toString();
        ApplicationResult result = (ApplicationResult)JSON.deserialize(responseBody, ApplicationResult.class);
        
        System.assert(result.success, 'Success');
    }

    @IsTest
    static void exceptionHandling(){
        String uniqueAccountName = 'Acme Corp';
        String uniqueTaxId = 'BG123456789';
        String appSource = 'Community';

        ApplicationDTO testApplication = new ApplicationDTO();

        testApplication.companyName = uniqueAccountName;
        testApplication.federalTaxId = uniqueTaxId;

        
        Test.startTest();
        ApplicationResult result = ApplicationFormController.submitApplication(testApplication);
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Opportunity], 'An Opportunity should not have been created.');

        List<Lead> createdLeads = [SELECT Company, Federal_Tax_Id__c, Application_Source__c FROM Lead WHERE Company = :uniqueAccountName];
        
        System.assertEquals(0, createdLeads.size(), 'A new Lead record should have been created.');
        System.assertEquals(result.success, false, 'Result should be false');
    }
}
