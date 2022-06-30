trigger AccountTrigger on Account (before insert, after insert, before update, after update) {

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            AccountTriggerHandler.onBeforeInsert(Trigger.new);
    }
        if(Trigger.isUpdate){
            AccountTriggerHandler.onBeforeUpdate(Trigger.new);

        }

      }  
/*
    if(Trigger.isAfter){
        if(Trigger.isInsert){

        }
        if(Trigger.isUpdate){

        }
        
    }  
    */
}