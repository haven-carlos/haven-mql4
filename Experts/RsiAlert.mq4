//+------------------------------------------------------------------+
//|                                                     RsiAlert.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(30);
      
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
   double M5 = getRSI(now, PERIOD_M5);
   double M15 = getRSI(now, PERIOD_M15);
   double M30 = getRSI(now, PERIOD_M30);
   double H1 = getRSI(now, PERIOD_H1);
   string text = "";
   if (M5 > 70 || M5 < 30) {
      text += "*RSI M5:* "+NormalizeDouble(M5,2)+"\n";
   }
   if (M15 > 70 || M15 < 30) {
      text += "*RSI M15:* "+NormalizeDouble(M15,2)+"\n";
   }
   if (M30 > 70 || M30 < 30) {
      text += "*RSI M30:* "+NormalizeDouble(M30,2)+"\n";
   }
   if (H1 > 70 || H1 < 30) {
      text += "*RSI H1:* "+NormalizeDouble(H1,2)+"\n";
   }
   sendToSlack("#forex-alerts",text);
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
   return res;
}