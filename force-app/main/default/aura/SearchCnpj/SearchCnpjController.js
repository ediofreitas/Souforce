({
    init : function(component, event, helper) {
        
    },

    handleClick : function(component, event, helper){
        let cnpj = component.get('v.cnpj');

        console.log(cnpj);
        helper.handleSearch(component, cnpj);

        component.set('v.columnsAcc', [
            { label: 'Conta', fieldName: 'Name', type: 'text' },
            { label: 'CNPJ', fieldName: 'CNPJ__c', type: 'text' }
        ]);

        component.set('v.columnsOpp', [
            { label: 'Oportunidade', fieldName: 'Name', type: 'text' },
            { label: 'CNPJ', fieldName: 'CNPJ__c', type: 'text' }
        ]);

        component.set('v.columnsLead', [
            { label: 'Lead', fieldName: 'Name', type: 'text' },
            { label: 'CNPJ', fieldName: 'CNPJ__c', type: 'text' }
        ]);
        
    }
})