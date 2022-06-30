public with sharing class HelloWorldController {
    
    @AuraEnabled(cacheable=true)
    public static User getUserDetail(String userId){
        User user = [SELECT Id, Name FROM User WHERE Id =: userId];

        return user;
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(){
        List<Account> accountList = [SELECT Id, Name FROM Account];

        return accountList;
    }


}
