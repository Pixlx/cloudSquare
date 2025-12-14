public with sharing class ApplicationFormController {
    
    @AuraEnabled
    public static ApplicationResult submitApplication(ApplicationDTO input){
        
            System.debug('in the application form controller ' + input);
            
            input.source = 'Community';
            return ApplicationProcessingService.processApplication(input);
            
        
    }
}