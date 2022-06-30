import { LightningElement, track, api } from 'lwc';
import getExpenses from '@salesforce/apex/ExpenseController.getExpenses';
import { refreshApex } from '@salesforce/apex';

export default class ExpenseList extends LightningElement {

    @track expenses;
    @track listContains = false;

    //columns displayed in the datatable
    @track columns = [
        { label: 'Label', fieldName: 'Name', type: 'text' },
        { label: 'Category', fieldName: 'Category__c', type: 'text' },
        { label: 'Date', fieldName: 'Expense_Date__c', type: 'date' },
        { label: 'Amount', fieldName: 'Amount__c', type: 'currency' },
        { label: 'Weekly Total Amount', fieldName: 'Weekly_Total_Amount__c', type: 'currency' },
        { label: 'Monthly Total Amount', fieldName: 'Monthly_Total_Amount__c', type: 'currency' }
    ];

    connectedCallback(){
        this.getExpenses();
    }

    //method called from the parent component to refresh the list with the new inserted values
    @api
    refreshView(){
        this.getExpenses();
    }

    //callback matheod to show the expenses
    getExpenses(){
        getExpenses()
        .then(result =>{
            this.expenses = result;
            this.listContains = true;
            
        }).catch(err =>{
            console.log('Error getting expenses: Check your data and try again.' + err);
        })

    }


}