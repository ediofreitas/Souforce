@isTest
public with sharing class CnpjSearchControllerTest {
    
    @TestSetup
    static void makeData(){
        Opportunity opp = new Opportunity();
            opp.Name = 'Opp Teste';
            opp.CNPJ__c = '11111111111111';
			opp.StageName = 'Qualification';
        	opp.CloseDate = System.today();
        
            insert opp;

        Account acc = new Account();
            acc.Name = 'Acc Teste';
            acc.CNPJ__c = '11111111111111';

            insert acc;

        Lead lead = new Lead();
            lead.LastName = 'Lead Teste';
            lead.CNPJ__c = '11111111111111';
			lead.Company = 'Teste';
            insert lead;
    }

    @isTest
    static void unitTest(){
        Test.startTest();
            CnpjSearchController.getOpportunities('11111111111111');
            CnpjSearchController.getLeads('11111111111111');
            CnpjSearchController.getAccounts('11111111111111');
        Test.stopTest();
    }
}