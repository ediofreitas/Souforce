public with sharing class AccountTriggerHandler {
    

    public static void onBeforeInsert(List<Account> triggerNew){

        AccountTriggerHelper.validatePhone(triggerNew);
    }

    public static void onBeforeUpdate(List<Account> triggerNew){

        AccountTriggerHelper.validatePhone(triggerNew);

    }
}
