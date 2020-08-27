public with sharing class TradeController {
	@AuraEnabled(cacheable=true)
    public static Trade__c[] getTradeRecords(){
        return [SELECT Id,
                	FORMAT(Buy_Amount__c),Buy_Currency__c,
                	FORMAT(Date_Booked__c),
                	Name,
                	FORMAT(Rate__c),
                	FORMAT(Sell_Amount__c),Sell_Currency__c FROM Trade__c WITH SECURITY_ENFORCED ORDER BY Date_Booked__c desc LIMIT 50000];
    }
    
    @AuraEnabled(cacheable=true)
    public static Double conversionRate(String sellCurrencyCode , String buyCurrencyCode){
        try{
            //Initial response
            Double res=0.0000;
            
            //Since I cant change the base currency I have to check if the currency to be sold is the base from the response (EUR)
            Boolean sameBaseCurrency=true;
            
            //Read the metadata to get the service API KEY
        	API_Key__mdt apiKeyMdt=[SELECT Value__c FROM API_Key__mdt WHERE DeveloperName='FixerIO'];
            
            //PREPARE THE CALLOUT
            HttpRequest req = new HttpRequest();  
            req.setEndpoint('callout:FixerIO/latest?access_key='+apiKeyMdt.Value__c);
            req.setMethod('GET');
            req.setTimeout(3000);
            
            //SEND THE REQUEST
            Http http = new Http();
            HttpResponse httpRes= http.send(req);
            
            //PARSE THE RESPONSE INTO A MAP
            Map<String,Object> parsedMap=(Map<String,Object>)JSON.deserializeUntyped(httpRes.getBody());
            
            //CHECK THAT THE CALLOUT WAS A SUCCESS
            if(parsedMap.containsKey('success')
               &&
               parsedMap.get('success')==true){
                
                //PARSE THE RATES INTO A MAP
                Map<String,Object> rates=(Map<String,Object>)parsedMap.get('rates');
                
                //CALCULATE THE RATE BASED ON THE SELL CURRENCY CODE, BUY CURRENCY CODE AND BASE CURRENCY CODE FROM THE SERVICE
                res=Double.valueOf(rates.get(buyCurrencyCode))/Double.valueOf(rates.get(sellCurrencyCode));
            }
            
            //RETURN THE RATE FIXED TO 4 DECIMALS
            return Decimal.valueOf(res).setScale(4);
        }catch(Exception e){
            //IF THE CALLOUT OR THE METADATA QUERY FAILS IT RETURNS 0
            System.debug(e);
            return 0.0000;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static Trade__c saveTrade(Decimal sellAmount,String sellCurrencyCode,String buyCurrencyCode){
        try{
            //GET THE RATE AND CALCULATE THE BUY AMOUNT BEFORE CREATING THE RECORD
            Double rate=TradeController.conversionRate(sellCurrencyCode,buyCurrencyCode);
            Trade__c trade=new Trade__c
            (
                Buy_Amount__c= sellAmount*rate,
                Buy_Currency__c= buyCurrencyCode,
                Date_Booked__c= Datetime.now(),
                Rate__c= rate,
                Sell_Amount__c = sellAmount,
                Sell_Currency__c = sellCurrencyCode
            );
        
           insert trade;
            
           trade=[SELECT Id,
                	FORMAT(Buy_Amount__c),Buy_Currency__c,
                	FORMAT(Date_Booked__c),
                	Name,
                	FORMAT(Rate__c),
                   	FORMAT(Sell_Amount__c),Sell_Currency__c 
                   FROM Trade__c 
                   WHERE Id = :trade.Id];
        	String groupName=Test.isRunningTest()?'TestTradeReviewers':'Trade reviewers';
           	CollaborationGroup reviewersGroup=[SELECT Id FROM CollaborationGroup WHERE Name=:groupName];
           	String chatterPostText=System.Label.NEW_TRADE_CHATTER_POST;
           	chatterPostText=chatterPostText.replace('{rate}', String.valueOf(trade.Rate__c))
               .replace('{date}', trade.Date_Booked__c.format()).replace('trade link', trade.Id)
               .replace('{sell amount}', String.valueOf(trade.Sell_Amount__c)).replace('{sell ccy}', trade.Sell_Currency__c)
               .replace('{buy amount}', String.valueOf(trade.Buy_Amount__c)).replace('{buy ccy}', trade.Buy_Currency__c);
           
           ConnectApiHelper.postFeedItemWithMentions(
               'internal', //community Id where to post, or "internal", or null
  				reviewersGroup.Id, //this is the record where the post will appear
  				chatterPostText
           );
           
           return trade;
        }
        catch(Exception e){
            System.debug(e);
            throw new AuraHandledException('');
        }
    }
}