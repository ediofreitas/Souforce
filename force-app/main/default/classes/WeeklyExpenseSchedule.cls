public with sharing class WeeklyExpenseSchedule implements Schedulable{
   
    String label;
    String category;
    Date dateTerm;
    Decimal amount;
    
    //using the constructor to receive parameters
    public WeeklyExpenseSchedule( String label, String category, Date dateTerm, Decimal amount){
        this.label = label;
        this.category = category;
        this.dateTerm = dateTerm;
        this.amount = amount;
    }

    // method that schedule the recurrent expense 7 days after the day inputed by the user 
    public void execute(SchedulableContext sc){

        Expense__c expense = new Expense__c();

        expense.Name = this.label;
        expense.Category__c = this.category;
        expense.Amount__c = this.amount;
        expense.Expense_Date__c = this.dateTerm.addDays(7);

        //changing the entrance paramater to 7 days+ so will not break after every schedule
        this.dateTerm.addDays(14);

        insert expense;
    }

}
