//+------------------------------------------------------------------+
//|                                                     RsiAlert.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

double last_alert_H1 = NULL;
double last_alert_H4 = NULL;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   OnTimer();
   EventSetTimer(300);
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   datetime now = TimeCurrent();
   double H1 = getRSI(now, PERIOD_H1);
   double H4 = getRSI(now, PERIOD_H4);
   double Price = Ask;
   
   string text = "";
   if (H1 > 70 || H1 < 30) {
      if (last_alert_H1 != H1) {
         if (H1 > 70) {
            Price = Bid;
         }
         text += "*RSI H1:* "+NormalizeDouble(H1,2)+" (_"+Price+"_)\n";
         last_alert_H1 = H1;
      }
   } else {
      if (last_alert_H1 != NULL) {
         last_alert_H1 = NULL;
      }
   }
   
   if (H4 > 70 || H4 < 30) {
      if (last_alert_H4 != H4) {
         if (H4 > 70) {
            Price = Bid;
         }
         text += "*RSI H4:* "+NormalizeDouble(H4,2)+" (_"+Price+"_)\n";
         last_alert_H4 = H4;
      }
   } else {
      if (last_alert_H4 != NULL) {
         last_alert_H4 = NULL;
      }
   }

   if (StringLen(text) != 0) {
      string symbol = Symbol();
      StringToLower(symbol);
      string channel = "#alerts-"+symbol;
      Print(channel);
      sendToSlack(channel,text);
   }
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
double getRSI(int time, int timeframe) {
   int iShift = iBarShift(NULL,timeframe, time, false);
   int rsi = iRSI(NULL, timeframe, 14, PRICE_CLOSE, iShift);
   return MathRound(rsi);
}

int sendToSlack(string channel, string text) {
   char data[], result[];
   string headers;
   string json = "payload={\"text\":\""+text+"\",\"channel\":\""+channel+"\"}";
   //--- Create the body of the POST request for authorization
   StringToCharArray(json, data, 0, StringLen(json));
   int res = WebRequest("POST", "https://hooks.slack.com/services/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", "", NULL,
                        10000, data, ArraySize(data), result, headers);
   if(res==-1)
     {
      Print("Error in WebRequest. Error code  =",GetLastError());
   }
   return res;
}