//+------------------------------------------------------------------+
//|                                                  MACD Sample.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"

input double TakeProfit    = 50;
input double LotsAmount    = 0.5;
input double TrailingStop  = 30;
input int    MATrendPeriod = 10;
input int    ThresholdRSI  = 5; 

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   double iRSI2, iSMA10, closePrice;
   int    cnt,ticket, totalBuys, totalSells;
   int    total = OrdersTotal();
   bool Profitable;
   closePrice = iClose(NULL, 0, 0);
//---
// initial data checks
// it is important to make sure that the expert works with a normal
// chart and the user did not make any mistakes setting external 
// variables (Lots, StopLoss, TakeProfit, 
// TrailingStop) in our case, we check TakeProfit
// on a chart of less than 100 bars
//---
   if(Bars<100)
     {
      Print("bars less than 100");
      return;
     }
   if(TakeProfit<10)
     {
      Print("TakeProfit less than 10");
      return;
     }
   if(TrailingStop<1)
     {
      Print("Stop Loss less than 1");
      return;
     }
//--- to simplify the coding and speed up access data are put into internal variables

   iRSI2 = iRSI(NULL,0,2,PRICE_CLOSE,1);
   iSMA10 = iMA(NULL,0,MATrendPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   
   totalBuys = 0;
   totalSells = 0;
   for(cnt=0;cnt<OrdersTotal();cnt++){
      if(!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
         continue;
      if(OrderType()<=OP_SELL &&   // check for opened position 
         OrderSymbol()==Symbol())  // check for symbol
            totalSells += 1;
      if(OrderType()<=OP_BUY &&   // check for opened position 
         OrderSymbol()==Symbol())  // check for symbol
            totalBuys += 1;            
         
   }
   
   if(totalBuys + totalSells <5) {
      //--- no opened orders identified
      if(AccountFreeMargin()<(1000*LotsAmount))
        {
         Print("We have no money. Free Margin = ",AccountFreeMargin());
         return;
        }
      //--- check for long position (BUY) possibility
      if (totalBuys < 2 && iRSI2 < ThresholdRSI){
         ticket=OrderSend(Symbol(),OP_BUY,LotsAmount,
                          Ask,3, Ask-Point*TrailingStop, Ask+TakeProfit*Point, 
                          "iRSI buy ",16384,0,Green);
         if(ticket>0)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               Print("BUY order opened : ",OrderOpenPrice());
           }
         else
            Print("Error opening BUY order : ",GetLastError());
         return;
      }
      
      //--- check for short position (SELL) possibility
      
      if(totalSells < 2 && iRSI2 > 100-ThresholdRSI)
        {
         ticket=OrderSend(Symbol(),OP_SELL,LotsAmount,
                          Bid,3, Bid+Point*TrailingStop, Bid-TakeProfit*Point, 
                          "iRSI sell",16384,0,Red);
         if(ticket>0)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               Print("SELL order opened : ",OrderOpenPrice());
           }
         else
            Print("Error opening SELL order : ",GetLastError());
        }
      //--- exit from the "no opened orders" block
      return;
     }
     
   //--- it is important to enter the market correctly, but it is more important to exit it correctly...   
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      if(!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
         continue;
      if(OrderType()<=OP_SELL &&   // check for opened position 
         OrderSymbol()==Symbol())  // check for symbol
        {
         //--- long position is opened
         if(OrderType()==OP_BUY)
           {
            //--- should it be closed?
            if(iSMA10 < iClose(NULL, 0, 1) || iRSI2 > 100 - ThresholdRSI)
              {
               Profitable = OrderOpenPrice() < Bid;
               //--- close order and exit
               if(Profitable && !OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet))
                  Print("OrderClose error ",GetLastError());
               return;
              }

           }
         else // go to short position
           {
            //--- should it be closed?
            Profitable = OrderOpenPrice() > Ask;
            if(iSMA10 > iClose(NULL, 0, 1) || iRSI2 < 0 + ThresholdRSI)
              {
               //--- close order and exit
               if(Profitable && !OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet))
                  Print("OrderClose error ",GetLastError());
               return;
              }
            //--- check for trailing stop

           }
        }
     }
//---
  }
//+------------------------------------------------------------------+