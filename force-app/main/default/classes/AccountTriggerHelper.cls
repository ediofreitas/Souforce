public with sharing class AccountTriggerHelper {
  

    public static void validatePhone(List<Account> triggerNew){

        for( Account acc : triggerNew){
            if(acc.Phone == null){
                acc.Phone.addError('O telefone não pode ser vazio.');
            }else if(acc.Phone.length() < 11){
                acc.Phone.addError('O telefone precisa conter 11 dígitos');
            }else{
                AccountTriggerHelper.formatPhone(acc);
            }
        }
    }

    public static void formatPhone(Account acc){

            String areaCode = acc.Phone.substring(0,2);
            String firstNumbers = acc.Phone.substring(2,7);
            String lastNumbers = acc.Phone.substring(7);

            acc.Phone = String.format('({0} {1}-{2}', new List<String>{areaCode, firstNumbers, lastNumbers});
    }
}
