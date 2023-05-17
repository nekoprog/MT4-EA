//+------------------------------------------------------------------+
//|                                                    EA Sadaqa.mq4 |
//|                                Copyright 2021, Faiz Petani Sugeh |
//|                                        https://fx.petanisugeh.my |
//|                                                                  |
//|                   THIS EA IS COMMERCIAL PRODUCT                  |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright     "Copyright 2021, Faiz Petani Sugeh"
#property link          "https://fx.petanisugeh.my"
#property version       "1.8"
#property description   "EA Sadaqa: MYR50 For 1 Year Subscription"
#property description   "\n\nRegistered for: 420186820"
#property description   "\nValid until: 05 April 2022"
#property strict

extern string  TradingSettings = "==== Trade Settings ====";
extern double LotSize = 0.01;
extern string  Copyright = "==== \x00A9 2021 Faiz Petani Sugeh ====";

//debug only, please delete
int StartTime = 0;
int EndTime = 23;

string relVersion = "1.8";
int OrderMagic = 44342;
datetime accRegDate=D'2021.04.05 00:00'; // User Register Date
int accId = 420186820; // User Account Number
double lastCheck,newCheck,curWO,curWP,prevWH,prevWL,prevWC; // Weekly candle
double buyTP,buySL,sellTP,sellSL,lots,stoplevel,ASK,BID,Balance,Equity; // Price

int CurrentTime,today,prevDay;
string dispCurrentTime,dispStartTime,dispEndTime,dispToday;
datetime currtime,prevtime,checkExpiry;

//+------------------------------------------------------------------+
//| Expert core function                                             |
//+------------------------------------------------------------------+
void sendOrder(int orderPos,double orderLot,double orderPrice,double orderSL,double orderTP,color orderColor) {
   bool order;
   while(IsTradeContextBusy()) Sleep(100);
   RefreshRates();
   order = OrderSend(Symbol(),orderPos,orderLot,orderPrice,3,orderSL,orderTP,"EA Sadaqa v"+relVersion+" | "+IntegerToString(accId),OrderMagic,0,orderColor);
   return;
  }

//+------------------------------------------------------------------+
//| Close all                                                        |
//+------------------------------------------------------------------+
void DelAllOrder(string objType) {
   bool deleteOrder;
   int tip;
   for(int i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderMagicNumber()!=OrderMagic || OrderSymbol()!=Symbol())
            continue;
         tip=OrderType();

         if (objType=="all") {
            // Buy
            if(tip==0)
               deleteOrder = OrderClose(OrderTicket(),OrderLots(),Bid,3);
         
            // Sell
            if(tip==1)
               deleteOrder = OrderClose(OrderTicket(),OrderLots(),Ask,3);
         }
            
         // Buy/Sell Pending
         if(tip==2||tip==3)
            deleteOrder = OrderDelete(OrderTicket());
      }
   }
   return;
}

//+------------------------------------------------------------------+
//| Weekly Pivot                                                     |
//+------------------------------------------------------------------+
void weeklyPivot() {
   prevWH = NormalizeDouble(iHigh(Symbol(),PERIOD_W1,1),Digits);
   prevWL = NormalizeDouble(iLow(Symbol(),PERIOD_W1,1),Digits);
   prevWC = NormalizeDouble(iClose(Symbol(),PERIOD_W1,1),Digits);
   curWP = NormalizeDouble((prevWH+prevWL+prevWC)/3,Digits);
   curWO = NormalizeDouble(iOpen(Symbol(),PERIOD_W1,0),Digits);
   }

//+------------------------------------------------------------------+
//| Draw   Pivot                                                     |
//+------------------------------------------------------------------+
void drawLine(string objName,color objColor,double objVal) {
   ObjectDelete(ChartID(),objName);
   ObjectCreate(objName,OBJ_HLINE,0,Time[0],objVal);
   ObjectSet(objName,OBJPROP_COLOR,objColor);
   ObjectSet(objName,OBJPROP_WIDTH,2);
   ObjectSetText(objName,string(objVal),10,"Arial",clrBlack);
   }

//+------------------------------------------------------------------+
//| Make Money $$$                                                   |
//+------------------------------------------------------------------+
void lotRegulator() {
   stoplevel = MarketInfo(Symbol(),MODE_STOPLEVEL);
   lots = NormalizeDouble(LotSize,2);
}

void theBrainz() {
   printf("Refresh Target");
   weeklyPivot();
   printf("Draw Target");
   drawLine("HLine",clrRed,curWP);
   
   if (curWO>curWP) {
      buyTP = NormalizeDouble(curWP+1000*Point,Digits);
      buySL = NormalizeDouble(curWP-500*Point,Digits);
      printf("lot: "+DoubleToStr(lots,2)+"| buy limit: "+DoubleToStr(curWP,3)+"| TP: "+DoubleToStr(buyTP,3)+"| SL: "+DoubleToStr(buySL,3));
      sendOrder(OP_BUYLIMIT,lots,curWP,buySL,buyTP,clrGreen);
      return;
   }
   
   if (curWO<curWP) {
      sellTP = NormalizeDouble(curWP-1000*Point,Digits);
      sellSL = NormalizeDouble(curWP+500*Point,Digits);
      printf("lot: "+DoubleToStr(lots,2)+"| sell limit: "+DoubleToStr(curWP,3)+"| TP: "+DoubleToStr(sellTP,3)+"| SL: "+DoubleToStr(sellSL,3));
      sendOrder(OP_SELLLIMIT,lots,curWP,sellSL,sellTP,clrRed);
      return;
   }
}

