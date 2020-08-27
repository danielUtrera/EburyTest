@IsTest
public class TradeControllerTest {
    
	@IsTest(SeeAllData=true)
    static void newTrade(){
        CollaborationGroup newGroup=new CollaborationGroup(Name='TestTradeReviewers',CollaborationType='Private');
        insert newGroup;
        
        API_Key__mdt[] apiKeysMdt=[SELECT Value__c FROM API_Key__mdt WHERE DeveloperName='FixerIO'];
        System.assertEquals(1,apiKeysMdt.size(),'API Key record found');
        
        String fixerResponse='{"success":true,"timestamp":1598537646,"base":"EUR","date":"2020-08-27","rates":{"USD":1.1037,"EUR":1}}';
        
        MockHttpResponseHandler.SimpleMockResponse fixerCall = new MockHttpResponseHandler.SimpleMockResponse('GET', fixerResponse);
        fixerCall.statusCode=200;
        
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:FixerIO/latest?access_key='+apiKeysMdt[0].Value__c, fixerCall);
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        Datetime now=Datetime.now();
        Trade__c trade=TradeController.saveTrade(1000, 'EUR','USD');
        Test.stopTest();
        
        System.assertNotEquals(null, trade.Id, 'Trade saved to DB');
        
        trade=[SELECT Buy_Amount__c,Buy_Currency__c,Date_Booked__c,Name,Rate__c,Sell_Amount__c,Sell_Currency__c FROM Trade__c WHERE Id = :trade.Id];
        System.assertEquals(true, trade.Name.startsWith('TR'), 'Right id');
        System.assertEquals(1000*1.1037, trade.Buy_Amount__c, 'Right buy amount');
        System.assertEquals('USD', trade.Buy_Currency__c, 'Right buy currency code');
        System.assertEquals(1000, trade.Sell_Amount__c, 'Right buy amount');
        System.assertEquals('EUR', trade.Sell_Currency__c, 'Right buy currency code');
        System.assertEquals(1.1037, trade.Rate__c, 'Right buy amount');
        System.assertEquals(
            true,
            now.addSeconds(-4)<trade.Date_Booked__c
            &&
            trade.Date_Booked__c<now.addSeconds(4),
            'Right date booked'
        );
    }
    @IsTest
    static void newTradeException(){
        API_Key__mdt[] apiKeysMdt=[SELECT Value__c FROM API_Key__mdt WHERE DeveloperName='FixerIO'];
        System.assertEquals(1,apiKeysMdt.size(),'API Key record found');
        
        String fixerResponse='{"success":true,"timestamp":1598537646,"base":"EUR","date":"2020-08-27","rates":{"USD":1.1037,"EUR":1}}';
        
        MockHttpResponseHandler.SimpleMockResponse fixerCall = new MockHttpResponseHandler.SimpleMockResponse('GET', fixerResponse);
        fixerCall.statusCode=200;
        
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:FixerIO/latest?access_key='+apiKeysMdt[0].Value__c, fixerCall);
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        Exception ex;
        try{
            Trade__c trade=TradeController.saveTrade(1000, 'USD',null);
        }
        catch(AuraHandledException e){
            ex=e;
        }
        Test.stopTest();
        System.assertNotEquals(null, ex, 'Exception captured and handled');
    }
    
    @IsTest
    static void checkRates(){
        API_Key__mdt[] apiKeysMdt=[SELECT Value__c FROM API_Key__mdt WHERE DeveloperName='FixerIO'];
        System.assertEquals(1,apiKeysMdt.size(),'API Key record found');
        
        String fixerResponse='{"success":true,"timestamp":1598537646,"base":"EUR","date":"2020-08-27","rates":{"USD":1.1037,"EUR":1}}';
        
        MockHttpResponseHandler.SimpleMockResponse fixerCall = new MockHttpResponseHandler.SimpleMockResponse('GET', fixerResponse);
        fixerCall.statusCode=200;
        
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse('callout:FixerIO/latest?access_key='+apiKeysMdt[0].Value__c, fixerCall);
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        Datetime now=Datetime.now();
        Double res=TradeController.conversionRate('EUR','USD');
        Test.stopTest();
        System.assertEquals(1.1037,res,'Right rate retrieved');
    }
    
    @IsTest
    static void queryTrades(){
        Test.startTest();
        Trade__c[] trades=TradeController.getTradeRecords();
        Test.stopTest();
        System.assertEquals(0, trades.size(),'Right amount of trade records found');
    }
}