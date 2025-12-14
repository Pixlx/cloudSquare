public class ApplicationDTO {
    @AuraEnabled public String companyName { get; set; }
    @AuraEnabled public String federalTaxId { get; set; }
    @AuraEnabled public Double annualRevenue { get; set; }
    @AuraEnabled public ContactDTO contact { get; set; }
    public String source { get; set; }
}