//+------------------------------------------------------------------+
//| Time                                                             |
//+------------------------------------------------------------------+
bool newTime()
  {
   currtime=iTime(Symbol(),PERIOD_CURRENT,0);
   if (prevtime!=currtime)
     {
      prevtime=currtime;
      return true;
     }
     
   else {return false;}
  }

void readTime()
  {
   CurrentTime = TimeHour(TimeCurrent());
   if(CurrentTime>12)
      dispCurrentTime=StringConcatenate(IntegerToString(CurrentTime-12)," PM");
   if(CurrentTime<12)
      dispCurrentTime=StringConcatenate(IntegerToString(CurrentTime)," AM");
   if(CurrentTime==0)
      dispCurrentTime="12 AM";

   if(StartTime>12)
      dispStartTime=StringConcatenate(IntegerToString(StartTime-12)," PM");
   if(StartTime<12)
      dispStartTime=StringConcatenate(IntegerToString(StartTime)," AM");
   if(StartTime==0)
      dispStartTime="12 AM";

   if(EndTime>12)
      dispEndTime=StringConcatenate(IntegerToString(EndTime-12)," PM");
   if(EndTime<12)
      dispEndTime=StringConcatenate(IntegerToString(EndTime)," AM");
   if(EndTime==0)
      dispEndTime="12 AM";
  }

//+------------------------------------------------------------------+
//| Day                                                              |
//+------------------------------------------------------------------+
void readDay()
  {
   today = DayOfWeek();
   switch(today)
     {
      case 0:
         dispToday="Sunday";
         break;
      case 1:
         dispToday="Monday";
         break;
      case 2:
         dispToday="Tuesday";
         break;
      case 3:
         dispToday="Wednesday";
         break;
      case 4:
         dispToday="Thursday";
         break;
      case 5:
         dispToday="Friday";
         break;
      case 6:
         dispToday="Saturday";
         break;
     }
  }

//+------------------------------------------------------------------+
//| Broker Info                                                      |
//+------------------------------------------------------------------+
void brokerInfo() {
   RefreshRates();
   ASK = NormalizeDouble(Ask,Digits);
   BID = NormalizeDouble(Bid,Digits);
   Balance = NormalizeDouble(AccountBalance(),2);
   Equity = NormalizeDouble(AccountEquity(),2);
   }
  
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//Init code block
   lastCheck=0;
   newCheck=0;
   currtime=0;
   prevtime=0;
   prevDay=0;
   today=0;
   checkExpiry=365*24*60*60; // 1 year = days * hour * minutes * seconds
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit() {
   ObjectsDeleteAll(); // clear the chart graphical objects
   Comment(""); // clear the chart comments
   
   return(0);
}
//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
void OnTick() {
   if ((AccountInfoInteger(ACCOUNT_LOGIN)==accId && TimeCurrent()<=accRegDate+checkExpiry && newTime()==true) || IsTesting()==true) {
      readTime();
      readDay();
      lotRegulator();
      newCheck=DayOfYear();

      // For debug purpose, can be commented out
      /*Comment("Current Day= ",dispToday,
              "\nTrue Day= ",DayOfWeek(),
              "\nCurrent Time= ",dispCurrentTime,
              "\nTrue Time= ",TimeHour(TimeCurrent()),
              "\nRegister date= ",accRegDate,
              "\nExpiry= ",accRegDate+checkExpiry,
              "\nCurrent Date= ",TimeCurrent(),
              "\nStart Time= ",dispStartTime,
              "\nEnd Time= ",dispEndTime,
              "\nASK= ",NormalizeDouble(Ask,Digits),
              "\nBID= ",NormalizeDouble(Bid,Digits),
              "\nBalance= ",NormalizeDouble(AccountBalance(),Digits),
              "\nEquity= ",NormalizeDouble(AccountEquity(),Digits),
              "\nStop Level= ",NormalizeDouble(stoplevel,Digits),
              "\nBuy TP= ",buySL,
              "\nBuy SL= ",buySL,
              "\nSell TP= ",sellTP,
              "\nSell SL= ",sellSL,
              "\nLots= ",lots,
              "\nTarget= ",curWP,
              "\nTime Left= ",TimeToStr(Period()*60+Time[0]-TimeCurrent(),TIME_MINUTES|TIME_SECONDS));*/

      if (DayOfWeek()==1 && TimeHour(TimeCurrent())<=7) { // 3am server = 8am MY
         if (lastCheck==0) {
            DelAllOrder("pending");
            lastCheck=newCheck;
            theBrainz();
         }
         
         if (lastCheck!=0 && newCheck==lastCheck+7) {
            lastCheck=newCheck;
            theBrainz();
         }  
      }
      
      if (DayOfWeek()==5 && TimeHour(TimeCurrent())>=6) { // 6am server = 11am MY
         DelAllOrder("all");
      }
   }
   
   if (IsTesting()==false) {
      if (AccountInfoInteger(ACCOUNT_LOGIN)!=accId) {
         Alert("Not authorized, contact reseller for registration");
      }
      
      else {
         if (TimeCurrent()>accRegDate+checkExpiry) {
            Alert("Registration expired, contact reseller to renew");
         }
      }
   }

   return;
}
//+------------------------------------------------------------------+
