//+------------------------------------------------------------------+
//|                                                          CBS.mq4 |
//|                                        Copyright 2015, Neko Prog |
//|                         https://www.mql5.com/en/users/megahentai |
//|                                                                  |
//|                   THIS EA IS SHAREWARE                           |
//|           WHICH MEANS THAT IT'S NOT A COMMERCIAL PRODUCT         |
//|                   BUT STILL COPYRIGHTED                          |
//+------------------------------------------------------------------+

/********
 * Todo *
 ******** 
 * sharp entry
 * trend surfing
 * trailing loss/breakeven
 * open trade after current D1 cs complete
 *
 */

/*************
 * CHANGELOG *
 *************
 * Ver 1.1
 * -Repair all warnings
 * -Add boolean toggle for delete PO after one of it is triggered
 * -Compare previous high/low with current Ask/Bid to prevent Error 130 invalid stop
 *
 * Ver 1.0
 * -Initial release
 *
 */
 
#property copyright "Copyright 2015, Neko Prog"
#property link      "https://www.mql5.com/en/users/megahentai"
#property version   "1.1"
#property description "Candlestick Breakout Scalper. Trade on candlestick breakout. Still in development stage. \n\n"
#property description "I need these 3 trading strategies in order to complete this EA: \n"
#property description " 1. Sharp entry (upon entry, only small price reversal and hit TP) \n"
#property description " 2. Trend surfing (after entry, it will follow current trend or hit TP) \n"
#property description " 3. Trailing stop (while following current trend, it will also lock profit in case of reversal) \n\n\n\n"
#property description "Any suggestions or comments are welcomed."
#property strict

extern string	TradingSettings = "==== Trade Settings ====";
extern double LotExponent = 5;
extern double MinLot = 0.01;
extern double MaxLot = 99;
extern double PendingGap = 0;
extern double TakeProfit = 100;
extern double StopLoss = 500;
extern bool DelPrevPO = true;
extern bool TradeAllCandle = true;
extern int MinCandleVolume = 100;
extern string TimeSettings = "==== Time Settings ====";
extern ENUM_TIMEFRAMES TimeFrame = PERIOD_D1;
extern bool EnableTime = false;
extern int StartTime = 0;
extern int EndTime = 23;
extern string	OtherSettings = "==== Other Settings ====";
input int OrderMagic = 44342;
extern string	Copyright = "==== \x00A9 2015 Neko Prog ====";

double lots,stoplevel,buystop,sellstop,buytp,selltp,buysl,sellsl;
double orderBuyTP,orderBuySL,orderSellTP,orderSellSL;
double CSPip,prevHigh,prevLow;
int CurrentTime,today,prevDay;
string dispCurrentTime,dispStartTime,dispEndTime,dispToday;
datetime currtime,prevtime;
bool delPO;

//+------------------------------------------------------------------+
//| Expert core function                                             |
//+------------------------------------------------------------------+
void sendOrder(int orderPos,double orderLot,double orderPrice,double orderSL,double orderTP,color orderColor)
  {
   bool order;
   order = OrderSend(Symbol(),orderPos,orderLot,orderPrice,3,orderSL,orderTP,"CBS_nEk0_v1.1",OrderMagic,0,orderColor);
  }

void DelAllStop()
  {
   delPO = false;
   bool deleteOrder;
   int tip;
   for (int i=0; i<OrdersTotal(); i++)
     {                                               
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if (OrderSymbol()!=Symbol()||OrderMagicNumber()!=OrderMagic) continue;
         tip=OrderType();
         
         // Buy/Sell Stop
         if (tip==4||tip==5) deleteOrder = OrderDelete(OrderTicket());
        }   
     }
  }
  
bool newTime()
  {
   if (TimeFrame==PERIOD_D1)
     {
      readDay();
      if (prevDay!=today)
        {
         prevDay=today;
         return true;
        }
        
      else {return false;}
     }
   
   else
     {
      currtime=iTime(Symbol(),TimeFrame,0);
      if (prevtime!=currtime)
        {
         prevtime=currtime;
         return true;
        }
      
      else {return false;}
     }
   
  }

void lotRegulator()
  {
   lots = NormalizeDouble((AccountEquity()*LotExponent/10000),2);
   if (lots<MinLot) lots = MinLot;
   if (lots>MaxLot) lots = MaxLot;
  }

void theBrainz()
  {
   if (PendingGap==0) PendingGap = stoplevel;
   if (NormalizeDouble(prevHigh+PendingGap*Point,Digits)>NormalizeDouble(Ask+PendingGap*Point,Digits)) buystop = NormalizeDouble(prevHigh+PendingGap*Point,Digits);
   if (NormalizeDouble(prevHigh+PendingGap*Point,Digits)<NormalizeDouble(Ask+PendingGap*Point,Digits)) buystop = NormalizeDouble(Ask+PendingGap*Point,Digits);
   if (NormalizeDouble(prevLow-PendingGap*Point,Digits)<NormalizeDouble(Bid-PendingGap*Point,Digits)) sellstop = NormalizeDouble(prevLow-PendingGap*Point,Digits);
   if (NormalizeDouble(prevLow-PendingGap*Point,Digits)>NormalizeDouble(Bid-PendingGap*Point,Digits)) sellstop = NormalizeDouble(Bid-PendingGap*Point,Digits);
   sendOrder(OP_BUYSTOP,lots,buystop,0,0,clrGreen);
   sendOrder(OP_SELLSTOP,lots,sellstop,0,0,clrRed);
  }
  
