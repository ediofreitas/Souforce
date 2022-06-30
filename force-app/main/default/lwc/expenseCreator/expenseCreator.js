import { LightningElement, track } from 'lwc';
import createExpense from '@salesforce/apex/ExpenseController.createExpense';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { refreshApex } from '@salesforce/apex';



export default class ExpenseCreator extends LightningElement {

    @track isRecurrent = 'No';
    @track category = 'Housing';
    @track label;
    @track dateTerm;
    @track amount;

    //options for the recurrence picklist
    get recurrenceOptions() {
        return [
            { label: 'No', value: 'No' },
            { label: 'Weekly', value: 'Weekly' },
            { label: 'Monthly', value: 'Monthly' },
        ];
    }

    //options for the category picklist
    get categoryOptions() {
        return [
            { label: 'Housing', value: 'Housing' },
            { label: 'Transportation', value: 'Transportation' },
            { label: 'Food', value: 'Food' },
            { label: 'Medical Healthcare', value: 'Medical Healthcare' },
            { label: 'Others', value: 'Others' },
        ];
    }

    
    handleChangeRecurrence(event) {
        this.isRecurrent = event.detail.value;
    }
    
    handleChangeCategory(event) {
        this.category = event.detail.value;
    }

    handleChangeLabel(event) {
        this.label = event.detail.value;
    }
    
    handleChangeDate(event) {
        this.dateTerm = event.target.value;
    }

    handleChangeAmount(event) {
        this.amount = event.detail.value;
    }

    //callback to the backend method that create the new expense
    handleClick(){
        
        createExpense({
            label : this.label,
            category : this.category,
            dateTerm : this.dateTerm,
            amount : this.amount,
            isRecurrent : this.isRecurrent
        }).then(result =>{
            this.showToast('SUCCESS','expense inserted with success', 'success');
            //comunication between parent and child component to call the child refresh component from parent click
            this.template.querySelector('c-expense-list').refreshView();
        }).catch(error =>{
            this.showToast('ERROR','Error trying to insert the expense. ', 'error');
        })
    }

    
    //confirmation toast
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    

    
    

    
}   