import { LightningElement, track, api, } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { refreshApex } from '@salesforce/apex';
//import getResolutionISGResults from '@salesforce/apex/CaseClassifcationComponentController.getResolutionISGResults';
//import getResolutionCSGResults from '@salesforce/apex/CaseClassifcationComponentController.getResolutionCSGResults';
import getClassificationData from '@salesforce/apex/CaseClassifcationComponentController.getClassificationData';
import getResolutions from '@salesforce/apex/CaseClassifcationComponentController.getResolutions';
import getCaseNumber from '@salesforce/apex/CaseClassifcationComponentController.getCaseNumber';
import deleteResolution from '@salesforce/apex/CaseClassifcationComponentController.deleteResolution';
import getUserName from '@salesforce/apex/CaseClassifcationComponentController.getUserName';
//import getAssetType from '@salesforce/apex/CaseClassifcationComponentController.getAssetType';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import CASE from '@salesforce/schema/PredictionValues__c.Case__c';
import NAME from '@salesforce/schema/PredictionValues__c.Prediction_Name__c';
import TYPERESO from '@salesforce/schema/PredictionValues__c.Resolution__c';
import CASENUMBER from '@salesforce/schema/PredictionValues__c.CaseNumber__c';
import BIZUNIT from '@salesforce/schema/PredictionValues__c.BizUnit__c';
import MANUALCC from '@salesforce/schema/PredictionValues__c.Manual_CC__c';
import LWCPREDOBJECT from '@salesforce/schema/PredictionValues__c';
import PROVIDEDBY from '@salesforce/schema/PredictionValues__c.Provided_by__c';
import TYPE from '@salesforce/schema/PredictionValues__c.Type__c';
import ACTION from '@salesforce/schema/PredictionValues__c.Action__c';
import USERID from '@salesforce/user/Id';
import ID_FIELD from '@salesforce/schema/PredictionValues__c.Id';
import DATETIME from '@salesforce/schema/PredictionValues__c.Date_Time__c';

export default class ShauryaComponent extends LightningElement {

    @track searchTerm;
    @track showValues;
    @track records;
    @track value = '';
    @track items = [];
    @api recordId;
    @api isFlow = false;
    @track valarr = [];
    @track noRecordsFlag = false;
    @track lobcode;
    @track csgAsset;
    @track isgAsset;
    @track casenum;
    @track valuesopen = false;
    @track loading = false;
    @track userName;


    connectedCallback() {
        this.getResolutionData();
        //this.getAssetType();
        this.getUserDetails();
    }

    refreshView() {
        this.items = [];
        this.loading = true;
        return refreshApex(this.getResolutionData());
    }

    get checkFlowScreen() {
        let css = '';
        if (this.isFlow === true) {
            css = 'flowcss';
        } else if (this.isFlow === false) {
            css = 'myclass';
        }
        return css;
    }

