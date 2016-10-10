#include <mt4gui2.mqh>
//+------------------------------------------------------------------+
//|                                                          gui.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int hwnd = 0;
int BuyExposureValueLabel, SellExposureValueLabel, NetExposureValueLabel,
    BuyPositionValueLabel, SellPositionValueLabel, PercentageExposureValueLabel,
    MaxExposureInput, BreakevenValueLabel, PLValueLabel, 
    BalanceValueLabel, EquityValueLabel, MarginValueLabel, FreeMarginValueLabel, MarginLevelValueLabel;

int confirmHeader, confirmPanel;
int NeutralizeButton, yesBtn, noBtn, SaveButton;

double SellExposure, BuyExposure, NetExposure, BuyPosition, SellPosition, PercentageExposure, 
   MaxExposure = GlobalVariableGet("maxExposure"), MaxExposureInLots,
   Breakeven = GlobalVariableGet("breakeven"),
   Profit = GlobalVariableGet("profit"),
   Balance = AccountBalance(), Equity = AccountEquity(), Margin = AccountMargin(), FreeMargin = AccountFreeMargin(), MarginLevel = NormalizeDouble((Equity/Margin)*100, 2);

int XExposure = 200;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   SellExposure = -1;
   BuyExposure = -1;
   NetExposure = -1;
   BuyPosition = -1;
   SellPosition = -1;
   PercentageExposure = -1;
   Breakeven = -1;
   Profit = -1;
   if (MaxExposure != NULL) {
      MaxExposureInLots = (AccountBalance()) * (MaxExposure/100) * 0.001;
   } else {
      MaxExposure = 100;
      MaxExposureInLots = (AccountBalance()) * (MaxExposure/100) * 0.001;
   }
   EventSetTimer(10);
   ObjectsDeleteAll();
   hwnd = WindowHandle(Symbol(),Period());     
   // Lets remove all Objects from Chart before we start
   guiRemoveAll(hwnd);
   // Lets build the Interface
   guiVendor("90AB57A8D63A3C5B53D8660E82537FF0");
   BuildInterface();
   return(0);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Very important to cleanup and remove all gui items from chart      
   if (hwnd>0) { guiRemoveAll(hwnd);     guiCleanup(hwnd ); }
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
bool neutralizeButtonClicked = false;
void OnTick()
  {
//---
   if (guiIsClicked(hwnd,NeutralizeButton) && !neutralizeButtonClicked) {
      if (BuyExposure == SellExposure) {
         Alert("Net Exposure is zero. Already neutralized.");
         return;
      }
      neutralizeButtonClicked = true;
      ShowConfirmWindow();
   }
   
   if (guiIsClicked(hwnd,noBtn) && neutralizeButtonClicked) {
      HideConfirmWindow();
      neutralizeButtonClicked = false;
   }
   
   if (guiIsClicked(hwnd,yesBtn) && neutralizeButtonClicked) {
      //place Order
      Print("place Order");
      int type;
      double volume = NetExposure;
      double bid   =MarketInfo("EURUSD",MODE_BID); // Request for the value of Bid
      double ask   =MarketInfo("EURUSD",MODE_ASK); // Request for the value of Ask
      if (BuyExposure < SellExposure) {
         type = OP_BUY;
      } else {
         type = OP_SELL;
      }
      int ticket=OrderSend("EURUSD",type,NormalizeDouble(volume,2),ask,3,0,0);
      if(ticket<0)
         Print("OrderSend failed with error #",GetLastError());
      else
         Print("OrderSend placed successfully");
      HideConfirmWindow();
      calculateExposure();
      neutralizeButtonClicked = false;
   }
   
   if (guiIsClicked(hwnd,SaveButton)) {
      MaxExposure = StrToDouble(guiGetText(hwnd, MaxExposureInput));
      GlobalVariableSet("maxExposure", MaxExposure);      
      Print(MaxExposure);
      double balance = AccountBalance();
      MaxExposureInLots = (balance) * (MaxExposure/100) * 0.001;
      Print(MaxExposureInLots);
   }
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   calculateExposure();
   calculatePL();
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

void BuildInterface() {
   int ExposureLabel = guiAdd(hwnd,"label",XExposure,5,130,15,"Exposure");     
   guiSetBgColor(hwnd,ExposureLabel,RoyalBlue);
   guiSetTextColor(hwnd,ExposureLabel,White);
   guiSetText(hwnd, ExposureLabel, "Exposure", 12, "Windings");

   int BuyExposureLabel = guiAdd(hwnd,"label",XExposure,20,90,15,"Buy Exposure: ");     
   guiSetBgColor(hwnd,BuyExposureLabel,White);
   guiSetTextColor(hwnd,BuyExposureLabel,Black);
   guiSetText(hwnd, BuyExposureLabel, "Buy Exposure: ", 12, "Windings");
   
   int BuyPositionLabel = guiAdd(hwnd,"label",XExposure,35,90,15,"Buy Avg. Position: ");     
   guiSetBgColor(hwnd,BuyPositionLabel,White);
   guiSetTextColor(hwnd,BuyPositionLabel,Black);
   guiSetText(hwnd, BuyPositionLabel, "Buy Avg. Position: ", 12, "Windings");
   
   int SellExposureLabel = guiAdd(hwnd,"label",XExposure,50,90,15,"Sell Exposure: ");     
   guiSetBgColor(hwnd,SellExposureLabel,White);
   guiSetTextColor(hwnd,SellExposureLabel,Black);
   guiSetText(hwnd, SellExposureLabel, "Sell Exposure: ", 12, "Windings");
   
   int SellPositionLabel = guiAdd(hwnd,"label",XExposure,65,90,15,"Sell Avg. Position: ");     
   guiSetBgColor(hwnd,SellPositionLabel,White);
   guiSetTextColor(hwnd,SellPositionLabel,Black);
   guiSetText(hwnd, SellPositionLabel, "Sell Avg. Position: ", 12, "Windings");
   
   int NetExposureLabel = guiAdd(hwnd,"label",XExposure,80,90,15,"Net Exposure: ");     
   guiSetBgColor(hwnd,NetExposureLabel,White);
   guiSetTextColor(hwnd,NetExposureLabel,Black);
   guiSetText(hwnd, NetExposureLabel, "Net Exposure: ", 12, "Windings");
   
   int PercentageExposureLabel = guiAdd(hwnd,"label",XExposure,95,90,15,"% over balance: ");     
   guiSetBgColor(hwnd,PercentageExposureLabel,White);
   guiSetTextColor(hwnd,PercentageExposureLabel,Black);
   guiSetText(hwnd, PercentageExposureLabel, "% over balance: ", 12, "Windings");
   
   BuyExposureValueLabel = guiAdd(hwnd,"label",XExposure+90,20,40,15,"");     
  guiSetBgColor(hwnd,BuyExposureValueLabel,White);
  guiSetTextColor(hwnd,BuyExposureValueLabel,Black);
   
   BuyPositionValueLabel = guiAdd(hwnd,"label",XExposure+90,35,40,15,"");     
   guiSetBgColor(hwnd,BuyPositionValueLabel,White);
   guiSetTextColor(hwnd,BuyPositionValueLabel,Black);

  SellExposureValueLabel = guiAdd(hwnd,"label",XExposure+90,50,40,15,"");     
  guiSetBgColor(hwnd,SellExposureValueLabel,White);
  guiSetTextColor(hwnd,SellExposureValueLabel,Black);
  
  SellPositionValueLabel = guiAdd(hwnd,"label",XExposure+90,65,40,15,"");     
   guiSetBgColor(hwnd,SellPositionValueLabel,White);
   guiSetTextColor(hwnd,SellPositionValueLabel,Black);
  
  NetExposureValueLabel = guiAdd(hwnd,"label",XExposure+90,80,40,15,"");     
  guiSetBgColor(hwnd,NetExposureValueLabel,White);
  guiSetTextColor(hwnd,NetExposureValueLabel,Black);

   PercentageExposureValueLabel = guiAdd(hwnd,"label",XExposure+90,95,40,15,"");     
  guiSetBgColor(hwnd,PercentageExposureValueLabel,White);
  guiSetTextColor(hwnd,PercentageExposureValueLabel,Black);

  NeutralizeButton = guiAdd(hwnd,"button",XExposure,110,130,15,"Neutralize Position");
  guiSetText(hwnd, NeutralizeButton, "Neutralize Position", 12, "Windings");

  calculateExposure();
  
  int MaxExposureLabel = guiAdd(hwnd,"label",XExposure+275,5,100,15,"Enter Max Exposure");     
   guiSetBgColor(hwnd,MaxExposureLabel,RoyalBlue);
   guiSetTextColor(hwnd,MaxExposureLabel,White);
   guiSetText(hwnd, MaxExposureLabel, "Enter Max Exposure", 12, "Windings");
   
  MaxExposureInput = guiAdd(hwnd,"text",XExposure+275,20,90,15,"");    
   guiSetBgColor(hwnd,MaxExposureInput,White);
   guiSetTextColor(hwnd,MaxExposureInput,Black);
   guiSetText(hwnd, MaxExposureInput, MaxExposure, 12, "Windings");
   
  int MaxExposurePercentageLabel = guiAdd(hwnd,"label",XExposure+365,20,10,15,"%");     
   guiSetBgColor(hwnd,MaxExposurePercentageLabel,White);
   guiSetTextColor(hwnd,MaxExposurePercentageLabel,Black);
   guiSetText(hwnd, MaxExposurePercentageLabel, "%", 12, "Windings");
  
  SaveButton = guiAdd(hwnd,"button",XExposure+275,35,100,15,"Save");
  guiSetText(hwnd, SaveButton, "Save", 12, "Windings");

   int BreakevenLabel = guiAdd(hwnd,"label",XExposure+275,55,100,15,"Breakeven point");     
   guiSetBgColor(hwnd,BreakevenLabel,RoyalBlue);
   guiSetTextColor(hwnd,BreakevenLabel,White);
   guiSetText(hwnd, BreakevenLabel, "Breakeven point", 12, "Windings");

   BreakevenValueLabel = guiAdd(hwnd,"label",XExposure+275,70,100,15,Breakeven);    
   guiSetBgColor(hwnd,BreakevenValueLabel,White);
   guiSetTextColor(hwnd,BreakevenValueLabel,Black);
   guiSetText(hwnd, BreakevenValueLabel, Breakeven, 12, "Windings");
   
   /* Add the PL for the symbol */
   int PL_Label = guiAdd(hwnd,"label",XExposure+275,85,100,15,"PL"); 
   guiSetBgColor(hwnd,PL_Label, RoyalBlue);
   guiSetTextColor(hwnd,PL_Label,White); 
   guiSetText(hwnd, PL_Label, "PL", 12, "Windings");
   
   string SymbolPL = Profit;
   PLValueLabel = guiAdd(hwnd,"label",XExposure+275,100,100,15, SymbolPL);    
   guiSetBgColor(hwnd,PLValueLabel,White);
   guiSetTextColor(hwnd,PLValueLabel,Black);
   guiSetText(hwnd, PLValueLabel, SymbolPL, 12, "Windings");
   
   /* Add the break margin point*/
   int BreakmarginLabel = guiAdd(hwnd,"label", XExposure+275,115,100,15,"Breakmargin pips");     
   guiSetBgColor(hwnd,BreakmarginLabel,RoyalBlue);
   guiSetTextColor(hwnd,BreakmarginLabel,White);
   guiSetText(hwnd, BreakmarginLabel, "Breakmargin point", 12, "Windings");
   
   /* Add the break margin for the symbol */
   double BreakMarginPoint = (Margin - Equity)/(10*NetExposure); 
   
   int BreakmarginValueLabel = guiAdd(hwnd,"label",XExposure+275,130,100,15,"PL"); 
   guiSetBgColor(hwnd,BreakmarginValueLabel, White);
   guiSetTextColor(hwnd,BreakmarginValueLabel,Black); 
   guiSetText(hwnd, BreakmarginValueLabel, NormalizeDouble(BreakMarginPoint,0), 14, "Windings");
   
   /* Add the stop out point */ 
   int StopoutLabel = guiAdd(hwnd,"label",XExposure+275,145,100,15,"Stopout point");     
   guiSetBgColor(hwnd,StopoutLabel,RoyalBlue);
   guiSetTextColor(hwnd,StopoutLabel,White);
   guiSetText(hwnd, StopoutLabel, "Stopout point", 12, "Windings");
   
   double StopoutValuePoint = (Equity - Margin*0.20)/(10*NetExposure);
   
   int StopoutValueLabel = guiAdd(hwnd,"label",XExposure+275,160,100,15,"Stopout point"); 
   guiSetBgColor(hwnd,StopoutValueLabel, White);
   guiSetTextColor(hwnd,StopoutValueLabel,Black); 
   guiSetText(hwnd, StopoutValueLabel, NormalizeDouble(StopoutValuePoint,0), 12, "Windings");
   
   int AccountInfoLabel = guiAdd(hwnd,"label",XExposure+135,5,135,15,"Account");     
   guiSetBgColor(hwnd,AccountInfoLabel,RoyalBlue);
   guiSetTextColor(hwnd,AccountInfoLabel,White);
   guiSetText(hwnd, AccountInfoLabel, "Account", 12, "Windings");
   
   int BalanceLabel = guiAdd(hwnd,"label",XExposure+135,20,65,15,"Balance: ");     
   guiSetBgColor(hwnd,BalanceLabel,White);
   guiSetTextColor(hwnd,BalanceLabel,Black);
   guiSetText(hwnd, BalanceLabel, "Balance: ", 12, "Windings");
   
   int EquityLabel = guiAdd(hwnd,"label",XExposure+135,35,65,15,"Equity: ");     
   guiSetBgColor(hwnd,EquityLabel,White);
   guiSetTextColor(hwnd,EquityLabel,Black);
   guiSetText(hwnd, EquityLabel, "Equity: ", 12, "Windings");
   
   int MarginLabel = guiAdd(hwnd,"label",XExposure+135,50,65,15,"Margin: ");     
   guiSetBgColor(hwnd,MarginLabel,White);
   guiSetTextColor(hwnd,MarginLabel,Black);
   guiSetText(hwnd, MarginLabel, "Margin: ", 12, "Windings");
   
   int FreeMarginLabel = guiAdd(hwnd,"label",XExposure+135,65,65,15,"Free margin: ");     
   guiSetBgColor(hwnd,FreeMarginLabel,White);
   guiSetTextColor(hwnd,FreeMarginLabel,Black);
   guiSetText(hwnd, FreeMarginLabel, "Free margin: ", 12, "Windings");
   
   int MarginLevelLabel = guiAdd(hwnd,"label",XExposure+135,80,65,15,"Margin level: ");     
   guiSetBgColor(hwnd,MarginLevelLabel,White);
   guiSetTextColor(hwnd,MarginLevelLabel,Black);
   guiSetText(hwnd, MarginLevelLabel, "Margin level: ", 12, "Windings");
   
   BalanceValueLabel = guiAdd(hwnd,"label",XExposure+200,20,70,15,Balance + " USD");     
  guiSetBgColor(hwnd,BalanceValueLabel,White);
  guiSetTextColor(hwnd,BalanceValueLabel,Black);
  guiSetText(hwnd, BalanceValueLabel, Balance + " USD", 12, "Windings");
   
   EquityValueLabel = guiAdd(hwnd,"label",XExposure+200,35,70,15,Equity);     
   guiSetBgColor(hwnd,EquityValueLabel,White);
   guiSetTextColor(hwnd,EquityValueLabel,Black);
   guiSetText(hwnd, EquityValueLabel, NormalizeDouble(Equity,2), 12, "Windings");

  MarginValueLabel = guiAdd(hwnd,"label",XExposure+200,50,70,15,Margin);     
  guiSetBgColor(hwnd,MarginValueLabel,White);
  guiSetTextColor(hwnd,MarginValueLabel,Black);
  guiSetText(hwnd, MarginValueLabel, NormalizeDouble(Margin,2), 12, "Windings");
  
  FreeMarginValueLabel = guiAdd(hwnd,"label",XExposure+200,65,70,15,FreeMargin);     
   guiSetBgColor(hwnd,FreeMarginValueLabel,White);
   guiSetTextColor(hwnd,FreeMarginValueLabel,Black);
   guiSetText(hwnd, FreeMarginValueLabel, NormalizeDouble(FreeMargin,2), 12, "Windings");
  
  MarginLevelValueLabel = guiAdd(hwnd,"label",XExposure+200,80,70,15,MarginLevel + "%");     
  guiSetBgColor(hwnd,MarginLevelValueLabel,White);
  guiSetTextColor(hwnd,MarginLevelValueLabel,Black);
  guiSetText(hwnd, MarginLevelValueLabel, NormalizeDouble(MarginLevel,2) + "%", 12, "Windings");
}

void calculatePL() {
   
}

void calculateExposure () {
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

     if (OrderSymbol()!=Symbol()) {
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
  double netExposure = MathAbs(buyExposure - sellExposure);
  double breakeven;
  if (netExposure != 0) { 
   bool type = false; // sellExposure = false; buyExposure = true;
   if (buyExposure > sellExposure) {
      type = true;
   }
   double decimals = 0.1 / Point;
   double pips = MathAbs(profit / (netExposure * 10));
   breakeven = ((type == false && (profit > 0))||(type == true && (profit < 0)))? (Bid + (pips/decimals)) : (Bid - (pips/decimals)); 
    
  }
  
  if (buyExposure != 0) {
    buyPosition = buyPosition/buyExposure; 
  }
  
  if (sellExposure != 0) {
    sellPosition = sellPosition/sellExposure; 
  }
  double balance = AccountBalance();
  double percentageExposure = ((netExposure * 100000) / ((balance) * 100)) * 100;
 
  if (buyExposure != BuyExposure) {
   guiSetText(hwnd, BuyExposureValueLabel, NormalizeDouble(buyExposure,2), 12, "Windings");
   BuyExposure = buyExposure;
  }
  
  if (sellExposure != SellExposure) {
   guiSetText(hwnd, SellExposureValueLabel, NormalizeDouble(sellExposure,2), 12, "Windings");
   SellExposure = sellExposure;
  }

  if (netExposure != NetExposure) {
   guiSetText(hwnd, NetExposureValueLabel, NormalizeDouble(netExposure,2), 12, "Windings");
   NetExposure = netExposure;
  }
  
  if (buyPosition != BuyPosition) {
   guiSetText(hwnd, BuyPositionValueLabel, NormalizeDouble(buyPosition,5), 12, "Windings");
   BuyPosition = buyPosition;
  }
  
  if (sellPosition != SellPosition) {
   guiSetText(hwnd, SellPositionValueLabel, NormalizeDouble(sellPosition,5), 12, "Windings");
   SellPosition = sellPosition;
  }
  
  if (percentageExposure != PercentageExposure) {
   percentageExposure = NormalizeDouble(percentageExposure, 2);
   guiSetText(hwnd, PercentageExposureValueLabel, percentageExposure, 12, "Windings");
   PercentageExposure = percentageExposure;
  }
  
  if (breakeven != Breakeven) {
   Breakeven = NormalizeDouble(breakeven,5);
   guiSetText(hwnd, BreakevenValueLabel, Breakeven, 12, "Windings");
   GlobalVariableSet("breakeven", breakeven);
  }
  
  if (profit != Profit) {
   Profit = NormalizeDouble(profit, 1);
   guiSetText(hwnd, PLValueLabel, Profit, 12, "Windings");
   GlobalVariableSet("profit", profit);
  }
  
  if (balance != Balance) {
   Balance = balance;
   guiSetText(hwnd, BalanceValueLabel, Balance, 12, "Windings");
  }
  
  double equity = AccountEquity();
  if (equity != Equity) {
   Equity = equity;
   guiSetText(hwnd, EquityValueLabel, NormalizeDouble(Equity,2), 12, "Windings");
  }
  
  double margin = AccountMargin();
  if (margin != Margin) {
   Margin = margin;
   guiSetText(hwnd, MarginValueLabel, NormalizeDouble(Margin,2), 12, "Windings");
  }
  
  double freeMargin = AccountFreeMargin();
  if (freeMargin != FreeMargin) {
   FreeMargin = freeMargin;
   guiSetText(hwnd, FreeMarginValueLabel, NormalizeDouble(FreeMargin,2), 12, "Windings");
  }
  
  double marginLevel = NormalizeDouble((equity/margin)*100, 2);
  if (marginLevel != MarginLevel) {
   MarginLevel = marginLevel;
   guiSetText(hwnd, MarginLevelValueLabel, MarginLevel + "%", 12, "Windings");
  }
  
  if (netExposure > MaxExposureInLots) {
   string text = "Maximum Exposure Reached!\nCurrent Exposure: "+NormalizeDouble(netExposure,2)+"\nMax Exposure: "+NormalizeDouble(MaxExposureInLots,2);
   Alert(text);
   sendToSlack("#desk",text);
  }
}

void ShowConfirmWindow () {
   confirmHeader = guiAdd(hwnd,"label",500,180,180,20,"Are you sure?");
   guiSetBgColor(hwnd,confirmHeader,RoyalBlue);
   guiSetTextColor(hwnd,confirmHeader,White);  
   confirmPanel = guiAdd(hwnd,"label",500,200,180,100,"");
   
    yesBtn = guiAdd(hwnd,"button",500+100,180+55,70,40,""); 
    guiSetBorderColor(hwnd,yesBtn,RoyalBlue);
    guiSetBgColor(hwnd,yesBtn, Blue);
    guiSetTextColor(hwnd,yesBtn,White);
    guiSetText(hwnd,yesBtn,"Yes",25,"Arial Bold");
    
    noBtn = guiAdd(hwnd,"button",500+10,180+55,70,40,""); 
    guiSetBorderColor(hwnd,noBtn,OrangeRed);
    guiSetBgColor(hwnd,noBtn, Red);
    guiSetTextColor(hwnd,noBtn,Black);
    guiSetText(hwnd,noBtn,"Cancel",25,"Arial Bold");
}

void HideConfirmWindow () {
   guiRemove(hwnd, confirmHeader);
   guiRemove(hwnd, confirmPanel);
   guiRemove(hwnd, yesBtn);
   guiRemove(hwnd, noBtn);
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