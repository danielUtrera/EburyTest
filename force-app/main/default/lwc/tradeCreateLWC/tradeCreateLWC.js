import { LightningElement,api,wire } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import TRADE_OBJECT from '@salesforce/schema/Trade__c';
import BUY_CURRENCY_CODE_OPTIONS from '@salesforce/schema/Trade__c.Buy_Currency__c';
import SELL_CURRENCY_CODE_OPTIONS from '@salesforce/schema/Trade__c.Sell_Currency__c';

import NEW_TRADE_LABEL from '@salesforce/label/c.NEW_TRADE';
import CANCEL_LABEL from '@salesforce/label/c.CANCEL';
import SAVE_LABEL from '@salesforce/label/c.SAVE';
import SELL_AMOUNT_LABEL from '@salesforce/label/c.SELL_AMOUNT';
import SELL_CURRENCY_LABEL from '@salesforce/label/c.SELL_CURRENCY';
import BUY_AMOUNT_LABEL from '@salesforce/label/c.BUY_AMOUNT';
import BUY_CURRENCY_LABEL from '@salesforce/label/c.BUY_CURRENCY';
import RATE_LABEL from '@salesforce/label/c.RATE';
import GENERIC_ERROR_LABEL from '@salesforce/label/c.GENERIC_ERROR';
import TRADE_SAVE_SUCCESS_LABEL from '@salesforce/label/c.TRADE_SAVE_SUCCESS';
import TRADE_SAVE_ERROR_LABEL from '@salesforce/label/c.TRADE_SAVE_ERROR';

import conversionRate from "@salesforce/apex/TradeController.conversionRate";
import saveTrade from "@salesforce/apex/TradeController.saveTrade";

export default class TradeCreateLWC extends LightningElement {
    NEW_TRADE=NEW_TRADE_LABEL;
    CANCEL=CANCEL_LABEL;
    SAVE=SAVE_LABEL;
    SELL_AMOUNT=SELL_AMOUNT_LABEL;
    SELL_CURRENCY=SELL_CURRENCY_LABEL;
    BUY_AMOUNT=BUY_AMOUNT_LABEL;
    BUY_CURRENCY=BUY_CURRENCY_LABEL;
    RATE=RATE_LABEL;
    GENERIC_ERROR=GENERIC_ERROR_LABEL;
    TRADE_SAVE_SUCCESS=TRADE_SAVE_SUCCESS_LABEL;
    TRADE_SAVE_ERROR=TRADE_SAVE_ERROR_LABEL;

    @api showModal=false;
    disallowSave=true;

    sellCurrencyCodeSelected;
    buyCurrencyCodeSelected;
    rate=0.0000;
    buyAmount=0.0000;
    sellAmount;


    @wire(getObjectInfo, { objectApiName: TRADE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: BUY_CURRENCY_CODE_OPTIONS})
    buyCurrencyCodes;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SELL_CURRENCY_CODE_OPTIONS})
    sellCurrencyCodes;

    closeModalEvent(refresh){
        this.buyCurrencyCodeSelected=undefined;
        this.sellCurrencyCodeSelected=undefined;
        this.buyAmount=0.0000;
        this.rate=0.0000;
        this.sellAmount=undefined;
        const selectedEvent = new CustomEvent("closemodal", {
            detail:
            {
                refresh: refresh
            }
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    closeModal(){
        this.closeModalEvent(false);
    }

    updateSellAmount(event){
        this.sellAmount=event.detail.value;
        this.buyAmount=this.rate*this.sellAmount;
        this.allowSave();
    }
    
    selectSellCurrencyCode(event){
        this.sellCurrencyCodeSelected=event.detail.value;
        this.updateRate();
        this.allowSave();
    }

    selectBuyCurrencyCode(event){
        this.buyCurrencyCodeSelected=event.detail.value;
        this.updateRate();
        this.allowSave();
    }

    updateRate(){
        conversionRate({sellCurrencyCode: this.sellCurrencyCodeSelected,buyCurrencyCode:this.buyCurrencyCodeSelected})
        .then(data => {
            console.log('DATA',data);
            this.rate=data;
            if(this.sellAmount){
                this.buyAmount=this.rate*this.sellAmount;
            }
        })
        .catch(error =>{
            console.log(JSON.stringify(error));
            this.rate=0.0000;
            this.buyAmount=0.0000;
        });
    }

    allowSave(){
        if(this.rate && this.buyCurrencyCodeSelected && this.buyCurrencyCodeSelected && this.sellCurrencyCodeSelected){
            this.disallowSave=false;
        }
        else{
            this.disallowSave=true;
        }
    }

    saveTrade(){
        this.disallowSave=true;
        saveTrade({sellAmount:this.sellAmount,sellCurrencyCode: this.sellCurrencyCodeSelected,buyCurrencyCode:this.buyCurrencyCodeSelected})
        .then(data => {
            this.closeModalEvent(true);
            const event = new ShowToastEvent({
                title: this.TRADE_SAVE_SUCCESS,
                message: '',
                variant: 'success',
                mode: 'sticky'
            });
            this.dispatchEvent(event);
        })
        .catch(error =>{
            this.closeModalEvent(false);
            const event = new ShowToastEvent({
                title: this.TRADE_SAVE_ERROR,
                message: this.GENERIC_ERROR,
                variant: 'error',
                mode: 'sticky'
            });
            this.dispatchEvent(event);
        });
    }
}