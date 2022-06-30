public with sharing class TicketsController {

    @AuraEnabled(cacheable=true)
    public static List<Aeroporto__c> getAeroportos(String search){

        search += '%';
        List<Aeroporto__c> aeroportos = [SELECT Id, Name, Estado__r.Name, Sigla__c FROM Aeroporto__c WHERE Name LIKE :search OR Estado__r.Name LIKE :search OR Sigla__c LIKE :search];
        return aeroportos;
    }

    public static Date dateParse(String dateString){
        List<String> dt = dateString.split('-');
        Date dateResult = Date.newInstance(Integer.valueof(dt[0]), Integer.valueof(dt[1]), Integer.valueof(dt[2]));

        return dateResult;
    }

    @AuraEnabled(cacheable=true)
    public static List<RetornoVooTO> getVoos(String aeroportoOrigem, String aeroportoDestino, String dataPartida, String dataRetorno){

        Date dtPartida = dateParse(dataPartida);
        Date dtRetorno = dateParse(dataRetorno);
        
        List <Voo__c> voosOrigem = [SELECT Id, Name, Aeroporto_Chegada__r.Sigla__c, Aeroporto_Partida__r.Sigla__c, Assento__c, Companhia__c, Data_Chegada__c, Data_Partida__c, Hora_de_Chegada__c, Hora_de_Partida__c, Valor__c FROM Voo__c WHERE Aeroporto_Chegada__c =: aeroportoDestino AND Aeroporto_Partida__c =: aeroportoOrigem AND Data_Partida__c =: dtPartida ];

        List <Voo__c> voosDestino = [SELECT Id, Name, Aeroporto_Chegada__r.Sigla__c, Aeroporto_Partida__r.Sigla__c, Assento__c, Companhia__c, Data_Chegada__c, Data_Partida__c, Hora_de_Chegada__c, Hora_de_Partida__c, Valor__c FROM Voo__c WHERE Aeroporto_Chegada__c =: aeroportoOrigem AND Aeroporto_Partida__c =: aeroportoDestino AND Data_Partida__c =: dtRetorno];

        List <RetornoVooTO> results = new List<RetornoVooTO>();

        for(Voo__c vooOrigem : voosOrigem){
            for(Voo__c vooDestino : voosDestino){
                results.add(new RetornoVooTO(vooOrigem, vooDestino));
            }
        }
        System.debug('results '+ results);
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static Ticket__c createTicket(String accountId, String vooIdaId, String vooVoltaId){
        Ticket__c ticket = new Ticket__c();
            ticket.Account__c = accountId;
            ticket.Voo_Ida__c = vooIdaId;
            ticket.Voo_Volta__c = vooVoltaId;
        
        insert ticket;

        return ticket;

    }

    public class RetornoVooTO{
        @AuraEnabled
        public Voo__c vooIda;
        @AuraEnabled
        public Voo__c vooVolta;

        public RetornoVooTO(Voo__c vooIda, Voo__c vooVolta){
            this.vooIda = vooIda;
            this.vooVolta = vooVolta;
        }
    }

}
