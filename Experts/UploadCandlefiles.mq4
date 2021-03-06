//+------------------------------------------------------------------+
//|                                            UploadCandlefiles.mq4 |
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


string Crypto[6] = {"BTC","ETC","ETH","LTC","NMC","BFX"};
string G8[8] = {"USD","EUR","JPY","GBP","AUD","NZD","CHF","CAD"};

/* returns true iff symbol contains both currencies under a basket*/
bool CurrencyBasket(string SymbolName, string &Basket[], double Strict = 1){

   string Base=StringSubstr(SymbolName,0,3);
   string Counter=StringSubstr(SymbolName,3,3); 

   bool ContainsBase, ContainsCounter = false;
   for(int i=0; i<ArraySize(Basket); i++){
      if (StringCompare(Base,Basket[i]) == 0)
         ContainsBase = true;
         
      if (StringCompare(Counter,Basket[i]) == 0)
         ContainsCounter = true;
   }
   
   if (Strict)
      return ContainsBase && ContainsCounter;
   else
      return ContainsBase || ContainsCounter; 
}

bool Forex(string SymbolName){
   return CurrencyBasket(SymbolName, G8, 1);
}


void WriteCandles(string SymbolName, int timeframe){
   string terminal_data_path=TerminalInfoString(TERMINAL_DATA_PATH);
   string filename=SymbolName+"-M"+timeframe+".csv";
   printf(filename);
   int handle=FileOpen(filename,FILE_CSV|FILE_WRITE,",");
   if(handle<0) {
      Alert(filename + " was not opened ");
      return;
   }
     
   // write header
   FileWrite(handle,"Time","Open","High","Low","Close","Volume");
   int total=OrdersTotal();
   
   // write open orders
   
   int historyCount = iBars(SymbolName, timeframe);
   int p = timeframe;
   datetime now = TimeCurrent();
   for(int s=1;s<historyCount;s++) {
      datetime t = now - s*60;
       FileWrite(handle, TimeToStr(t), 
         iOpen(SymbolName, p, s),
         iHigh(SymbolName, p, s),
         iLow(SymbolName, p, s),
         iClose(SymbolName, p, s),
         iVolume(SymbolName, p, s));
         
      //FirebasePutCandle(SymbolName, p, t, iOpen(SymbolName, p, s), iHigh(SymbolName, p, s), iLow(SymbolName, p, s), iClose(SymbolName, p, s));
   }
   FileClose(handle);
}

int FirebasePutCandle(string SymbolName, int timeframe, datetime time, double open, double high, double low, double close) {
   char data[], result[];
   string headers;
   int timestamp = time;
   
   string json = "{ \"timestamp\": " + timestamp + ",";
   json += " \"open\": " + open + ",";
   json += " \"high\": " + high + ",";
   json += " \"low\": " + low + ",";
   json += " \"close\": " + close ;
   json += "}";
   
   //  ={\"text\":\""+text+"\",\"channel\":\""+channel+"\"}";
   //--- Create the body of the POST request for authorization
   StringToCharArray(json, data, 0, StringLen(json));
   
   ResetLastError();
   int res = WebRequest("PUT", "https://fxwax-28a0e.firebaseio.com/"+SymbolName+"/M"+timeframe+".json", "", NULL,
                        5000, data, ArraySize(data), result, headers);
   if(res==-1)
     {
      Print(json);
      Print("Error in WebRequest. Error code  =",GetLastError());
   } else {
      Print(json);
      Print(CharArrayToString(result));
      Print("https://fxwax-28a0e.firebaseio.com/"+SymbolName+"/M"+timeframe+".json");
   }
   return res;
}

int OnInit()
  {
//---
   
//---
   bool MWatch = 0;
   int SymbolCount = SymbolsTotal(MWatch);
   for (int i = 0; i < 0; i++){
      string SymbolName = SymbolName(i,MWatch);
      
      if (Forex(SymbolName)){
        WriteCandles(SymbolName, PERIOD_H1);      
      }
   }
    
    WriteCandles("USDJPY", PERIOD_M1);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
