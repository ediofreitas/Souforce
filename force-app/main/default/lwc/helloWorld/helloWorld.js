import { LightningElement, api, wire, track } from 'lwc';
import USER_ID  from '@salesforce/user/Id';
import Data from '@salesforce/schema/QuoteTemplateRichTextData.Data';
import getUserDetail from '@salesforce/apex/HelloWorldController.getUserDetail'
import getAccounts from '@salesforce/apex/HelloWorldController.getAccounts'
import ACCOUNT from '@salesforce/schema/Account'
import ACCOUNT_NAME from '@salesforce/schema/Account.Name'
import { getObjectInfo } from 'lightning/uiObjectInfoApi';


const columns = [
    { label: 'Account Id', fieldName: 'Id' },
    { label: 'Account Name', fieldName: 'Name'}
];

export default class HelloWorld extends LightningElement {

    @api userId = USER_ID; 
    @api recordId;
    @track finalName;
    @track name;
    @track accountName;

    @track isCheck;
    @track accountList;
    
    
    data = [];
    columns = columns;

    @wire (getUserDetail,{userId: '$userId'})
    record;

    @wire (getObjectInfo, {objectApiName: ACCOUNT})
        getObjectInfo({error, data}){
            if(error){
                console.log(error);
            }else if(data){
                console.log(data.fields[ACCOUNT.fieldApiName]);
                this.accountName = data.fields[ACCOUNT.fieldApiName].label
            }

        }
/*
    @wire(getAccounts)
    accountList;
    */
    
    connectedCallback(){
        this.getAccounts();
    }

    getAccounts(){
        getAccounts()
        .then(result =>{
            this.accountList = result;
        })
        .catch(error => {
            console.log(error);
        })
    }

    handleChange(event){
        this.name = event.target.value;
    }

    handleClick(){
        this.finalName = this.name;
    }

    handleCheck(event){
        this.isCheck = event.target.checked;
    }


    /*connectedCallback(){
        this.getUserDetails();
    }
    
    /*getUserDetails(){
        getUserDetail({userId : this.userId})
        .then( result => {
            console.log(result);
            this.name = result.Name;
        })
        .catch(error=> {
            console.log('Error:' + error)
        })
    }*/

}