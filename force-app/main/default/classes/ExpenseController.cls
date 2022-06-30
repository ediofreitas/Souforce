public with sharing class ExpenseController {
    
    // Method called to insert the expense and call the schedule when needed
    @AuraEnabled
    public static void createExpense(String label, String category, Date dateTerm, Decimal amount, String isRecurrent){
        System.debug(label + category + dateTerm + amount + isRecurrent);
        
        Expense__c expense = new Expense__c();
        expense.Name = label;
        expense.Category__c = category;
        expense.Amount__c = amount;
        expense.Expense_Date__c = dateTerm;

        // If the expense is recurrent im creating a schedule to repeat the insertion of the expense, 7 days after the dateTerm if weekly or in the next 30 days if monthly. The schedule date is every friday for weekly recurrences and every 15th day of the month for monthly recurrences as requested in the description of the task.
        if(isRecurrent == 'Weekly'){
            System.schedule('Weekly expense ' + label, '0 0 0 ? * 6', new WeeklyExpenseSchedule(label, category, dateTerm, amount));
            expense.Weekly_expense__c = true;
        }else if(isRecurrent == 'Monthly'){
            System.schedule('Monthly expense ' + label, '0 0 0 15 * ?', new MonthlyExpenseSchedule(label, category, dateTerm, amount));
            expense.Monthly_expense__c = true;
        }
        
        insert expense;
    }

    // Method called to retrieve all the expenses in the database
    @AuraEnabled //(cacheable=true) --- obs: removed the cacheable true because this is the only way to refresh the table after insert a new value
    public static List<Expense__c> getExpenses(){
        List<Expense__c> expensesList = [SELECT Id, Name, Category__c, Amount__c, Expense_Date__c, Weekly_Total_Amount__c, Monthly_Total_Amount__c FROM Expense__c];

        return expensesList;
    }

    // ----------------- IMPORTANT---------------------
    //not using try/catches here because i already have them in each method on the LWC
}
