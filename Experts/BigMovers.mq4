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

string Crypto[6] = {"BTC","ETC","ETH","LTC","NMC","BFX"};
string G8[8] = {"USD","EUR","JPY","GBP","AUD","NZD","CHF","CAD"};
string G10[10] = {"USD","EUR","JPY","GBP","AUD","NZD","CHF","CAD","CNH","CNY"};
string G20[20] = {"USD","EUR","JPY","GBP","AUD","NZD","CHF","CAD","CNH","CNY",
                  "DKK","HKD","HUF","ILS","MXN","NOK","PLN","SEK","SGD","RUB"};
string Commodity[4] = {"XAU","XAG","XPT","XPD"};
string EM[] = {"BRL","CZK","INR","TRY","ZAR"};
string Deposit[3] = {"USD","BIT","LIT","IDR"};

int OnInit()
  {

   ScanMovers(PERIOD_W1);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {}


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

/* returns true iff symbol is stock*/
bool Stock(string SymbolName){
   return StringFind(SymbolName, ".",0) > 0;
}

bool Energy(string SymbolName){
   string EndsWith = StringSubstr(SymbolName, StringLen(SymbolName) - 3, 3);
   return StringCompare(EndsWith, "OIL") == 0;
}

bool Index(string SymbolName){
   string Digit[10] = {"0","1","2","3","4","5","6","7","8","9"};
   for (int i = 0; i < 10; i++){
      if (StringFind(SymbolName, Digit[i],1) >= 0)
         return true;
   }
   return false;
}

bool Forex(string SymbolName){
   //return CurrencyBasket(SymbolName, G8, 1);
   return CurrencyBasket(SymbolName, G20, 1) || CurrencyBasket(SymbolName, EM, 0);
}

bool Pair(string SymbolName){
   return StringLen(SymbolName) == 6;
}

int StdWeek() {
   int iDay  = ( TimeDayOfWeek(TimeCurrent()) + 6 ) % 7 + 1,                    // convert day to standard index (1=Mon,...,7=Sun)
       iWeek = ( TimeDayOfYear(TimeCurrent()) - iDay + 10 ) / 7;                // calculate standard week number

   return(iWeek);
 }
   
   
void ScanMovers(int timeframe){
   
   int MarketWatch = 0;
   int MaxLen = SymbolsTotal(MarketWatch);
   string Movers[];
   double BasisPoints[];
   double PercentPoints[];
   
   ArrayResize(Movers, MaxLen, 0);
   ArrayResize(BasisPoints, MaxLen, 0);
   ArrayResize(PercentPoints, MaxLen, 0);
   
   int Count = 0;
   int iShift = 1;
   
   for(int i=0;i<SymbolsTotal(MarketWatch);i++)
   {
      string SymbolName = SymbolName(i,MarketWatch);
     
      if (Pair(SymbolName)){ // no indexes, energy, nor stocks
      
         bool Added = false;
         
         //if (CurrencyBasket(SymbolName, G20, 1)) {
         if (Forex(SymbolName)){
            Added = true;
            Movers[Count] = SymbolName;
            double Change = iClose(SymbolName, timeframe, iShift) - iOpen(SymbolName, timeframe, iShift);
            BasisPoints[Count] = Change;
            if (iOpen(SymbolName, timeframe,0)==0) {
               Print("ERROR: ", SymbolName, iOpen(SymbolName, timeframe, iShift));
               PercentPoints[Count] = 0.0;
            } else {
               double PercentPoint = Change / iOpen(SymbolName, timeframe, iShift)*100;
               PercentPoints[Count] = PercentPoint;
            }
            Count++;
         } 
          
         if (!Added 
            && !Stock(SymbolName)
            && !Index(SymbolName)
            && !CurrencyBasket(SymbolName, Deposit, 1)
            && !CurrencyBasket(SymbolName, Crypto, 0) 
            && !CurrencyBasket(SymbolName, Commodity, 0)
            
         )
            Print(SymbolName  + " no es ");  
      }
   }
   
   double PercentPointsZipped[][2];
   ArrayResize(PercentPointsZipped, Count, 0);
   
   for (int i = 0; i < Count; i ++){
      PercentPointsZipped[i][0] = MathAbs(PercentPoints[i]);
      PercentPointsZipped[i][1] = i;
   }
   
   ArraySort(PercentPointsZipped,WHOLE_ARRAY,0, MODE_DESCEND);
   
   for (int j = 0; j < Count; j++){
       int i =  PercentPointsZipped[j][1];
       Print(j, " " + Movers[i], " " + BasisPoints[i] + " " + PercentPoints[i]);
   }
   
   
   /* Write file */
   
   string terminal_data_path=TerminalInfoString(TERMINAL_DATA_PATH);
   string filename="BigMovers-" + TimeYear(TimeCurrent()) + "-"+(StdWeek() - iShift)+".csv";
   printf(filename);
   int handle=FileOpen(filename,FILE_CSV|FILE_WRITE,",");
   if(handle<0) {
      Alert("OrdersReport.csv was not opened ");
      return;
   }
     
  FileWrite(handle,"Symbol","BasisPoints","PercentagePoints");
  
  for (int j = 0; j < Count; j++){
       int i =  PercentPointsZipped[j][1];
       //Print(j, " " + Movers[i], " " + BasisPoints[i] + " " + PercentPoints[i]);
       FileWrite(handle, Movers[i] , BasisPoints[i], PercentPoints[i]);
   }
   
  FileClose(handle);
  Alert(filename + " was produced");
}