    getUserDetails() {
        getUserName({ strUserId: USERID })
            .then(result => {
                this.userName = result.Name;
            })
            .catch(error => {
                console.log('Error retreiving asset details');
            })
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    /*getAssetType() {
        getAssetType({
                recordid: this.recordId
            })
            .then(result => {
                if (result != undefined) {
                    console.log('Asset fetched successfully')
                    if (result === 'CSG') {
                        this.csgAsset = true;
                        console.log('Asset code is CSG');
                    } else if (result === 'ISG') {
                        this.isgAsset = true;
                        console.log('Asset code is ISG');
                    } else
                        console.log('Undefined LOB');


                }
            })
            .catch(error => {
                console.log('Error retreiving asset details');
            })

    }*/


    createResolution(prediction) {

        getCaseNumber({ CaseId: this.recordId })
            .then(result => {
                if (result != undefined) {
                    this.casenum = result;
                    console.log('casenum is ' + JSON.stringify(this.casenum));
                    const fields = {};
                    const dateNow = new Date();
                    fields[CASE.fieldApiName] = this.recordId;
                    fields[NAME.fieldApiName] = prediction;
                    fields[CASENUMBER.fieldApiName] = this.casenum;
                    fields[TYPERESO.fieldApiName] = true;
                    fields[MANUALCC.fieldApiName] = true;
                    fields[PROVIDEDBY.fieldApiName] = this.userName;
                    fields[TYPE.fieldApiName] = 'Resolution'
                    fields[ACTION.fieldApiName] = 'Added'
                    fields[DATETIME.fieldApiName] = dateNow.toISOString();
                    /*if (this.csgAsset === true) {
                        fields[BIZUNIT.fieldApiName] = 'CSG';
                    }
                    if (this.isgAsset === true) {
                        fields[BIZUNIT.fieldApiName] = 'ISG';
                    }*/

                    const recordInput = {
                        apiName: LWCPREDOBJECT.objectApiName,
                        fields
                    };

                    createRecord(recordInput)
                        .then(() => {
                            console.log('record created successfully');
                            let val = this.value;
                            this.valarr.push({
                                label: this.value,
                                name: this.value,
                                type: 'icon',
                                iconName: 'standard:people',
                                alternativeText: 'people'
                            });
                            this.items = [...this.valarr];
                            this.showValues = false;
                            this.searchTerm = '';

                            this.loading = false;

                        }).catch(error => {
                            console.error('Error creating record', error.body.message, 'error');
                            this.showToast('ERROR', error.body.message, 'error');
                            this.loading = false;

                        });

                }
            }).catch(error => {
                console.log('error in retreiving casenumber ' + error);
                this.showToast('ERROR', error.body.message, 'error');
                this.loading = false;

            })




    }



    getResolutionData() {
        getResolutions({
                CaseId: this.recordId
            })
            .then(result => {
                this.valarr = [];
                if (result.length > 0) {
                    if (result != undefined) {
                        for (let i = 0; i < result.length; i++) {
                            if (result[i].Manual_CC__c == true) {
                                this.valarr.push({
                                    label: result[i].Prediction_Name__c,
                                    name: result[i].Prediction_Name__c,
                                    type: 'icon',
                                    iconName: 'standard:people',
                                    alternativeText: 'people'
                                });
                            } else if (result[i].Manual_CC__c == false && result[i].Model_CC__c == false) {
                                this.valarr.push({
                                    label: result[i].Prediction_Name__c,
                                    name: result[i].Prediction_Name__c,
                                    type: 'icon',
                                    iconName: 'standard:flow',
                                    alternativeText: 'flow',
                                });
                            }

                            this.items = [...this.valarr];

                        }
                    }
                }
                this.loading = false;
            })
            .catch(error => {
                console.log('error retrieving predictions' + error);
                this.loading = false;
            })
    }



    deleteResolution(caseid, name) {
        deleteResolution({ CaseId: caseid, Name: name })
            .then(result => {
                let predid = result;
                const fields = {};
                const dateNow = new Date();
                const recordInput = { fields };
                fields[ID_FIELD.fieldApiName] = predid;
                fields[ACTION.fieldApiName] = 'Removed';
                fields[PROVIDEDBY.fieldApiName] = this.userName;
                fields[DATETIME.fieldApiName] = dateNow.toISOString();
                console.log('id recieved' + predid);
                updateRecord(recordInput)
                    .then(() => {
                        console.log('Record Deleted Succesfully');
                        //this.valarr = this.valarr.filter(item => item.name !== name);

                        for (var i = 0; i < this.valarr.length; i++) {
                            if (this.valarr[i].label === name) {
                                this.valarr.splice(i, 1);
                                break;
                            }

                        }
                        this.items = [...this.valarr];
                        this.loading = false;
                    })
                    .catch(error => {
                        console.log('Error deleting record' + this.error);
                        this.showToast('ERROR', error.body.message, 'error');
                        this.loading = false;
                    });
            })
            .catch(error => {
                console.log('Unable to fetch id ' + error);

                this.showToast('ERROR', error.body.message, 'error');
                this.loading = false;
            });
    }


    get hasItemValues() {
        if (this.items.length > 0) {
            if (this.valuesopen === false) {
                if (this.loading === false) {
                    return true;
                }
            }
            if (this.valuesopen === true) {
                return false;
            }
        } else return false;
    }

    handleItemRemove(event) {
        this.loading = true;
        const name = event.detail.item.name;
        /*this.valarr = this.valarr.filter(item => item.name !== event.detail.item.name)
        this.items = [...this.valarr];*/
        this.deleteResolution(this.recordId, name);
    }

    handlelookupselect(event) {

        this.loading = true;

        this.value = event.detail.Prediction_Name__c;
        /*let val = this.value;
        this.valarr.push({
            label: this.value,
            name: this.value
        });
        this.items = [...this.valarr];
        this.showValues = false;
        this.searchTerm = ''; */
        this.createResolution(this.value);
        this.valuesopen = false;

    }

    handleChange(event) {
        this.searchTerm = event.detail.value;
        if (this.searchTerm.length > 2) {
            this.makeServercall();
        } else {
            this.showValues = false;
            this.valuesopen = false;
        }
    }

    makeServercall() {

        let defvalue = '';
        getClassificationData({
            searchTerm: this.searchTerm,
            caseId: this.recordId,
            isResolution: true

        })           
        /*if (this.csgAsset === true) {
            getResolutionCSGResults({
                    searchTerm: this.searchTerm
                })*/
                .then(result => {
                    console.log('Result from Server' + JSON.stringify(result));

                    if (result != undefined) {
                        this.records = result;
                        this.showValues = true;
                        this.valuesopen = true;
                        this.noRecordsFlag = false;
                        if (result.length === 0) {
                            this.noRecordsFlag = true;
                        }


                    }


                })
        //}

        /*if (this.isgAsset === true) {
            getResolutionISGResults({
                    searchTerm: this.searchTerm
                })
                .then(result => {
                    console.log('Result from Server' + JSON.stringify(result));

                    if (result != undefined) {
                        this.records = result;
                        this.showValues = true;
                        this.valuesopen = true;
                        this.noRecordsFlag = false;
                        if (result.length === 0) {
                            this.noRecordsFlag = true;
                        }

                    }


                })
        }*/


    }

}