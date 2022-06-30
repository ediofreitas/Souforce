public with sharing class CnpjSearchController {
    
    @AuraEnabled 
    public static List<Opportunity> getOpportunities(String cnpj){
       
        if(cnpj != null){
            List<Opportunity> oportunidades = [ SELECT 
                                                id, name, CNPJ__c
                                            FROM
                                                Opportunity
                                            WHERE
                                                CNPJ__c =: cnpj];
        
            return oportunidades;
        }
        
        return null;
    }

    @AuraEnabled 
    public static List<Lead> getLeads(String cnpj){
       
        if(cnpj != null){
            List<Lead> leads = [ SELECT 
                                                id, name, CNPJ__c
                                            FROM
                                                Lead
                                            WHERE
                                                CNPJ__c =: cnpj];

            return leads;
        }
        return null;
    }

    @AuraEnabled 
    public static List<Account> getAccounts(String cnpj){

        if(cnpj != null){
            List<Account> contas = [ SELECT 
                                                id, name, CNPJ__c
                                            FROM
                                                Account
                                            WHERE
                                                CNPJ__c =: cnpj];

            return contas;
        }
        return null;
    }

}