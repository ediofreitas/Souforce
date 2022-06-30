/**************************************************************************************************************
* @company:             Globant Brasil
* @author:              Adriano Fernandes href=<adriano.fernandes@globant.com>
* @project:             CASC SA - Origination Grain - 360° - Cargill
* @name:                AVX_AddressBookIntegration_wbs
* @description:         Class for AddressBook integration.
* @dependencies     
*
* @changes (Version)
* --------   ---   ----------   ------------------------------------   ------------------------------------------------
*            No.   Date         Author                                 Description
* --------   ---   ----------   ------------------------------------   ------------------------------------------------
* @version   1.0   2020-07-20   Adriano Fernandes                      Initial version.
* @version   2.0   2020-09-10   Andrés Ballesteros                     Adjustment for Boomi/CDP JSON Structure.
* @version   2.1   2020-09-28   Jesús Rosales                          Adjustment sor saving logs on error.
* @version   2.2   2020-10-05   Andrés Ballesteros                     Add Domestic Market Logic.
**************************************************************************************************************

**/
@RestResource(urlMapping = '/AddressBook/*')
global  without sharing class AVX_AddressBookIntegration_wbs {

    @HttpPut
    global static void AddressBookUpsert(){
        /* Map<String,IntegrationResponseWrapper> mapIntegrationResponseWrapper = new Map<String,IntegrationResponseWrapper>(); 
        List<IntegrationLogs__c> lstIntegrationLogs = new List<IntegrationLogs__c>(); */

        try{
            RestRequest objRESTRequest      = RestContext.request; 
            String resquestBody             =  objRESTRequest.requestBody.toString();

            IntegrationRequest objIntegrationRequest = (IntegrationRequest) JSON.deserialize(resquestBody, IntegrationRequest.class);
            System.debug('test4: ' + objIntegrationRequest);
            List<AddressBookWrapper> lstAddressBookWrapper = new List<AddressBookWrapper>();
            if(objIntegrationRequest.accountData != null && !objIntegrationRequest.accountData.isEmpty()){
                lstAddressBookWrapper                   = objIntegrationRequest.accountData;
                objIntegrationRequest.Account           = objIntegrationRequest.accountData;
            }else if (objIntegrationRequest.Account != null && !objIntegrationRequest.Account.isEmpty()){
                lstAddressBookWrapper                   = objIntegrationRequest.Account;
                objIntegrationRequest.accountData       = objIntegrationRequest.Account;
            }
                

            system.debug('AddressBookUpsert || Integration Request >> ' + JSON.serializePretty(lstAddressBookWrapper));

            if(lstAddressBookWrapper == null || lstAddressBookWrapper.isEmpty()){
                throw new AddressBookException('List Cannot be Null.');
            }

           

            List<IntegrationResponseWrapper> lstIntegrationResponseWrapper = upsertAccountAndBusinessDetail(objIntegrationRequest);
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(lstIntegrationResponseWrapper));
            
        }catch(Exception ex){
            //mapIntegrationResponseWrapper = new Map<String,IntegrationResponseWrapper>(); 
            Map<String,IntegrationResponseWrapper> mapIntegrationResponseWrapper = new Map<String,IntegrationResponseWrapper>();
            List<IntegrationLogs__c> lstIntegrationLogs = new List<IntegrationLogs__c>();
            mapIntegrationResponseWrapper.put(null,new IntegrationResponseWrapper(null,'ERROR','APEX_ERROR',ex.getMessage()));

            
            IntegrationLogs__c iLog = new IntegrationLogs__c();
            iLog.Source__c = 'A004119';
            iLog.Status__c = 'Error';
            iLog.Response__c = ex.getMessage();
            lstIntegrationLogs.add(iLog);

            insert(lstIntegrationLogs);
            
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(mapIntegrationResponseWrapper.values()));
            return;
        }
    }

    public static List<IntegrationResponseWrapper> upsertAccountAndBusinessDetail(IntegrationRequest objIntegrationRequest){
        Map<String,IntegrationResponseWrapper> mapIntegrationResponseWrapper = new Map<String,IntegrationResponseWrapper>(); 
        List<IntegrationLogs__c> lstIntegrationLogs = new List<IntegrationLogs__c>();
        
        Map<String, AddressBookWrapper> mapAddressBookWrapperByERPNumber = new Map<String, AddressBookWrapper>();
        Map<String, List<AddressBookWrapper>> mapAddressBookWrapperByParentERPNumber = new Map<String, List<AddressBookWrapper>>();
        Set<String> setBusinessId = new Set<String>();
        Set<String> setBusinessDivision = new Set<String>();

        for(AddressBookWrapper objAddressBookWrapper : objIntegrationRequest.Account){
            if(String.isBlank(objAddressBookWrapper.address_child)){
                throw new AddressBookException('Please check the request again. One or More items does not have Identifier and the list cannot be processed.'); 
            }else{
                mapAddressBookWrapperByERPNumber.put(objAddressBookWrapper.address_child, objAddressBookWrapper);
                mapIntegrationResponseWrapper.put(objAddressBookWrapper.address_child,new IntegrationResponseWrapper(objAddressBookWrapper.address_child,'ERROR','DEFAULT_ERROR','Something went Wrong.'));
                if(objAddressBookWrapper.address_parent_child != null){
                    if(!mapAddressBookWrapperByParentERPNumber.containsKey(objAddressBookWrapper.address_parent_child))
                        mapAddressBookWrapperByParentERPNumber.put(objAddressBookWrapper.address_parent_child, new List<AddressBookWrapper>());

                    mapAddressBookWrapperByParentERPNumber.get(objAddressBookWrapper.address_parent_child).add(objAddressBookWrapper);
                }

                setBusinessId.add(objAddressBookWrapper.company_cd);
                setBusinessDivision.add(objAddressBookWrapper.Business_Division);
            }  
        }
        
        List<User> integrationUser = [SELECT id FROM user WHERE username LIKE 'integrationsfdc@cargill.com%'];
        Map<String, Business__c> mapBusinessByKey = new Map<String, Business__c>();
        for(Business__c objBusiness : [SELECT Id, Name, BusinessAlias__c, BusinessID__c, CargillEnterprise__c, CargillGroup__c, 
                                        BusinessDivision__c, ExternalKey__C 
                                        FROM Business__c 
                                        WHERE BusinessID__c =: setBusinessId]){
            mapBusinessByKey.put(objBusiness.ExternalKey__C, objBusiness);
        }

        List<Account> lstAccount = [SELECT id,name,Active__c,BillingState,BillingCity,BillingCountryCode,BillingStreet,	
                                    CASC_Address_Customer__c 
                                    FROM Account 
                                    WHERE CASC_Address_Customer__c =: mapAddressBookWrapperByERPNumber.keySet()
                                    OR CASC_Address_Customer__c =: mapAddressBookWrapperByParentERPNumber.keySet()];
    
        Map<String, Account> mapAccountByERPInfo = new Map<String, Account>();
        for(Account objAccount : lstAccount){
            mapAccountByERPInfo.put(objAccount.CASC_Address_Customer__c, objAccount);
        }

        List<BusinessDetail__c> lstBusinessDetail = [SELECT Id, CASC_Address_Customer__c, BusinessUnit__r.BusinessDivision__c,
                                                    BusinessUnit__r.BusinessID__c, ExternalId__c
                                                    FROM  BusinessDetail__c 
                                                    WHERE (CASC_Address_Customer__c =: mapAddressBookWrapperByERPNumber.keySet() 
                                                    OR CASC_Address_Customer__c =: mapAddressBookWrapperByParentERPNumber.keySet())
                                                    AND BusinessUnit__r.BusinessDivision__c =: setBusinessDivision
                                                    AND BusinessUnit__r.BusinessID__c =: setBusinessId];

        Map<String, BusinessDetail__c> mapBusinessDetailByKey = new Map<String, BusinessDetail__c>();
        for(BusinessDetail__c objBusinessDetail : lstBusinessDetail){
            mapBusinessDetailByKey.put(objBusinessDetail.ExternalId__c, objBusinessDetail);
        }

        List<Account> lstGrandParentAccount_Upsert = new List<Account>();
        List<Account> lstParentAccount_Upsert = new List<Account>();
        List<Account> lstAccount_Upsert = new List<Account>();
        Account objAccount;

        List<BusinessDetail__c> lstGrandParentBusinessDetail_Upsert = new List<BusinessDetail__c>();
        List<BusinessDetail__c> lstParentBusinessDetail_Upsert = new List<BusinessDetail__c>();
        List<BusinessDetail__c> lstBusinessDetail_Upsert = new List<BusinessDetail__c>();
        BusinessDetail__c objBusinessDetail;

        List<ERPInformation__c> lstERPInformation_Upsert = new List<ERPInformation__c>();
		ERPInformation__c objERPInformation;

        for(AddressBookWrapper objAddressBookWrapper : objIntegrationRequest.Account){
            //////////////// VALIDATIONS //////////////////////
            if(!mapBusinessByKey.containsKey(objAddressBookWrapper.company_cd + '-' + objAddressBookWrapper.Business_Division)){
                mapIntegrationResponseWrapper.put(objAddressBookWrapper.address_child,new IntegrationResponseWrapper(objAddressBookWrapper.address_child,'ERROR','APEX_ERROR','Was Not Possible to relate the ' + objAddressBookWrapper.company_cd + '-' + objAddressBookWrapper.Business_Division + ' Business.' ));
                continue;
            }

            //////////////// FIELD FILLING //////////////////////
            if(mapAccountByERPInfo.containsKey(objAddressBookWrapper.address_child)){
                objAccount = mapAccountByERPInfo.get(objAddressBookWrapper.address_child);
            }else{
                objAccount = new Account();
            }

            objAccount.CASC_Address_Customer__c         = objAddressBookWrapper.address_child;
            if(String.isNotBlank(objAddressBookWrapper.address_parent_child)){
                objAccount.Parent = new Account (CASC_Address_Customer__c = objAddressBookWrapper.address_parent_child);
            }
            objAccount.Name                             = objAddressBookWrapper.customer_name;
            objAccount.LegalName__c                     = objAddressBookWrapper.customer_name;
            objAccount.Active__c                        = objAddressBookWrapper.status_address == 'TRUE'; 
            objAccount.ERPName__c                       = objAddressBookWrapper.ERP_Origin;
            objAccount.BillingStreet                    = objAddressBookWrapper.billing_street;
            objAccount.BillingCity                      = objAddressBookWrapper.billing_city;
            objAccount.BillingStateCode                 = objAddressBookWrapper.billing_state;
            objAccount.BillingCountryCode               = objAddressBookWrapper.billing_country_cd;
            objAccount.BillingPostalCode                = objAddressBookWrapper.billing_postal_cd;
            objAccount.CurrencyIsoCode                  = objAddressBookWrapper.currency_iso_cd;
            objAccount.Geolocation__latitude__s         = objAddressBookWrapper.Latitude;
            objAccount.Geolocation__longitude__s        = objAddressBookWrapper.Longitude;
            if(!integrationUser.IsEmpty())
                objAccount.OwnerId 						= integrationUser[0].Id;

            if(String.isBlank(objAddressBookWrapper.address_parent_child)){
                lstGrandParentAccount_Upsert.add(objAccount);
            }else{
                if(mapAddressBookWrapperByParentERPNumber.containsKey(objAddressBookWrapper.address_child)){
                    lstParentAccount_Upsert.add(objAccount);
                }else{
                    lstAccount_Upsert.add(objAccount);
                }
            }

            objAddressBookWrapper.BusinessDetailKey         = objAddressBookWrapper.address_child + '//' + objAddressBookWrapper.company_cd + '-' + objAddressBookWrapper.Business_Division;
            objAddressBookWrapper.ParentBusinessDetailKey   = objAddressBookWrapper.address_parent_child + '//' + objAddressBookWrapper.company_cd + '-' + objAddressBookWrapper.Business_Division;

            if(mapBusinessDetailByKey.containsKey(objAddressBookWrapper.BusinessDetailKey)){
                objBusinessDetail = mapBusinessDetailByKey.get(objAddressBookWrapper.BusinessDetailKey);
            }else{
                objBusinessDetail = new BusinessDetail__c();
            }
            objBusinessDetail.ExternalID__c                             = objAddressBookWrapper.address_child + '//' + objAddressBookWrapper.company_cd + '-' + objAddressBookWrapper.Business_Division;

            objBusinessDetail.Account__r = new Account (CASC_Address_Customer__c = objAddressBookWrapper.address_child);
            if(String.isNotBlank(objAddressBookWrapper.address_parent_child)){
                objBusinessDetail.ParentAccount__r = new Account (CASC_Address_Customer__c = objAddressBookWrapper.address_parent_child);
                objBusinessDetail.ParentBusinessDetail__r = new BusinessDetail__c (ExternalId__c = objAddressBookWrapper.ParentBusinessDetailKey);
            }
            
            objBusinessDetail.Name                                      = mapBusinessByKey.get(objAddressBookWrapper.company_cd + '-' + objAddressBookWrapper.Business_Division).BusinessAlias__c + ' | ' + objAddressBookWrapper.customer_name;
            objBusinessDetail.BusinessUnit__c                           = mapBusinessByKey.get(objAddressBookWrapper.company_cd + '-' + objAddressBookWrapper.Business_Division).Id;

            objBusinessDetail.IdentificationDocument__c                 = objAddressBookWrapper.identication_document;
            objBusinessDetail.StateRegistration__c                      = objAddressBookWrapper.state_registration;
            objBusinessDetail.InternalStatus__c                         = objAddressBookWrapper.internal_status;

            objBusinessDetail.CreditLimit__c                            = objAddressBookWrapper.credit_limit;
            objBusinessDetail.CreditLastCheck__c                        = objAddressBookWrapper.credit_last_check;
            objBusinessDetail.CreditDueDate__c                          = objAddressBookWrapper.credit_due_date;
            objBusinessDetail.CurrencyIsoCode                  			= Label.AVX_StdCurrencyOnBusinessDetail_NT == '-'? objAddressBookWrapper.currency_iso_cd : 'USD';

            objBusinessDetail.AccountRepresentant__c                    = objAddressBookWrapper.account_representant;
            objBusinessDetail.AccountRepresentantDescription__c         = objAddressBookWrapper.account_representant_desc;
            objBusinessDetail.BranchCode__c                             = objAddressBookWrapper.branch_cd;
            objBusinessDetail.BranchCodeDescription__c                  = objAddressBookWrapper.branch_cd_desc;
            objBusinessDetail.BranchOfActivity__c                       = objAddressBookWrapper.branch_of_activity;
            objBusinessDetail.ActivityBranch__c                         = objAddressBookWrapper.branch_of_activity;
            objBusinessDetail.ActivityBranchDescription__c              = objAddressBookWrapper.activity_branch_desc;
            objBusinessDetail.Classification__c                         = objAddressBookWrapper.classification;
            objBusinessDetail.ClassificationDescription__c              = objAddressBookWrapper.classification_desc;
            objBusinessDetail.FiscalLocation__c                         = objAddressBookWrapper.fiscal_location;
            objBusinessDetail.IndustrialClassification__c               = objAddressBookWrapper.industrial_classification;
            objBusinessDetail.IndustrialClassificationDescription__c    = objAddressBookWrapper.industrial_classification_desc;
            objBusinessDetail.SalesTerritory__c                         = objAddressBookWrapper.sales_territory;
            objBusinessDetail.SalesTerritoryDescription__c              = objAddressBookWrapper.sales_territory_desc;
            objBusinessDetail.SearchType__c                             = objAddressBookWrapper.search_type;
            objBusinessDetail.SelectionCode__c                          = objAddressBookWrapper.selection_cd;
            objBusinessDetail.SelectionCodeDescription__c               = objAddressBookWrapper.selection_cd_desc;
            objBusinessDetail.TaxType__c                                = objAddressBookWrapper.tax_id;

            objBusinessDetail.Segmentation__c                           = objAddressBookWrapper.segmentation;
            objBusinessDetail.SegmentationDescription__c                = objAddressBookWrapper.segmentation_desc;
            objBusinessDetail.MacroSegmentation__c                      = objAddressBookWrapper.macro_segmentation;
            objBusinessDetail.MacroSegmentationDescription__c           = objAddressBookWrapper.macro_segmentation_desc;
            objBusinessDetail.AllowedtoChangeInterests__c               = objAddressBookWrapper.confirming_customer == 'TRUE'; // UNCOMMENT WHEN DOMESTIC MARKET MERGE.

            if(String.isBlank(objAddressBookWrapper.address_parent_child)){
                lstGrandParentBusinessDetail_Upsert.add(objBusinessDetail);
            }else{
                if(mapAddressBookWrapperByParentERPNumber.containsKey(objAddressBookWrapper.address_child)){
                    lstParentBusinessDetail_Upsert.add(objBusinessDetail);
                }else{
                    lstBusinessDetail_Upsert.add(objBusinessDetail);
                }
            }

            objERPInformation = new ERPInformation__c();
			objERPInformation.ExternalId__c                             = objAddressBookWrapper.address_child + '//' + objAddressBookWrapper.ERP_Origin + '-' + objAddressBookWrapper.company_cd + '-' + objAddressBookWrapper.Business_Division;
			objERPInformation.Account__r = new Account (CASC_Address_Customer__c = objAddressBookWrapper.address_child);
			objERPInformation.BusinessDetail__r = new BusinessDetail__c (ExternalID__c = objAddressBookWrapper.address_child + '//' + objAddressBookWrapper.company_cd + '-' + objAddressBookWrapper.Business_Division);
			objERPInformation.Business__c = mapBusinessByKey.get(objAddressBookWrapper.company_cd + '-' + objAddressBookWrapper.Business_Division).Id;
			objERPInformation.ERPID__c = objAddressBookWrapper.address_child;
			objERPInformation.ERPName__c = objAddressBookWrapper.ERP_Origin;

			lstERPInformation_Upsert.add(objERPInformation);

            /* // NOT IN WS
            public String IDType; // BUSINESS DETAIL: IDType__c

            // PENDING
            Public String MacroSegmentation; // BUSINESS DETAIL: MacroSegmentation__c
            Public String segmentationDescription; // BUSINESS DETAIL: MacroSegmentationDescription__c */
            
        }
        
        ////////////////////////// ACCOUNT UPSERT ////////////////////////////////////        
        Database.UpsertResult[] lstGrandParentAccount_Upserted = Database.upsert(lstGrandParentAccount_Upsert,Account.Fields.CASC_Address_Customer__c,false);
        for(Integer index = 0, size = lstGrandParentAccount_Upserted.size(); index < size; index++) 
        {
            mapIntegrationResponseWrapper.put(
                lstGrandParentAccount_Upsert[index].CASC_Address_Customer__c,
                new IntegrationResponseWrapper(
                    lstGrandParentAccount_Upsert[index].CASC_Address_Customer__c,
                    lstGrandParentAccount_Upserted[index].isSuccess()? 'SUCCESS':'ERROR',
                    lstGrandParentAccount_Upserted[index].isSuccess()? null:'APEX_ERROR',
                    lstGrandParentAccount_Upserted[index].isSuccess()? String.valueOf(lstGrandParentAccount_Upserted[index].getId()):String.valueOf(lstGrandParentAccount_Upserted[index].getErrors()[0].getMessage()))
            );
        }

        Database.UpsertResult[] lstParentAccount_Upserted = Database.upsert(lstParentAccount_Upsert,Account.Fields.CASC_Address_Customer__c,false);
        for(Integer index = 0, size = lstParentAccount_Upserted.size(); index < size; index++) 
        {
            mapIntegrationResponseWrapper.put(
                lstParentAccount_Upsert[index].CASC_Address_Customer__c,
                new IntegrationResponseWrapper(
                    lstParentAccount_Upsert[index].CASC_Address_Customer__c,
                    lstParentAccount_Upserted[index].isSuccess()? 'SUCCESS':'ERROR',
                    lstParentAccount_Upserted[index].isSuccess()? null:'APEX_ERROR',
                    lstParentAccount_Upserted[index].isSuccess()? String.valueOf(lstParentAccount_Upserted[index].getId()):String.valueOf(lstParentAccount_Upserted[index].getErrors()[0].getMessage()))
            );
        }

        Database.UpsertResult[] lstAccount_Upserted = Database.upsert(lstAccount_Upsert,Account.Fields.CASC_Address_Customer__c,false);
        for(Integer index = 0, size = lstAccount_Upserted.size(); index < size; index++) 
        {
            mapIntegrationResponseWrapper.put(
                lstAccount_Upsert[index].CASC_Address_Customer__c,
                new IntegrationResponseWrapper(
                    lstAccount_Upsert[index].CASC_Address_Customer__c,
                    lstAccount_Upserted[index].isSuccess()? 'SUCCESS':'ERROR',
                    lstAccount_Upserted[index].isSuccess()? null:'APEX_ERROR',
                    lstAccount_Upserted[index].isSuccess()? String.valueOf(lstAccount_Upserted[index].getId()):String.valueOf(lstAccount_Upserted[index].getErrors()[0].getMessage()))
            );
        }

        ////////////////////////// BUSINESS DETAIL UPSERT ////////////////////////////////////

        Map<String, Boolean> mapBusinessId_Upserted = new Map<String, Boolean>();
        Database.UpsertResult[] lstGrandParentBusinessDetail_Upserted = Database.upsert(lstGrandParentBusinessDetail_Upsert,BusinessDetail__c.Fields.ExternalId__c,false);
        for(Integer index = 0, size = lstGrandParentBusinessDetail_Upserted.size(); index < size; index++) 
        {
            if(mapIntegrationResponseWrapper.get(lstGrandParentBusinessDetail_Upsert[index].ExternalId__c.split('//')[0]).errorCode != 'APEX_ERROR'){
                mapIntegrationResponseWrapper.put(
                    lstGrandParentBusinessDetail_Upsert[index].ExternalId__c.split('//')[0],
                    new IntegrationResponseWrapper(
                        lstGrandParentBusinessDetail_Upsert[index].ExternalId__c.split('//')[0],
                        lstGrandParentBusinessDetail_Upserted[index].isSuccess()? 'SUCCESS':'ERROR',
                        lstGrandParentBusinessDetail_Upserted[index].isSuccess()? null:'APEX_ERROR',
                        lstGrandParentBusinessDetail_Upserted[index].isSuccess()? String.valueOf(lstGrandParentBusinessDetail_Upserted[index].getId()):String.valueOf(lstGrandParentBusinessDetail_Upserted[index].getErrors()[0].getMessage()))
                );
            } 
        }

        Database.UpsertResult[] lstParentBusinessDetail_Upserted = Database.upsert(lstParentBusinessDetail_Upsert,BusinessDetail__c.Fields.ExternalId__c,false);
        for(Integer index = 0, size = lstParentBusinessDetail_Upserted.size(); index < size; index++) 
        {
            if(mapIntegrationResponseWrapper.get(lstParentBusinessDetail_Upsert[index].ExternalId__c.split('//')[0]).errorCode != 'APEX_ERROR'){
                mapIntegrationResponseWrapper.put(
                    lstParentBusinessDetail_Upsert[index].ExternalId__c.split('//')[0],
                    new IntegrationResponseWrapper(
                        lstParentBusinessDetail_Upsert[index].ExternalId__c.split('//')[0],
                        lstParentBusinessDetail_Upserted[index].isSuccess()? 'SUCCESS':'ERROR',
                        lstParentBusinessDetail_Upserted[index].isSuccess()? null:'APEX_ERROR',
                        lstParentBusinessDetail_Upserted[index].isSuccess()? String.valueOf(lstParentBusinessDetail_Upserted[index].getId()):String.valueOf(lstParentBusinessDetail_Upserted[index].getErrors()[0].getMessage()))
                );
            }
        }

        Database.UpsertResult[] lstBusinessDetail_Upserted = Database.upsert(lstBusinessDetail_Upsert,BusinessDetail__c.Fields.ExternalId__c,false);
        for(Integer index = 0, size = lstBusinessDetail_Upserted.size(); index < size; index++) 
        {
            if(mapIntegrationResponseWrapper.get(lstBusinessDetail_Upsert[index].ExternalId__c.split('//')[0]).errorCode != 'APEX_ERROR'){
                mapIntegrationResponseWrapper.put(
                    lstBusinessDetail_Upsert[index].ExternalId__c.split('//')[0],
                    new IntegrationResponseWrapper(
                        lstBusinessDetail_Upsert[index].ExternalId__c.split('//')[0],
                        lstBusinessDetail_Upserted[index].isSuccess()? 'SUCCESS':'ERROR',
                        lstBusinessDetail_Upserted[index].isSuccess()? null:'APEX_ERROR',
                        lstBusinessDetail_Upserted[index].isSuccess()? String.valueOf(lstBusinessDetail_Upserted[index].getId()):String.valueOf(lstBusinessDetail_Upserted[index].getErrors()[0].getMessage()))
                );
            }
        }

        ////////////////////////// ERP UPSERT ////////////////////////////////////
        Database.UpsertResult[] lstERPInformation_Upserted = Database.upsert(lstERPInformation_Upsert,ERPInformation__c.Fields.ExternalId__c,false);
        
        IntegrationLogs__c objIntegrationLog;
        for(String strKey : mapIntegrationResponseWrapper.keySet()){
            if(mapIntegrationResponseWrapper.get(strKey).Status == 'ERROR'){
                objIntegrationLog = new IntegrationLogs__c();
                objIntegrationLog.Source__c = mapAddressBookWrapperByERPNumber.get(strKey).Business_Division == 'Domestic Market'? 'A004163' : 'A004119';
                objIntegrationLog.Status__c = 'Error';
                objIntegrationLog.Request__c = JSON.serialize(mapAddressBookWrapperByERPNumber.get(strKey));
                objIntegrationLog.Response__c = mapIntegrationResponseWrapper.get(strKey).message;
                objIntegrationLog.DocumentNumber__c = strKey;
                lstIntegrationLogs.add(objIntegrationLog);
            }
        }

        if(lstIntegrationLogs != null && !lstIntegrationLogs.isEmpty()){
            Database.insert(lstIntegrationLogs, false);
        }
        
        system.debug('mapIntegrationResponseWrapper.values(): ' + mapIntegrationResponseWrapper.values());
        return mapIntegrationResponseWrapper.values();
    }

    public class AddressBookException extends Exception{}

    public Class IntegrationRequest{
        public List<AddressBookWrapper> accountData;
        public List<AddressBookWrapper> Account;
        
        public IntegrationRequest(){
            accountData = new List<AddressBookWrapper>();
            Account = new List<AddressBookWrapper>();
        } 
    }
    
    public Class AddressBookWrapper {
        public String address_child; // ACCOUNT: CASC_Address_Customer__c // BUSINESS DETAIL: Account__c
        Public String address_parent_child; // ACCOUNT: ParentId // BUSINESS DETAIL: ParentAccount__c
        public String customer_name; // ACCOUNT: Name, LegalName__c // BUSINESS DETAIL: Name
        public String status_address; // ACCOUNT: Active__c
        public String ERP_Origin; // ACCOUNT: ERPName__c
        public String billing_street; // ACCOUNT: BillingAddress
        public String billing_city; // ACCOUNT: BillingAddress
        public String billing_state; // ACCOUNT: BillingAddress
        public String billing_country_cd; // ACCOUNT: BillingAddress
        public String billing_postal_cd; // ACCOUNT: BillingAddress
        public String currency_iso_cd; // ACCOUNT: CurrencyIsoCode // BUSINESS DETAIL: CurrencyIsoCode

        public String company_cd; // BUSINESS DETAIL: BusinessUnit__c
        public String Business_Division; // BUSINESS DETAIL: BusinessUnit__c
        public String BusinessDetailKey; // BUSINESS DETAIL: ExternalId__c
        public String ParentBusinessDetailKey; // BUSINESS DETAIL: ParentBusinessDetail__c

        public String identication_document; // BUSINESS DETAIL: IdentificationDocument__c
        Public String state_registration; // BUSINESS DETAIL: StateRegistration__c
        public String internal_status; // BUSINESS DETAIL: InternalStatus__c
        Public decimal credit_limit; // BUSINESS DETAIL: CreditLimit__c
        Public Date credit_last_check; // BUSINESS DETAIL: CreditLastCheck__c
        Public Date credit_due_date; // BUSINESS DETAIL: CreditDueDate__c

        public String account_representant; // BUSINESS DETAIL: AccountRepresentant__c
        public String account_representant_desc; // BUSINESS DETAIL: AccountRepresentantDescription__c
        public String branch_cd; // BUSINESS DETAIL: BranchCode__c
        public String branch_cd_desc; // BUSINESS DETAIL: BranchCodeDescription__c
        public String branch_of_activity; // BUSINESS DETAIL: BranchOfActivity__c, ActivityBranch__c
        public String activity_branch_desc; // BUSINESS DETAIL: ActivityBranchDescription__c
        Public String classification; // BUSINESS DETAIL: Classification__c
        Public String classification_desc; // BUSINESS DETAIL: ClassificationDescription__c
        Public String fiscal_location; // BUSINESS DETAIL: FiscalLocation__c
        Public String industrial_classification; // BUSINESS DETAIL: IndustrialClassification__c
        public String industrial_classification_desc; // BUSINESS DETAIL: IndustrialClassificationDescription__c
        Public String sales_territory; // BUSINESS DETAIL: SalesTerritory__c
        public String sales_territory_desc; // BUSINESS DETAIL: SalesTerritoryDescription__c
        Public String search_type; // BUSINESS DETAIL: SearchType__c
        Public String selection_cd; // BUSINESS DETAIL: SelectionCode__c
        Public String selection_cd_desc; // BUSINESS DETAIL: SelectionCodeDescription__c
        Public String tax_id; // BUSINESS DETAIL: TaxType__c
        
        Public String segmentation; // BUSINESS DETAIL: Segmentation__c
        Public String segmentation_desc; // BUSINESS DETAIL: SegmentationDescription__c
        Public String macro_segmentation; // BUSINESS DETAIL: MacroSegmentation__c
        Public String macro_segmentation_desc; // BUSINESS DETAIL: MacroSegmentationDescription__c
        Public String confirming_customer; // BUSINESS DETAIL: AllowedtoChangeInterests__c

        // NOT IN WS
        public String IDType; // BUSINESS DETAIL: IDType__c
        public portfolioWrapper portfolio; // USED IN AURA COMPONENT: AVX_AddressBookSearch
        public String AccountPreferenceRecordTypeId; // USED IN AURA COMPONENT: AVX_AddressBookSearch

        // PENDING
       
        public Decimal Latitude; // ACCOUNT: Geolocation__c
        public Decimal Longitude; // ACCOUNT: Geolocation__c
        
        public AddressBookWrapper() {
        } 
             
        public AddressBookWrapper parse(String json) {
            return (AddressBookWrapper) System.JSON.deserialize(json, AddressBookWrapper.class);
        }  
        
    }
    
    public Class IntegrationResponseWrapper{
        public String address_child; // Address Number.
        public String Status; //'SUCCESS':'ERROR'
        public String errorCode; // 
        public String message; // IF ERROR ( Error Message ) IF SUCCESS ( Business Detail Id )
        
        
        public IntegrationResponseWrapper(){
            this.address_child = '';
            this.Status = '';
            this.errorCode = '';
            this.message = '';
        } 

        public IntegrationResponseWrapper(String strAddress, String strStatus, String strErrorCode, String strMessage){
            this.address_child = strAddress;
            this.Status = strStatus;
            this.errorCode = strErrorCode;
            this.message = strMessage;
        }
    }
    
    public Class portfolioWrapper{
        public String Id; 
        public Boolean Owned;
        public String Name;
        public String Description;
        public String Subregion;
        public String OwnerName;
        
        public portfolioWrapper(){
            this.owned = false;
        } 
    }
    
    
}