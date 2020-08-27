import { LightningElement,track,wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';

import getTradeRecords from '@salesforce/apex/TradeController.getTradeRecords';

import NEW_TRADE_LABEL from '@salesforce/label/c.NEW_TRADE';
import BOOKED_TRADES_LABEL from '@salesforce/label/c.BOOKED_TRADES';
import DATE_BOOKED_LABEL from '@salesforce/label/c.DATE_BOOKED';
import SELL_AMOUNT_LABEL from '@salesforce/label/c.SELL_AMOUNT';
import SELL_CCY_LABEL from '@salesforce/label/c.SELL_CCY';
import BUY_AMOUNT_LABEL from '@salesforce/label/c.BUY_AMOUNT';
import BUY_CCY_LABEL from '@salesforce/label/c.BUY_CCY';
import RATE_LABEL from '@salesforce/label/c.RATE';

import SELL_CURRENCY_CODE from "@salesforce/schema/Trade__c.Sell_Currency__c";
import SELL_AMOUNT from "@salesforce/schema/Trade__c.Sell_Amount__c";
import BUY_CURRENCY_CODE from "@salesforce/schema/Trade__c.Buy_Currency__c";
import BUY_AMOUNT from "@salesforce/schema/Trade__c.Buy_Amount__c";
import RATE from "@salesforce/schema/Trade__c.Rate__c";
import DATE_BOOKED from "@salesforce/schema/Trade__c.Date_Booked__c";

const COLUMNS = [
    {
        label: SELL_CCY_LABEL, 
        fieldName: SELL_CURRENCY_CODE.fieldApiName, 
        type: "text" 
    },
    {
        label: SELL_AMOUNT_LABEL,
        fieldName: SELL_AMOUNT.fieldApiName,
        type: "number",
        typeAttributes: {
            maximumFractionDigits: 2
        }
    },
    { 
        label: BUY_CCY_LABEL, 
        fieldName: BUY_CURRENCY_CODE.fieldApiName, 
        type: "text"
    },
    {
        label: BUY_AMOUNT_LABEL,
        fieldName: BUY_AMOUNT.fieldApiName,
        type: "number",
        typeAttributes: {
            maximumFractionDigits: 2
        }
    },
    {
        label: RATE_LABEL,
        fieldName: RATE.fieldApiName,
        type: "number",
        typeAttributes: {
            maximumFractionDigits: 4
        }
    },
    { 
        label: DATE_BOOKED_LABEL, 
        fieldName: DATE_BOOKED.fieldApiName, 
        type: "date",
        typeAttributes: {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
        }
    }    
]; 

export default class TradeViewLWC extends LightningElement {
    NEW_TRADE=NEW_TRADE_LABEL;

    columns = COLUMNS;
    showModal=false;
    @track tradeRecords=[];


    @wire(getTradeRecords)
    tradeRecordsWire(result) {
        this.tradeRecords = result;
    }

    newTrade(){
        this.showModal=true;
    }

    closeModal(event){
        this.showModal=false;
        if(event.detail.refresh){
            refreshApex(this.tradeRecords);
        }
    }
}