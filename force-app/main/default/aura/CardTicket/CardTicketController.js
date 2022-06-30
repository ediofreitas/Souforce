({
    reservaHandleClick : function(component, event, helper) {

        let vooIda = component.get('v.vooIda');
        let vooVolta = component.get('v.vooVolta');
        let compEvent = component.getEvent('ticketEventClick');
        compEvent.setParams({"IdVooIda"   : vooIda.Id,
                             "IdVooVolta" : vooVolta.Id
        });

        compEvent.fire();

    }
})
