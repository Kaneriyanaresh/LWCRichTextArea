/*******************************************************************************************************
Name : CATPricePageController
Description : This class will create Product2, PricebookEntry, SBQQ__ProductOption__c, SBQQ__Quote__c,
               SBQQ__QuoteLine__c records that is entered from the Opportunity Page's Case Price button
               Layout.
CreatedDate : 15th July 2022
---------------------------------------------------------------------------------------------
Version  Intial Draft     LastModify By  Modification Description
1.0      Naresh Kaneriya                   
*********************************************************************************************************/
public class CATPricePageController { 
    
    
    @AuraEnabled // This Method will create Product2, PricebookEntry, SBQQ__ProductOption__c, SBQQ__Quote__c records
    public static String saveController(String oppRecordId, string wrapperProducts, String priceModel){
        try {
            
            System.debug('oppRecordId   '+oppRecordId); 
            System.debug('wrapperProducts  '+wrapperProducts);
            System.debug('priceModel  '+priceModel);
            
            List<ProductWrapper> ProductWrapperList   =  new List<ProductWrapper>();
            List<Object> deserializewrapperList = new List<Object>();
            
            // Prodcut2 Related Varibale
            List<ProductWrapper> zeroIndexProductsList = new List<ProductWrapper>();
            List<ProductWrapper> nonZeroIndexProductsList = new List<ProductWrapper>();
            List<Product2> insertProducts = new List<Product2>();
            Map<String, String> productIdMap = new Map<String, String>();
            Product2 zeroIndexProducts = new Product2();            
            
            // PricebookEntry Related Varibale
            List<PricebookEntry> insertPricebookEntry = new List<PricebookEntry>();
            Map<String, Decimal> productPriceMap = new Map<String, Decimal>();
            
            // Product Option Related Varibale
            List<SBQQ__ProductOption__c> insertProductOption = new List<SBQQ__ProductOption__c>();
            Integer ProductOptionNumberCount = 10;
            Integer OptionCount = 10;
            Map<String,String> productOptionMap = new Map<String,String>(); 
            
            // Quote Related Varibale
            SBQQ__Quote__c InsertQuote = new SBQQ__Quote__c();
            
            // Quote Line Related Varibale
            SBQQ__QuoteLine__c zeroIndexQuoteLine = new SBQQ__QuoteLine__c();
            List<SBQQ__QuoteLine__c> insertQuoteLine = new List<SBQQ__QuoteLine__c>();
            
            if(String.isNotBlank(wrapperProducts)){
                deserializewrapperList = (List<Object>)JSON.deserializeUntyped(wrapperProducts);
            }           
            
            System.debug('deserializewrapperList ==>  '+deserializewrapperList);
            
            if(deserializewrapperList.size() > 0 ){

                for(Object deserialize: deserializewrapperList) {
                    Map<String, Object> productData = (Map<String, Object>)deserialize; 
                    ProductWrapper objWrapper = new ProductWrapper();
                    objWrapper.productCode = (string)productData.get('productCode');
                    objWrapper.productName = (string)productData.get('productName');
                    objWrapper.productPrice = (Decimal)productData.get('price'); 
                    ProductWrapperList.add(objWrapper);
                } 
                
                System.debug('ProductWrapperList ==>   '+ProductWrapperList);
                
                // To Separate Index Zero, remaining Index from ProductWrapperList List 
                for(Integer i = 0; i < ProductWrapperList.size(); i++) {
                    if (i == 0) 
                        zeroIndexProductsList.add(ProductWrapperList[0]);
                    else 
                        nonZeroIndexProductsList.add(ProductWrapperList[i]);
                }
                
                System.debug('zeroIndexProductsList ==>   '+zeroIndexProductsList);
                System.debug('nonZeroIndexProductsList ==>   '+nonZeroIndexProductsList);

                // Start of Product2 Insert Logic

                // To Create First entry of product from the List
                if(zeroIndexProductsList.size() > 0) {
                    for(ProductWrapper products : zeroIndexProductsList) {
                        zeroIndexProducts = new Product2(IsActive = true,
                                                         Name = products.productName, 
                                                         ProductCode = products.productCode,
                                                         SBQQ__Component__c = false,
                                                         Price_Model__c = priceModel);
                        
                    }
                } 
                
                System.debug('zeroIndexProducts ==>   '+zeroIndexProducts);
                if(zeroIndexProducts != null){
                    insert zeroIndexProducts;
                }  
                
                // To Create other entry of product (Except 1st Entry) from the List
                if (nonZeroIndexProductsList.size() > 0) {
                    for(ProductWrapper products : nonZeroIndexProductsList) {
                        insertProducts.add(new Product2(IsActive = true,
                                                        Name = products.productName, 
                                                        ProductCode = products.productCode,
                                                        SBQQ__Component__c = true)
                                          );
                    }
                }
                
                System.debug('insertProducts ==>   '+insertProducts);
                if (insertProducts.size() > 0 ) {
                    insert insertProducts;
                }
                
                // Add all inserted Products to insertProducts List
                insertProducts.add(zeroIndexProducts);
                
                if (insertProducts.size() > 0 ) {
                    for (Product2 prod : insertProducts) {
                        productIdMap.put(prod.ProductCode+''+prod.Name, prod.Id);
                    }
                }
                
                //End of Product2 Insert Logic


                // Start of PricebookEntry Insert Logic

                Id StandardPriceBookId = [select id, name from Pricebook2 where isStandard = true limit 1].Id;

                for (ProductWrapper prodPrice : ProductWrapperList) {
                    String UniqueProducts = prodPrice.productCode+''+prodPrice.productName+''+prodPrice.productPrice; 
                    productPriceMap.put(UniqueProducts,prodPrice.productPrice);
                }
                                
                System.debug('StandardPriceBookId  '+StandardPriceBookId);
                System.debug('productIdMap  '+productIdMap.size());
                System.debug('productPriceMap  '+productPriceMap.size());
                System.debug('ProductWrapperList  '+ProductWrapperList);
                
                // Create PricebookEntry i.e. Number of Entry == Number of PricebookEntry
                if(StandardPriceBookId != null && productIdMap.size()> 0 && productPriceMap.size() > 0 ){ 
                    for (ProductWrapper objPricebookEntry : ProductWrapperList) {
                        String PriceBookEntryUnitPrice = objPricebookEntry.productCode+''+objPricebookEntry.productName+''+objPricebookEntry.productPrice; 
                        insertPricebookEntry.add(new PricebookEntry(
                            Pricebook2Id =StandardPriceBookId,
                            IsActive = true,
                            Product2Id = productIdMap.get(objPricebookEntry.productCode+''+objPricebookEntry.productName),
                            UnitPrice =productPriceMap.get(PriceBookEntryUnitPrice))
                                                );
                    }
                }
                
                if (insertPricebookEntry.size() > 0 ) {
                    insert insertPricebookEntry; 
                }                
                // End of PricebookEntry Insert Logic


                // Start of ProductOption Insert Logic
                // To Create other entry of ProductOption (Except 1st Entry) from the List i.e. i.e. Number of Entry - 1
                if (nonZeroIndexProductsList.size() > 0) {
                    
                    for(ProductWrapper products : nonZeroIndexProductsList) {
                        String ProductOptionUnitPrice = products.productCode+''+products.productName+''+products.productPrice;
                        insertProductOption.add(new SBQQ__ProductOption__c(
                            SBQQ__Number__c =ProductOptionNumberCount,
                            SBQQ__Quantity__c = 1.00,
                            SBQQ__Selected__c = true,
                            SBQQ__Required__c = true,
                            SBQQ__Type__c = 'Component',
                            SBQQ__ConfiguredSKU__c = zeroIndexProducts.Id,
                            SBQQ__UnitPrice__c = productPriceMap.get(ProductOptionUnitPrice),
                            SBQQ__OptionalSKU__c = productIdMap.get(products.productCode+''+products.productName)));
                        
                        ProductOptionNumberCount += 10;
                    }
                }
                
                if (insertProductOption.size() >0 ) {
                    insert insertProductOption;
                }

                if(insertProductOption.size() > 0){
                    for(SBQQ__ProductOption__c options : insertProductOption){
                        String UniqueProductOption = options.SBQQ__Number__c+'-'+options.SBQQ__UnitPrice__c;
                        productOptionMap.put(UniqueProductOption,options.Id);
                    }
                }
               // End of ProductOption Insert Logic
                
               
                // Start of Quote Insert Logic
                // To Create signle Quote 
                if (String.isNotBlank(oppRecordId)) {
                    InsertQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppRecordId);
                 }
                
                if(InsertQuote != null){
                    insert InsertQuote;
                 }  
                 // End  of Quote Insert Logic
                 
                 // Start of QuoteLine Insert Logic
                 // Insert QuoteLine for the first Entry
                  if (zeroIndexProductsList.size() > 0 ) {
                    for(ProductWrapper ZeroIndex : zeroIndexProductsList) {
                        zeroIndexQuoteLine = new SBQQ__QuoteLine__c(
                            SBQQ__Quote__c = InsertQuote.Id,
                            SBQQ__Number__c = 1,
                            SBQQ__Product__c = productIdMap.get(ZeroIndex.productCode+''+ZeroIndex.productName)
                        );
                    }
                 }

                 if(zeroIndexQuoteLine != null){
                     insert zeroIndexQuoteLine;
                 }
                 
                  // To Create other entry of QuoteLine (Except 1st Entry) from the List i.e. i.e. Number of Entry - 1
                  if (nonZeroIndexProductsList.size() > 0) {
                         Decimal SBQQNumber = zeroIndexQuoteLine.SBQQ__Number__c + 1 ;
                    for(ProductWrapper products : nonZeroIndexProductsList) {
                        String getProductOptionId = OptionCount+'-'+products.productPrice;
                        System.debug('getProductOptionId  '+getProductOptionId);
                        
                        insertQuoteLine.add(new SBQQ__QuoteLine__c(
                            SBQQ__Quote__c = InsertQuote.Id,
                            SBQQ__Number__c = SBQQNumber,
                            SBQQ__OptionLevel__c = 1,
                            SBQQ__OptionType__c = 'Component',
                            SBQQ__RequiredBy__c = zeroIndexQuoteLine.Id,
                            SBQQ__ProductOption__c = productOptionMap.get(getProductOptionId),
                            SBQQ__Product__c = productIdMap.get(products.productCode+''+products.productName)));

                        SBQQNumber += 1; 
                        OptionCount += 10;
                    }
                }

                 if (insertQuoteLine.size() > 0 ) { 
                       insert insertQuoteLine;
                  } 
                // End of QuoteLine Insert Logic
               
            }
            
            return InsertQuote.Id;

        } catch (Exception e) {
            System.debug('Error Line Number '+e.getLineNumber() + '\n'+ 'Error Message '+e.getMessage());
            throw new AuraHandledException('Error Line Number '+e.getLineNumber() + '\n'+ 'Error Message '+e.getMessage());
        }
    }

    // Wrapper class to hold Product details
    public class ProductWrapper {
        @AuraEnabled public string productCode;
        @AuraEnabled public string productName;
        @AuraEnabled public Decimal productPrice; 
    }
}