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
   OnTimer();
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
  double profit = 0;
  for (int i=0; i < hstTotal; i++) {
     //---- check selection result
     if(OrderSelect(i, SELECT_BY_POS) == false) {
        Print("Access to history failed with error (", GetLastError(), ")");
        break;
     }
     if (Symbol() != OrderSymbol()) {
      continue;
     }
     profit += OrderProfit();
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
  string text = "*General Report* --> *"+Symbol()+" Buy* E:"+buyExposure;
  if (buyExposure != 0) {
    text += " AP:"+DoubleToString(buyPosition/buyExposure,5); 
  }
  text += " *Sell* E:"+sellExposure;
  if (sellExposure != 0) {
    text += " AP:"+DoubleToString(sellPosition/sellExposure,5); 
  }
  double netExposure = MathAbs(buyExposure - sellExposure);
  text += " *NE*:"+netExposure;
  double balance = AccountBalance();
  if (netExposure != 0) { 
   bool type = false; // sellExposure = false; buyExposure = true;
   if (buyExposure > sellExposure) {
      type = true;
   }
   double pips = MathAbs(profit / (netExposure * 10));
   double breakeven = ((type == false && (profit > 0))||(type == true && (profit < 0)))? (Bid + (pips/10000)) : (Bid - (pips/10000)); 
    text += " *BP*:"+DoubleToString(breakeven,5);
  }
  double percentageExposure = (netExposure * 100000) / (balance * 100);
  text += " *%OB*:"+DoubleToString(percentageExposure*100,2);
  text += "% *Balance* $"+addCommas(DoubleToString(balance,0));
  //Alert(text);
  sendToSlack("#reports", text);
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
string addCommas(string number) {
   string money;
   for(int i=StringLen(number)-1;i>=0;i--) {
    string c = StringSubstr(number, i, 1);
    money += c;
    if (i!=0 && (StringLen(number)-i)%3 == 0) {
      money += ",";
    }
   }
   string str;
   for(int i=StringLen(money)-1;i>=0;i--) {
    string c = StringSubstr(money, i, 1);
    str += c;
   }
   return str;
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