void readTime()
  {
   CurrentTime = TimeHour(TimeCurrent());
   if (CurrentTime>12) dispCurrentTime=StringConcatenate(IntegerToString(CurrentTime-12)," PM");
   if (CurrentTime<12) dispCurrentTime=StringConcatenate(IntegerToString(CurrentTime)," AM");
   if (CurrentTime==0) dispCurrentTime="12 AM";
  
   if (StartTime>12) dispStartTime=StringConcatenate(IntegerToString(StartTime-12)," PM");
   if (StartTime<12) dispStartTime=StringConcatenate(IntegerToString(StartTime)," AM");
   if (StartTime==0) dispStartTime="12 AM";
  
   if (EndTime>12) dispEndTime=StringConcatenate(IntegerToString(EndTime-12)," PM");
   if (EndTime<12) dispEndTime=StringConcatenate(IntegerToString(EndTime)," AM");
   if (EndTime==0) dispEndTime="12 AM";
  }

void readDay()
  {
   today = DayOfWeek();
   switch(today)
     {
      case 0: dispToday="Sunday";      break;
      case 1: dispToday="Monday";      break;
      case 2: dispToday="Tuesday";     break;
      case 3: dispToday="Wednesday";   break;
      case 4: dispToday="Thursday";    break;
      case 5: dispToday="Friday";      break;
      case 6: dispToday="Saturday";    break;
     }
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //Init code block
   currtime=0;
   prevtime=0;
   prevDay=0;
   today=0;
   delPO=false;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   ObjectsDeleteAll(); // clear the chart graphical objects
   Comment(""); // clear the chart comments

   return(0);
  }
//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   if (Period()==TimeFrame)
    {
     readTime();
     readDay();
     stoplevel = MarketInfo(Symbol(),MODE_STOPLEVEL);
     lotRegulator();
     
     // For debug purpose, can be commented out
     Comment("Current Day= ",dispToday,
             "\nCurrent Time= ",dispCurrentTime,
             "\nStart Time= ",dispStartTime,
             "\nEnd Time= ",dispEndTime,
             "\nASK= ",NormalizeDouble(Ask,Digits),
             "\nBID= ",NormalizeDouble(Bid,Digits),
             "\nBalance= ",NormalizeDouble(AccountBalance(),Digits),
             "\nEquity= ",NormalizeDouble(AccountEquity(),Digits),
             "\nStop Level= ",NormalizeDouble(stoplevel,Digits),
             "\nBuy TP= ",orderBuyTP,
             "\nBuy SL= ",orderBuySL,
             "\nSell TP= ",orderSellTP,
             "\nSell SL= ",orderSellSL,
             "\nLots= ",lots,
             "\nTime Left= ",TimeToStr(Period()*60+Time[0]-TimeCurrent(),TIME_MINUTES|TIME_SECONDS) );
     
     // Check stale order, delete untriggered Stop Order
     if (OrdersTotal()==1 || delPO==true) DelAllStop();
     
     // Check order for possible hit Hidden TP/SL
     if (OrdersTotal()>0)
       {
        bool close;
        int tip;
        for (int i=0; i<OrdersTotal(); i++)
         {                                            
          if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
            {
             if (OrderSymbol()!=Symbol()||OrderMagicNumber()!=OrderMagic) continue;
             tip=OrderType();
             
             //Buy
             if (tip==0)
               {
                delPO = true;
                orderBuyTP = NormalizeDouble(OrderOpenPrice()+TakeProfit*Point,Digits);
                orderBuySL = NormalizeDouble(OrderOpenPrice()-StopLoss*Point,Digits);
                
                if (TakeProfit>0 && Bid>=orderBuyTP) close = OrderClose(OrderTicket(),OrderLots(),Bid,3,clrBlue); //TP
                if (StopLoss>0 && Bid<=orderBuySL) close = OrderClose(OrderTicket(),OrderLots(),Bid,3,clrBlue); //SL
               }
             
             //Sell 
             if (tip==1)
               {
                delPO = true;
                orderSellTP = NormalizeDouble(OrderOpenPrice()-TakeProfit*Point,Digits);
                orderSellSL = NormalizeDouble(OrderOpenPrice()+StopLoss*Point,Digits);
                
                if (TakeProfit>0 && Ask<=orderSellTP) close = OrderClose(OrderTicket(),OrderLots(),Ask,3,clrBlue); //TP
                if (StopLoss>0 && Ask>=orderSellSL) close = OrderClose(OrderTicket(),OrderLots(),Ask,3,clrBlue); //SL
               }
            }   
         }
       }
      
     // Send order per candle
     if (newTime()==true)
       {
        // Delete all untriggered Pending Orders
        if (DelPrevPO==true) DelAllStop();
        
        // Start trade if no order
        if (OrdersTotal()==0)
          {
           prevHigh = iHigh(Symbol(),TimeFrame,1);
           prevLow = iLow (Symbol(),TimeFrame,1);
           CSPip = MathAbs(NormalizeDouble(prevHigh-prevLow,Digits)/Point);
           
           if (EnableTime==true && CurrentTime>=StartTime && CurrentTime<=EndTime)
             {
              if (TradeAllCandle==true) theBrainz();
              if (TradeAllCandle==false && CSPip>=MinCandleVolume) theBrainz();
             }
             
           if (EnableTime==false)
             {
              if (TradeAllCandle==true) theBrainz();
              if (TradeAllCandle==false && CSPip>=MinCandleVolume) theBrainz();
             }
          }
       }
     }
     
   else { Alert("Trade run on ",EnumToString(TimeFrame)," timeframe only."); } 
   return(0);
  }
//+------------------------------------------------------------------+
