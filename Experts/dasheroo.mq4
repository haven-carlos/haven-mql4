//+------------------------------------------------------------------+
//|                                                     dasheroo.mq4 |
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
   EventSetTimer(60);
      
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
   double balance = AccountBalance();
   datetime now = TimeLocal();
   string nowstr = TimeToString(now, TIME_DATE);
   StringReplace(nowstr, ".", "-");
   char data[], result[];
   string headers;
   string json = "value="+balance+"&label=Balance&type=currency";
   //--- Create the body of the POST request for authorization
   //StringToCharArray(json, data, 0, StringLen(json));
   int res = WebRequest("PUT", "https://www.dasheroo.com/external/api/subscriptions/b764e17f62b098c4a141ca840fcabc47?"+json, "", NULL,
                        10000, data, ArraySize(data), result, headers);
   Print(res);
   Print(json);
   if (res != 200) {
      Print(GetLastError());
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
