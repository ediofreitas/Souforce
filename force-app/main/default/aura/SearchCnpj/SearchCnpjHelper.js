({
    handleSearch : function(component, cnpj) {

        let actionOpp = component.get('c.getOpportunities');
        let actionAcc = component.get('c.getAccounts');
        let actionLead = component.get('c.getLeads');

        actionOpp.setParam("cnpj", cnpj);
        actionAcc.setParam("cnpj", cnpj);
        actionLead.setParam("cnpj", cnpj);

        console.log('OBA');
        
        actionOpp.setCallback(this, function(response){
            let state = response.getState();
            if(state == 'SUCCESS'){
                console.log(response.getReturnValue());
                let data = response.getReturnValue();
                component.set('v.oportunidades', data);
                component.set('v.contains', true);
            }else{
                console.error(response.getError());
            }
        });
        $A.enqueueAction(actionOpp);
        
        actionAcc.setCallback(this, function(response){
            let state = response.getState();
            if(state == 'SUCCESS'){
                let data = response.getReturnValue();
                component.set('v.contas', data);
                component.set('v.contains', true);

            }else{
                console.error(response.getError());
            }
        });
        $A.enqueueAction(actionAcc);

        actionLead.setCallback(this, function(response){
            let state = response.getState();
            if(state == 'SUCCESS'){
                let data = response.getReturnValue();
                component.set('v.leads', data);
                component.set('v.contains', true);
            }else{
                console.error(response.getError());
            }
        });
        $A.enqueueAction(actionLead);
        

       
    }
})