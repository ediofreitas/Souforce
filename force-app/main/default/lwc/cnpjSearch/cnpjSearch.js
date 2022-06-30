import { LightningElement } from 'lwc';
import getOpportunities from '@salesforce/apex/CnpjSearchController.getOpportunities';
import getLeads from '@salesforce/apex/CnpjSearchController.getLeads';
import getAccounts from '@salesforce/apex/CnpjSearchController.getAccounts';


export default class CnpjSearch extends LightningElement {

    cnpj;
    oportunidades;
    contas;
    leads;
    listContains = false;

    columnsConta = [
        { label: 'Conta', fieldName: 'Name', type: 'text' },
        { label: 'CNPJ', fieldName: 'CNPJ__c', type: 'text' },
    ];
    
    columnsOportunidade = [
        { label: 'Oportunidade', fieldName: 'Name', type: 'text' },
        { label: 'CNPJ', fieldName: 'CNPJ__c', type: 'text' },
        
    ];
    
    columnsLead = [
        { label: 'Lead', fieldName: 'Name', type: 'text' },
        { label: 'CNPJ', fieldName: 'CNPJ__c', type: 'text' },

    ];
    
    updateCnpj(event){
            this.cnpj = event.detail.value;
    }
    
    handleClick(){
        getOpportunities({cnpj : this.cnpj})
        .then(result => {
                this.oportunidades = result;
                this.listContains = true;
            
        })
        .catch(error=>{
            this.oportunidades = null;
        })
        
        getLeads({cnpj : this.cnpj})
        .then(result => {
                this.leads = result;
                this.listContains = true;

        })
        .catch(error=>{
            this.leads = null;
        })

        getAccounts({cnpj : this.cnpj})
        .then(result => {
                this.contas = result;
                this.listContains = true;
        })
        .catch(error=>{
            this.contas = null;
        })

    }
}