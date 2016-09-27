//+------------------------------------------------------------------+
//|                                                PendingOrders.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---

   string terminal_data_path=TerminalInfoString(TERMINAL_DATA_PATH);
   string filename="OrdersReport.csv";
   printf(filename);
   int handle=FileOpen(filename,FILE_CSV|FILE_WRITE,",");
   if(handle<0) {
      Alert("OrdersReport.csv was not opened ");
      return;
   }
     
     // write header
     FileWrite(handle,"#","open_price","open_time","symbol","lots","type");
     int total=OrdersTotal();
     // write open orders
     for(int pos=0;pos<total;pos++)
       {
        if(OrderSelect(pos,SELECT_BY_POS)==false) continue;
        FileWrite(handle,OrderTicket(),OrderOpenPrice(),OrderOpenTime(),OrderSymbol(),OrderLots(), OrderType());
       }
     FileClose(handle);
     Alert("OrdersReport.csv was produced");
  }
//+------------------------------------------------------------------+
