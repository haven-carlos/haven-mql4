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
    MaxExposureInput;

int confirmHeader, confirmPanel;
int NeutralizeButton, yesBtn, noBtn, SaveButton;

double SellExposure, BuyExposure, NetExposure, BuyPosition, SellPosition, PercentageExposure, 
   MaxExposure = GlobalVariableGet("maxExposure"), MaxExposureInLots;

int XExposure = 220;
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
   if (MaxExposure != NULL) {
      MaxExposureInLots = AccountBalance() * (MaxExposure/100) * 0.001;
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
      double balance = AccountBalance();
      MaxExposureInLots = balance * (MaxExposure/100) * 0.001;
   }
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   calculateExposure();
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
   int ExposureLabel = guiAdd(hwnd,"label",XExposure,5,200,25,"Exposure");     
   guiSetBgColor(hwnd,ExposureLabel,RoyalBlue);
   guiSetTextColor(hwnd,ExposureLabel,White);

   int BuyExposureLabel = guiAdd(hwnd,"label",XExposure,30,150,25,"Buy Exposure: ");     
   guiSetBgColor(hwnd,BuyExposureLabel,White);
   guiSetTextColor(hwnd,BuyExposureLabel,Black);
   
   int BuyPositionLabel = guiAdd(hwnd,"label",XExposure,55,150,25,"Buy Avg. Position: ");     
   guiSetBgColor(hwnd,BuyPositionLabel,White);
   guiSetTextColor(hwnd,BuyPositionLabel,Black);
   
   int SellExposureLabel = guiAdd(hwnd,"label",XExposure,80,150,25,"Sell Exposure: ");     
   guiSetBgColor(hwnd,SellExposureLabel,White);
   guiSetTextColor(hwnd,SellExposureLabel,Black);
   
   int SellPositionLabel = guiAdd(hwnd,"label",XExposure,105,150,25,"Sell Avg. Position: ");     
   guiSetBgColor(hwnd,SellPositionLabel,White);
   guiSetTextColor(hwnd,SellPositionLabel,Black);
   
   int NetExposureLabel = guiAdd(hwnd,"label",XExposure,130,150,25,"Net Exposure: ");     
   guiSetBgColor(hwnd,NetExposureLabel,White);
   guiSetTextColor(hwnd,NetExposureLabel,Black);
   
   int PercentageExposureLabel = guiAdd(hwnd,"label",XExposure,155,150,25,"% over balance: ");     
   guiSetBgColor(hwnd,PercentageExposureLabel,White);
   guiSetTextColor(hwnd,PercentageExposureLabel,Black);
   
   BuyExposureValueLabel = guiAdd(hwnd,"label",XExposure+150,30,50,25,"");     
  guiSetBgColor(hwnd,BuyExposureValueLabel,White);
  guiSetTextColor(hwnd,BuyExposureValueLabel,Black);
   
   BuyPositionValueLabel = guiAdd(hwnd,"label",XExposure+150,55,50,25,"");     
   guiSetBgColor(hwnd,BuyPositionValueLabel,White);
   guiSetTextColor(hwnd,BuyPositionValueLabel,Black);

  SellExposureValueLabel = guiAdd(hwnd,"label",XExposure+150,80,50,25,"");     
  guiSetBgColor(hwnd,SellExposureValueLabel,White);
  guiSetTextColor(hwnd,SellExposureValueLabel,Black);
  
  SellPositionValueLabel = guiAdd(hwnd,"label",XExposure+150,105,50,25,"");     
   guiSetBgColor(hwnd,SellPositionValueLabel,White);
   guiSetTextColor(hwnd,SellPositionValueLabel,Black);
  
  NetExposureValueLabel = guiAdd(hwnd,"label",XExposure+150,130,50,25,"");     
  guiSetBgColor(hwnd,NetExposureValueLabel,White);
  guiSetTextColor(hwnd,NetExposureValueLabel,Black);

   PercentageExposureValueLabel = guiAdd(hwnd,"label",XExposure+150,155,50,25,"");     
  guiSetBgColor(hwnd,PercentageExposureValueLabel,White);
  guiSetTextColor(hwnd,PercentageExposureValueLabel,Black);

  NeutralizeButton = guiAdd(hwnd,"button",XExposure,180,200,25,"Neutralize Position");

  calculateExposure();
  
  int MaxExposureLabel = guiAdd(hwnd,"label",XExposure+203,5,200,25,"Enter Max Exposure");     
   guiSetBgColor(hwnd,MaxExposureLabel,RoyalBlue);
   guiSetTextColor(hwnd,MaxExposureLabel,White);
   
  MaxExposureInput = guiAdd(hwnd,"text",XExposure+203,30,180,25,"");    
   guiSetBgColor(hwnd,MaxExposureInput,White);
   guiSetTextColor(hwnd,MaxExposureInput,Black);
   guiSetText(hwnd, MaxExposureInput, MaxExposure, 16, "Windings");
   
  int MaxExposurePercentageLabel = guiAdd(hwnd,"label",XExposure+383,30,20,25,"%");     
   guiSetBgColor(hwnd,MaxExposurePercentageLabel,White);
   guiSetTextColor(hwnd,MaxExposurePercentageLabel,Black);
  
  SaveButton = guiAdd(hwnd,"button",XExposure+203,55,200,25,"Save"); 
}

void calculateExposure () {
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
  double netExposure = MathAbs(buyExposure - sellExposure);
  if (buyExposure != 0) {
    buyPosition = buyPosition/buyExposure; 
  }
  
  if (sellExposure != 0) {
    sellPosition = sellPosition/sellExposure; 
  }
  double balance = AccountBalance();
  double percentageExposure = (netExposure * 100000) / (balance * 100);
  if (buyExposure != BuyExposure) {
   guiSetText(hwnd, BuyExposureValueLabel, NormalizeDouble(buyExposure,2), 16, "Windings");
   BuyExposure = buyExposure;
  }
  
  if (sellExposure != SellExposure) {
   guiSetText(hwnd, SellExposureValueLabel, NormalizeDouble(sellExposure,2), 16, "Windings");
   SellExposure = sellExposure;
  }

  if (netExposure != NetExposure) {
   guiSetText(hwnd, NetExposureValueLabel, NormalizeDouble(netExposure,2), 16, "Windings");
   NetExposure = netExposure;
  }
  
  if (buyPosition != BuyPosition) {
   guiSetText(hwnd, BuyPositionValueLabel, NormalizeDouble(buyPosition,5), 16, "Windings");
   BuyPosition = buyPosition;
  }
  
  if (sellPosition != SellPosition) {
   guiSetText(hwnd, SellPositionValueLabel, NormalizeDouble(sellPosition,5), 16, "Windings");
   SellPosition = sellPosition;
  }
  
  if (percentageExposure != PercentageExposure) {
   guiSetText(hwnd, PercentageExposureValueLabel, NormalizeDouble(percentageExposure*100,2), 16, "Windings");
   PercentageExposure = percentageExposure;
  }
  
  if (netExposure > MaxExposureInLots) {
   string text = "Maximum Exposure Reached!\nCurrent Exposure: "+NormalizeDouble(netExposure,2)+"\nMax Exposure: "+NormalizeDouble(MaxExposureInLots,2);
   Alert(text);
   sendToSlack("#forex-desk",text);
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