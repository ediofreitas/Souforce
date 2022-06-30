({
    loadVoos : function(component, aeroportoOrigem, aeroportoDestino, dataPartida, dataRetorno) {
        let action = component.get('c.getVoos');
        //action.setParams({aeroportoOrigem : aeroportoOrigem, aeroportoDestino : aeroportoDestino, dataPartida : dataPartida, dataRetorno : dataRetorno});
        action.setParam('aeroportoOrigem', aeroportoOrigem);
        action.setParam('aeroportoDestino', aeroportoDestino);
        action.setParam('dataPartida', dataPartida);
        action.setParam('dataRetorno', dataRetorno);

        action.setCallback(this, function(response){
            let state = response.getState();
            
            if(state == 'SUCCESS'){
                component.set('v.voos', response.getReturnValue());
            }else if(state == 'ERROR'){
                console.log(response.getError());
            }
        });

        $A.enqueueAction(action);
    }
})
