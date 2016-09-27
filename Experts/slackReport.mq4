//+------------------------------------------------------------------+
//|                                                  slackReport.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int lastTradeDate = GlobalVariableGet("lastTrade");
int lastTransactionDate = GlobalVariableGet("lastTransaction");
  //+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
 {
  if (lastTradeDate == NULL) {
   lastTradeDate = TimeCurrent();
  }
  if (lastTransactionDate == NULL) {
   lastTransactionDate = TimeCurrent();
  }
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
void OnTimer() {
  int hstTotal = OrdersTotal();
  Print("Last Trade Date: ", lastTradeDate);
  for (int i=0; i < hstTotal; i++) {
     //---- check selection result
     if(OrderSelect(i, SELECT_BY_POS) == false) {
        Print("Access to history failed with error (", GetLastError(), ")");
        break;
     }
     int date = OrderOpenTime();
     if (date > lastTradeDate) {
        int orderType = OrderType();
        if (orderType != OP_SELL && orderType != OP_BUY) {
           continue;
        }
        if (Symbol() != OrderSymbol()) {
         continue;
        }
        double openM5 = getRSI(date, PERIOD_M5);
        double openM15 = getRSI(date, PERIOD_M15);
        double openM30 = getRSI(date, PERIOD_M30);
        double openH1 = getRSI(date, PERIOD_H1);

        string text = "*New Order Created*\n#"+OrderTicket()+" "+(orderType==OP_SELL?"Sell":"Buy")+": "+OrderLots()+"@"+OrderSymbol()+" "
                     +OrderOpenPrice()+" RSI("+openM5+","+openM15+","+openM30+","+openH1+")";
        int res = sendToSlack("#reports", text);
        if (res != 200) {
         Print(GetLastError());
         continue;
        }
        OrderPrint();
        lastTradeDate = date;
        GlobalVariableSet("lastTrade", lastTradeDate);
     }
  }
  //---
  // retrieving info from account history
  hstTotal = OrdersHistoryTotal();
  Print("Last Transaction Date: ", lastTransactionDate);
  for (int i=0; i < hstTotal; i++) {
     //---- check selection result
     if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) {
        Print("Access to history failed with error (", GetLastError(), ")");
        break;
     }
     int date = OrderCloseTime();
     if (date > lastTransactionDate) {
        int orderType = OrderType();
        if (orderType != OP_SELL && orderType != OP_BUY) {
           continue;
        }
        if (Symbol() != OrderSymbol()) {
         continue;
        }
        int openDate = OrderOpenTime();
        double openM5 = getRSI(openDate, PERIOD_M5);
        double closeM5 = getRSI(date, PERIOD_M5);
        double openM15 = getRSI(openDate, PERIOD_M15);
        double closeM15 = getRSI(date, PERIOD_M15);
        double openM30 = getRSI(openDate, PERIOD_M30);
        double closeM30 = getRSI(date, PERIOD_M30);
        double openH1 = getRSI(openDate, PERIOD_H1);
        double closeH1 = getRSI(date, PERIOD_H1);
        string text = (orderType==OP_SELL?"Sell":"Buy")+": "+OrderLots()+"@"+OrderSymbol()+" "+OrderOpenPrice()
                     +" RSI("+openM5+","+openM15+","+openM30+","+openH1+")\n"+(orderType==OP_SELL?"Buy":"Sell")
                     +": "+OrderLots()+"@"+OrderSymbol()+" "+OrderClosePrice()+" RSI("+closeM5+","+closeM15+","+closeM30+","
                     +closeH1+")| P/L "+OrderProfit();
        int res = sendToSlack("#reports", text);
        if (res != 200) {
         Print(GetLastError());
         continue;
        }
        OrderPrint();
        lastTransactionDate = date;
        GlobalVariableSet("lastTransaction", lastTransactionDate);
     }
  }
  //---
  // retrieving info from trade
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