
//+------------------------------------------------------------------+
//|                                                     RsiAlert.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

double BaseEquity = -1;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if (BaseEquity < 0)
      BaseEquity = NormalizeDouble(AccountEquity(),0); 
   
   if (TimeDayOfYear(TimeCurrent())<302){
      BaseEquity = 86939.64; //hard code week 24 to 28 oct
   }
   
   Print ("On init");
//--- create timer
   OnTimer();
   int seconds = 60; //60*60*6; //6 hours
   EventSetTimer(seconds);
      
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
   
   Print(now);
   Print(TimeDayOfYear(now));
   
   //sunday
   if (DayOfWeek() == 1 && TimeHour(now) == 1 && TimeMinute(now) == 0) {
         BaseEquity = NormalizeDouble(AccountEquity(),0);
         
         if (!WeekOpen) {
            sendToSlack("#desk-equity");
            WeekOpen = true;
         }
   }
   
   //friday
   if (TimeHour(now) == 0 && TimeMinute(now) == 0) {
      
      if (DayOfWeek() == 5) {
         sendToSlack("#desk-equity");
         WeekOpen = true;  
      }
   }
  }



int sendToSlack(string channel) {
   char data[], result[];
   string headers;
   double Equity = NormalizeDouble(AccountEquity(),0);
   string message = "*Equity:* " + addCommas(Equity);
   
   message += "\n*Sunday's Equity:* " + addCommas(BaseEquity);
   message += "\n*Week to day:* " + NormalizeDouble((Equity/BaseEquity*100)-100,1) + "%";
   
   string json = "payload={\"text\":\""+message+"\",\"channel\":\""+channel+"\"}";
   //--- Create the body of the POST request for authorization
   StringToCharArray(json, data, 0, StringLen(json));
   
   int res = WebRequest("POST", "https://hooks.slack.com/services/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", "", NULL,
                        10000, data, ArraySize(data), result, headers);
   if(res==-1)
     {
      Print("Error in WebRequest. Error code  =",GetLastError());
   }
   Print("Res: "+ res);
   Print("Server Response: "+CharArrayToString(result,0,ArraySize(result)));
   Print("Server Response Headers: "+headers);
   return res;
}

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