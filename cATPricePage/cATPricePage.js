import { api, LightningElement, track } from 'lwc';
import saveProductsDetails from '@salesforce/apex/CATPricePageController.saveController';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

export default class CATPricePage extends NavigationMixin(LightningElement) {
   
    @api isPreview = false;
    addedproducts ;
    error;
    @api recordId;
    disableSaveButton = false;  

    // Variable for JS call
    @track productsArrayList = [];
    totalPrice = 0.00;
    priceModelName;
  
    handleRichTextChange(event) {
       this.addedproducts = event.detail.value;
    }
    
    handleModelChange(event){
        this.priceModelName = event.target.value;
    }
 
    Back(){ 
        this.isPreview = false;
        this.productsArrayList = [];
        this.totalPrice = 0.00;
        this.disableSaveButton = false; 
        console.log('isPreview  '+this.isPreview +'\n'+'totalPrice '+this.totalPrice + '\n'+ 'productsArrayList '+productsArrayList + '\n' + 'disableSaveButton  '+this.disableSaveButton);
    }

    // code with JS Logic
    PreviewHandler(){
        try{

        var inputRichValue = this.addedproducts;
        var PriviewValidateCheck = true;

        var strRemoveOpeningTag;
        var inputRichValueArray = [];
        var productsArray = [];
     
        if (inputRichValue == undefined ) { //   || inputRichValue.length == 0 || inputRichValue == ' '
            PriviewValidateCheck = false;
            this.showToastMessage('Error', 'Please add product details.','error');
          } 

        if(PriviewValidateCheck){  

        inputRichValue = inputRichValue.includes('&nbsp;') ? inputRichValue.replaceAll('&nbsp;', ' ') : inputRichValue;
  
        inputRichValueArray.push(inputRichValue);

        for (var i = 0; i < inputRichValueArray.length; i++) {
            strRemoveOpeningTag = inputRichValueArray[i].includes('<p>') ? inputRichValueArray[i].replaceAll('<p>', ' ') : strRemoveOpeningTag;
            strRemoveOpeningTag = strRemoveOpeningTag.includes('</p>') ? strRemoveOpeningTag.replaceAll('</p>', ',') : strRemoveOpeningTag;
            strRemoveOpeningTag = strRemoveOpeningTag.includes('<br>,') ? strRemoveOpeningTag.replaceAll('<br>,', '') : strRemoveOpeningTag;
         }
         
        
         productsArray = strRemoveOpeningTag.split(','); 
        
         for (var j = 0; j <= productsArray.length - 2; j++) {
            try{

            var str = productsArray[j]; 
            
            var trimStr = !str || str.length === 0 ? str : productsArray[j].trim();

            // To Store Product Code 

            // Remove the Tab space from String // tab space will contain \t 
            var ProductCode = trimStr.includes('\t') ? trimStr.replaceAll('\t',' ') : trimStr;
            var strProductCode = ProductCode.substring(0, ProductCode.indexOf(' '));

           //Products Price
            var strProductPrice = str.includes('$') ? str.substring(str.lastIndexOf('$') - 1 ) : 0.00 ; 

            // ProductName
            var ProductName = str.replace(strProductCode, ' ');
            var ProductDotName = strProductPrice == 0 ? ProductName : ProductName.replace(strProductPrice, ' ');
            var strProductName = ProductDotName.includes('.') ? ProductDotName.replaceAll('.','') : ProductDotName; 
            
            // If Price == 0, then diplay it as $0.00 on UI
            var strProductPrice = strProductPrice == 0 ? '$0.00' : strProductPrice;

            // Calculate Total Products Price
            var Price = str.includes('$') ? str.substring(str.lastIndexOf('$') + 1 ) : 0.00 ;          
            this.totalPrice += Number(Price); 
           
            var productObjects = {};
            productObjects['Id'] = j;
            productObjects['productCode'] = strProductCode;
            productObjects['productPrice'] = strProductPrice;
            productObjects['productName'] = strProductName;
            productObjects['price'] = Number(Price);

            this.productsArrayList.push(productObjects); 

            console.log(' String From Array  ' +str +'  '+j);
            console.log(' Trim String  ==> '+trimStr +'  '+j);
            console.log(' strProductCode ==> '+strProductCode +'  '+j);
            console.log(' strProductPrice ==> '+strProductPrice +'  '+j);
            console.log(' ProductName ==> '+ProductName +'  '+j);
            console.log(' strProductName ==> '+strProductName +'  '+j);
            console.log(' totalPrice ==> '+this.totalPrice +'  '+j);
           
            console.log(' productObjects ==> '+JSON.stringify(this.productObjects)+'  '+j);
            console.log(' productsArrayList ==> '+JSON.stringify(this.productsArrayList)+'  '+j);

        } 
        catch (err){
            console.log(' Error in For loop ==> '+err+'  '+j);
            this.showToastMessage('Error', 'The system has encountered an unexpected error!','error');
        }
  
     } 
         this.totalPrice = this.totalPrice.toFixed(2);
         this.isPreview = true;
        
    }
   }
    catch (errMessage){
        console.log(' Errorin Method ==> '+errMessage);
        this.showToastMessage('Error', 'The system has encountered an unexpected error!','error');
    }


    }

     // Logic for Save Button
     submitProducts(){       
       this.disableSaveButton = true; 

       saveProductsDetails({oppRecordId: this.recordId, wrapperProducts: JSON.stringify(this.productsArrayList), priceModel:this.priceModelName})
        .then((result) => {
           
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/sbqq__sb?id='+result
                }
            })

            this.showToastMessage('Success', 'The details of your products have been saved!','success');
            this.disableSaveButton = true; 
           // this.dispatchEvent(new CloseActionScreenEvent());

        })
        .catch(error => {   
            this.error = error;            
            this.disableSaveButton = false; 
            console.log('error message in submitProducts Method without JSON stringify==> '+error); 
            console.log('error message in submitProducts Method with JSON stringify==> '+JSON.stringify(error)); 
            this.showToastMessage('Error', error.body.message,'error');
           
        });
    }

    showToastMessage(title, message, variant ){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
   
}