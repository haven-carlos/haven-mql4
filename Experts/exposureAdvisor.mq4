//+------------------------------------------------------------------+
//|                                              exposureAdvisor.mq4 |
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
   EventSetTimer(3600);
      
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
   //---
  // retrieving info from trade
  int hstTotal = OrdersTotal();
  double buyExposure = 0;
  double sellExposure = 0;
  double buyPosition = 0;
  double sellPosition = 0;
  for (int i=0; i < hstTotal; i++) {
     //---- check selection result
     if(OrderSelect(i, SELECT_BY_POS) == false) {
        Print("Access to history failed with error (", GetLastError(), ")");
        break;
     }
     int orderType = OrderType();
     if (orderType == OP_SELL) {
      sellExposure += OrderLots();
      sellPosition += (OrderOpenPrice() * OrderLots());
     } else {
       if (orderType == OP_BUY) {
         buyExposure += OrderLots();
         buyPosition += (OrderOpenPrice() * OrderLots());
       } 
     }
  }
  string text = "*Buy*\nExposure: "+NormalizeDouble(buyExposure, 2);
  if (buyExposure != 0) {
    text += " Avg. Position: "+NormalizeDouble(buyPosition/buyExposure,5); 
  }
  text += "\n*Sell*\nExposure: "+NormalizeDouble(sellExposure, 2);
  if (sellExposure != 0) {
    text += " Avg. Position: "+NormalizeDouble(sellPosition/sellExposure,5); 
  }
  double netExposure = MathAbs(buyExposure - sellExposure);
  text += "\n*Net Exposure*: "+NormalizeDouble(netExposure,2);
  double balance = AccountBalance();
  double percentageExposure = (netExposure * 100000) / (balance * 100);
  text += "\n*% over balance*: "+NormalizeDouble(percentageExposure*100,2);
  Alert(text);
  sendToSlack("#forex-desk", text);
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