/* ---------------------------------------------------------------------------------------------------------------------------
* Name:       CaseClassifcationComponentController
* Description:  Contains different methods to be used by the symptom and resolution classification Components
* ---------------------------------------------------------------------------------------------------------------------------
* Date                 Author             Summary of Changes 
* -----------  ------------------------  ---------------------------------------------------------------------------
* 05/15/2020   Shaurya Bajaj             Initial Release
* 22/02/2021   Shaurya Bajaj			 Story 10150255
* 05/25/2021   Shaurya Bajaj             Story 10255797
* 07/21/2021   Omkar Kadam               Checkmarx Fixes
* 08/10/2021   Omkar / Shuchismita       Leverage WO Product Classification Custom Metadata
* 09/29/2021   Omkar Kadam               Added getClassificationData for search based on LOB/Product Family
* --------------------------------------------------------------------------------------------------------------------------- */

public with sharing class CaseClassifcationComponentController {
    
    /* -----------------------------------------------------------------------------------------------------------------------
Method Name:  getClassificationData
Description:  Fetches Prediction Data based on LOB or Product Family
----------------------------------------------------------------------------------------------------------------------------
Date         Version          Author             Summary of Changes 
-----------  -------  ------------------------  ------------------------------------------------------------------------------
09/29/2021     1.0         Omkar Kadam               Initial Release
10/13/2021     1.2         Omkar Kadam               Checkmarx Fixes
10/21/2021	   1.3		   Omkar Kadam				 Defect 11460609 Fix
-------------------------------------------------------------------------------------------------------------------------- */
    @AuraEnabled
    public static List<Prediction__c> getClassificationData(String searchTerm, String caseId, Boolean isResolution){
        String searchValue= String.escapeSingleQuotes(searchTerm);
        String queryProduct = String.escapeSingleQuotes('SELECT Product_Family__c,Product.LOB_Code__c FROM Case WHERE Id = :caseId');
        
        Case caseDetails = Database.query(queryProduct);
        
        
        // get case related Product's lob/family
        String lobCode = caseDetails.Product.LOB_Code__c;
        String productFamily = caseDetails.Product_Family__c;
        
        // Checks first if LOB present if not then checks if Product Family is present or not
        
        List<Prediction__c> predictionValues = new List<Prediction__c>();
        
        if(String.isNotEmpty(lobCode)){
            List<Prediction__c> lstLOBPredictions = [SELECT Prediction_Name__c 
                                                     FROM Prediction__c 
                                                     WHERE Resolution_Flag__c =:isResolution AND (LOB_Code__c = :lobCode OR LOB_Code__c LIKE:lobCode+';%' OR LOB_Code__c LIKE:'%; '+lobCode OR LOB_Code__c LIKE:'%; '+lobCode+';%')
                                                     ORDER BY Prediction_Name__c];
            
            if(lstLOBPredictions.size() > 0){
                for(Prediction__c label : lstLOBPredictions){
                    if((label.Prediction_Name__c).containsIgnoreCase(searchValue)){
                        predictionValues.add(label);
                    }
                }
                return predictionValues;
            }
        }
        
        if(String.isNotEmpty(productFamily)){
            List<Prediction__c> lstFamilyPredictions = [SELECT Prediction_Name__c 
                                                        FROM Prediction__c 
                                                        WHERE Resolution_Flag__c =:isResolution AND (Product_Family__c = :productFamily OR Product_Family__c LIKE:productFamily+';%' OR Product_Family__c LIKE:'%; '+productFamily OR Product_Family__c LIKE:'%; '+productFamily+';%') 
                                                        ORDER BY Prediction_Name__c];
            
            
            if(lstFamilyPredictions.size() > 0){
                for(Prediction__c label : lstFamilyPredictions){
                    if((label.Prediction_Name__c).containsIgnoreCase(searchValue)){
                        predictionValues.add(label);
                    }
                }
                return predictionValues;
            }
        }
        
        // Get generic list if there's no lob / family on product or lob/family do not match with any prediction label
        
        String defaultValue = '%'+searchTerm+'%';
        List<Prediction__c> lstGenericPredictions = [SELECT Prediction_Name__c 
                                                     FROM Prediction__c 
                                                     WHERE Prediction_Name__c LIKE:defaultValue AND Product_Family__c = '' AND LOB_Code__c = '' AND Resolution_Flag__c =:isResolution 
                                                     ORDER BY Prediction_Name__c];
        
        return lstGenericPredictions;
        
    }
    
    /* -----------------------------------------------------------------------------------------------------------------------
Method Name:  getUserName
Description:  Fetches user name from user Id.
----------------------------------------------------------------------------------------------------------------------------
Date         Version          Author             Summary of Changes 
-----------  -------  ------------------------  ------------------------------------------------------------------------------
06/17/2021     1.0         Sai Kumar               Initial Release
07/27/2021     1.2         Omkar Kadam             Checkmarx Fixes
-------------------------------------------------------------------------------------------------------------------------- */
    
    @AuraEnabled
    public static User getUserName(Id strUserId){
        return [SELECT Name FROM User WHERE Id =:strUserId];
    }
    
    
    
    /* -----------------------------------------------------------------------------------------------------------------------
Method Name:  getPredictions
Description:  Fetches selected classification values associated with the case/
----------------------------------------------------------------------------------------------------------------------------
Date         Version          Author             Summary of Changes 
-----------  -------  ------------------------  ------------------------------------------------------------------------------
05/15/2020     1.0         Shaurya Bajaj               Initial Release
-------------------------------------------------------------------------------------------------------------------------- */
    
    
    
    @AuraEnabled
    public static List<PredictionValues__c> getPredictions(String CaseId){
        List<PredictionValues__c> pred = [select id,Prediction_Name__c,Manual_CC__c,Model_CC__c from PredictionValues__c where Case__c = :CaseId and Classification__c = true AND Action__c ='Added'];
        return pred;
    }
    
    /* -----------------------------------------------------------------------------------------------------------------------
Method Name:  getResolutions
Description:  Fetches selected resolution values associated with the case.
----------------------------------------------------------------------------------------------------------------------------
Date         Version          Author             Summary of Changes 
-----------  -------  ------------------------  ------------------------------------------------------------------------------
05/15/2020     1.0         Shaurya Bajaj               Initial Release
-------------------------------------------------------------------------------------------------------------------------- */
    
    @AuraEnabled
    public static List<PredictionValues__c> getResolutions(String CaseId){
        List<PredictionValues__c> pred = [select id,Prediction_Name__c,Manual_CC__c,Model_CC__c from PredictionValues__c where Case__c = :CaseId AND Resolution__c = true AND Action__c ='Added'];
        return pred;
    }
    
    /* -----------------------------------------------------------------------------------------------------------------------
Method Name:  deletePred
Description:  Deletes the selected predictions values by the agent.
----------------------------------------------------------------------------------------------------------------------------
Date         Version          Author             Summary of Changes 
-----------  -------  ------------------------  ------------------------------------------------------------------------------
05/15/2020     1.0         Shaurya Bajaj               Initial Release
-------------------------------------------------------------------------------------------------------------------------- */
    
    @AuraEnabled
    public static Id  deletePred(String CaseId ,String Name){
        System.debug(CaseId+' '+Name);
        PredictionValues__c pred = [select id from PredictionValues__c where Case__c = :CaseId and Prediction_Name__c = :Name and Classification__c = true AND Action__c ='Added' LIMIT 1];
        System.debug(pred);
        return pred.id;
    }
    
    /* -----------------------------------------------------------------------------------------------------------------------
Method Name:  deleteResolution
Description:  Deletes the selected resolution values by the agent.
----------------------------------------------------------------------------------------------------------------------------
Date         Version          Author             Summary of Changes 
-----------  -------  ------------------------  ------------------------------------------------------------------------------
05/15/2020     1.0         Shaurya Bajaj               Initial Release
-------------------------------------------------------------------------------------------------------------------------- */
    
    @AuraEnabled
    public static id  deleteResolution(String CaseId ,String Name){
        System.debug(CaseId+' '+Name);
        PredictionValues__c pred = [Select Id FROM PredictionValues__c WHERE Case__c = :CaseId AND Prediction_Name__c = :Name AND Resolution__c = true AND Action__c ='Added' LIMIT 1];
        System.debug(pred);
        return pred.Id;
        
        
    }
    
    /* -----------------------------------------------------------------------------------------------------------------------
Method Name:  getCaseNumber
Description:  Fetches case number of the seleted case
----------------------------------------------------------------------------------------------------------------------------
Date         Version          Author             Summary of Changes 
-----------  -------  ------------------------  ------------------------------------------------------------------------------
05/15/2020     1.0         Shaurya Bajaj               Initial Release
-------------------------------------------------------------------------------------------------------------------------- */
    
    @AuraEnabled
    public static String getCaseNumber(String CaseId){
        String casequery  =String.escapesinglequotes('select CaseNumber from Case where id = :CaseId LIMIT 1');
        
        Case rec = Database.query(casequery);        
        System.debug(rec.CaseNumber);
        return rec.CaseNumber;
        
    }
    
    
  
}