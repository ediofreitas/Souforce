({
    init : function(component, event, helper) {
        let aeroportoOrigem = 'a025e000008MO9WAAW';
        let aeroportoDestino = 'a025e000008MO9YAAW';
        let dataPartida = '2022-01-10'
        let dataRetorno = '2022-01-15'

        helper.loadVoos(component, aeroportoOrigem, aeroportoDestino, dataPartida, dataRetorno);
    },

    handlerEventClick : function(component, event, helper){
        const idVooIda = event.getParam("IdVooIda");
        const idVooVolta = event.getParam("IdVooVolta");

        console.log('idVooIda: ' + idVooIda);
        console.log('idVooVolta: ' + idVooVolta);
    }
})
