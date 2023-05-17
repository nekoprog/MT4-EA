//+------------------------------------------------------------------+
//|                                                          CBS.mq4 |
//|                                        Copyright 2015, Neko Prog |
//|                         https://www.mql5.com/en/users/megahentai |
//|                                                                  |
//|                   THIS EA IS SHAREWARE                           |
//|           WHICH MEANS THAT IT'S NOT A COMMERCIAL PRODUCT         |
//|                   BUT STILL COPYRIGHTED                          |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Todo                                                             |
//|                                                                  |
//| - sharp entry                                                    |
//| - trend surfing                                                  |
//| - trailing loss / breakeven                                      |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| 2015-08-18 by Capella @ http://worldwide-invest.org/             |
//| Version v.Capella_001                                            |
//| - Fixed OrderDelete error bug                                    |
//| - Fixed compiler warnings                                        |
//| - Changed OrderMagic from global to external                     |
//| 2015-09-14 by Capella @ http://worldwide-invest.org/             |
//| Version v.Capella_2                                              |
//| - Changed StartTime, EndTime and CurrentTime from hours only     |
//|   to hour and minute                                             |
//| - Overruled USA am/pm time format to international 24 hour time  |
//| - Added Trailing StopLoss                                        | 
//+------------------------------------------------------------------+

#property copyright "Copyright 2015, Neko Prog"
#property link      "https://www.mql5.com/en/users/megahentai"
#property version   "1.0"
#property description "Candlestick Breakout Scalper. Trade on candlestick breakout. Still in development stage. \n\n"
#property description "I need these 3 trading strategies in order to complete this EA: \n"
#property description " 1. Sharp entry (upon entry, only small price reversal and hit TP) \n"
#property description " 2. Trend surfing (after entry, it will follow current trend or hit TP) \n"
#property description " 3. Trailing stop (while following current trend, it will also lock profit in case of reversal) \n\n\n\n"
#property description "Any suggestions or comments are welcomed."
#property strict

extern string TradingSettings = "==== Trade Settings ====";
extern double LotExponent = 5;
extern double MinLot = 0.01;
extern double MaxLot = 99;
extern double PendingGap = 0;
extern double TakeProfit = 75;
extern double StopLoss = 50;
extern bool DelPrevPO = false;
extern bool TradeAllCandle = false;
extern int MinCandleVolume = 100;
extern string TimeSettings = "==== Time Settings ====";
extern ENUM_TIMEFRAMES TimeFrame = PERIOD_D1;
extern bool EnableTime = TRUE;
extern int StartHour = 0;
extern int StartMinute = 0;
extern int EndHour = 23;
extern int EndMinute = 00;
extern string TrailSettings = "=== Trail Profit ==="; // Added by Capella
extern bool UseTrailProfit = TRUE; // Trail profit or not
extern double TrailStart = 35; // Points in profit to start trailing StopLoss
extern double TrailGap = 10; // Points distance between current price and new StopLoss
extern double TrailStep = 10;  // Points for a new SL increase before modifying trailing (to avoid unnecessary OrderModify)
extern string OtherSettings = "==== Other Settings ====";
extern int OrderMagic = 44342;   // Changed to extern by Capella
extern string Copyright = "==== \x00A9 2015 Neko Prog ====";

double StartTime, EndTime;
double lots,stoplevel,buystop,sellstop,buytp,selltp,buysl,sellsl;
double orderBuyTP,orderBuySL,orderSellTP,orderSellSL;
double CSPip,prevHigh,prevLow;
double CurrentTime;
int today;
string dispCurrentTime,dispStartTime,dispEndTime,dispToday;
datetime currtime,prevtime;

//+------------------------------------------------------------------+
//| Expert core function                                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Convert from sexagesimal to deciomal
   StartTime = (double) StartHour + (double) StartMinute / 60;
   EndTime = (double) EndHour + (double) EndMinute / 60;
   //Init code block
   currtime=0;
   prevtime=0;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   if (true) ObjectsDeleteAll(); // clear the chart graphical objects
   Comment(""); // clear the chart comments

   return(0);
}

void sendOrder(int orderPos,double orderLot,double orderPrice,double orderSL,double orderTP,color orderColor)
{
   bool sent; // Added by Capella for the use of OrderSend command, see correction below!
//   OrderSend(Symbol(),orderPos,orderLot,orderPrice,3,orderSL,orderTP,"CBS_nEk0",OrderMagic,0,orderColor);  // Commented out by Capella
   sent = OrderSend(Symbol(),orderPos,orderLot,orderPrice,3,orderSL,orderTP,"CBS_nEk0",OrderMagic,0,orderColor);  // Added by Capella
}

void DelAllStop()
{
   bool deleted;  // Added by Capella for the use of OrderDelete command. See correction below!
   int tip;
   for (int i=0; i<OrdersTotal(); i++)
   {                                               
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
      {
         if (OrderSymbol()!=Symbol()||OrderMagicNumber()!=OrderMagic) continue;
         tip=OrderType();
         
         // Buy/Sell Stop
         if (tip==4||tip==5) // OrderDelete(OrderTicket());  // Commented out by Capella
            deleted = OrderDelete(OrderTicket());  // Added by Capella
      }   
   }
}
  
bool newTime()
  {
   currtime=iTime(NULL,TimeFrame,0);
   if (prevtime!=currtime)
     {
      prevtime=currtime;
      return true;
     }
     
   else {return false;}
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
   buystop = NormalizeDouble(prevHigh+PendingGap*Point,Digits);
   sellstop = NormalizeDouble(prevLow-PendingGap*Point,Digits);      
   sendOrder(OP_BUYSTOP,lots,buystop,0,0,clrGreen);
   sendOrder(OP_SELLSTOP,lots,sellstop,0,0,clrRed);
  }
  
void readTime()
{
   // Added hour and minute for current broker server time
   double hour, minute;
   hour = TimeHour ( TimeCurrent() );
   minute = TimeMinute ( TimeCurrent() );   
   CurrentTime = hour + minute / 60;  
   
   // Added International time format
   dispCurrentTime = (string) hour + ":" + (string) minute;
   dispStartTime = (string) StartHour + ":" + (string) StartMinute;
   dispEndTime = (string) EndHour + ":" + (string) EndMinute;
/* Overruled USA time format  
   if (CurrentTime>12) dispCurrentTime=StringConcatenate(DoubleToString(CurrentTime-12)," PM");
   if (CurrentTime<12) dispCurrentTime=StringConcatenate(DoubleToString(CurrentTime)," AM");
   if (CurrentTime==0) dispCurrentTime="12 AM";
  
   if (StartTime>12) dispStartTime=StringConcatenate(IntegerToString(StartTime-12)," PM");
   if (StartTime<12) dispStartTime=StringConcatenate(IntegerToString(StartTime)," AM");
   if (StartTime==0) dispStartTime="12 AM";
  
   if (EndTime>12) dispEndTime=StringConcatenate(IntegerToString(EndTime-12)," PM");
   if (EndTime<12) dispEndTime=StringConcatenate(IntegerToString(EndTime)," AM");
   if (EndTime==0) dispEndTime="12 AM";
*/
  
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
//| Expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
   bool closed; // Added by Capella for ther use of OrderClose, see correction below!
   if (Period() == TimeFrame)
   {
     readTime();
     readDay();
     stoplevel = MarketInfo(Symbol(),MODE_STOPLEVEL);
     lotRegulator();
     
     // For debug purpose, can be commented out
     Comment("Current Day= ",dispToday,
             "\nCurrent Broker Server Time= ",dispCurrentTime,
             "\nBroker Server Start Time= ",dispStartTime,
             "\nBroker Server End Time= ",dispEndTime,
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
     if (OrdersTotal()==1) DelAllStop();
     
     // Check order for possible hit Hidden TP/SL
     if (OrdersTotal() > 0 )
       {
        int tip;
        for (int i=0; i<OrdersTotal(); i++)
         {                                            
          if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
            {
             if (OrderSymbol()!=Symbol()||OrderMagicNumber()!=OrderMagic) continue;
             tip=OrderType();
             
             // Check Trailing - added by Capella
             if ( UseTrailProfit == TRUE )
               CheckTrail ( OrderTicket() );
             
             //Buy
             if (tip==0)
               {
//                DelAllStop();   // Commented out by Capella as it causes OrderDelete errors
                orderBuyTP = NormalizeDouble(OrderOpenPrice()+TakeProfit*Point,Digits);
                orderBuySL = NormalizeDouble(OrderOpenPrice()-StopLoss*Point,Digits);
                
                if (TakeProfit>0 && Bid>=orderBuyTP) // OrderClose(OrderTicket(),OrderLots(),Bid,3,clrBlue); //TP
                  closed = OrderClose(OrderTicket(),OrderLots(),Bid,3,clrBlue); //TP
                if (StopLoss>0 && Bid<=orderBuySL) // OrderClose(OrderTicket(),OrderLots(),Bid,3,clrBlue); //SL
                  closed = OrderClose(OrderTicket(),OrderLots(),Bid,3,clrBlue); //SL
               }
             
             //Sell 
             if (tip==1)
               {
//                DelAllStop();   // Commented out by Capella as it causes OrderDelete errors
                orderSellTP = NormalizeDouble(OrderOpenPrice()-TakeProfit*Point,Digits);
                orderSellSL = NormalizeDouble(OrderOpenPrice()+StopLoss*Point,Digits);
                
                if (TakeProfit>0 && Ask<=orderSellTP) //OrderClose(OrderTicket(),OrderLots(),Ask,3,clrBlue); //TP - Commented out by Capella
                  closed = OrderClose(OrderTicket(),OrderLots(),Ask,3,clrBlue); //TP - Added by Capella
                if (StopLoss>0 && Ask>=orderSellSL) // OrderClose(OrderTicket(),OrderLots(),Ask,3,clrBlue); //SL - Commented out by Capella
                  closed = OrderClose(OrderTicket(),OrderLots(),Ask,3,clrBlue); //SL - Added by Capella
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
           prevHigh = iHigh(NULL,TimeFrame,1);
           prevLow = iLow (NULL,TimeFrame,1);
           CSPip = MathAbs(NormalizeDouble(prevHigh-prevLow,Digits)/Point);
           
           if (EnableTime == true) 
           {           
               if ( CurrentTime >= StartTime && CurrentTime <= EndTime )
               {
                  if (TradeAllCandle==true) theBrainz();
                  if (TradeAllCandle==false && CSPip>=MinCandleVolume) theBrainz();
               }
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

// Trail specific order; check to see if StopLoss cand and should be changed
void CheckTrail( int par_ticket )
{
   double trstart = TrailStart * Point;
   double gap = TrailGap * Point;
   double step = TrailStep * Point;
   double spread = Ask - Bid;
   double openprice = 0;
   double oldSL = 0;
   double newSL = 0;
   bool wasmodified = FALSE;
   
   // If we can select the order that should be trailing
   if ( OrderSelect( par_ticket, SELECT_BY_TICKET, MODE_TRADES ) == TRUE  )
   {
      openprice = OrderOpenPrice();
      oldSL = OrderStopLoss();

   	// Spread is higher than Trailing value, so set Trailing value to spread
      if ( spread > trstart )
         trstart = spread;
   	// If the order does not have any SL yet
      if ( oldSL == 0 )
      {
         // If we have matching order type and symbol
         if ( OrderType() == OP_BUY )
         {
            // Calculate new SL
            newSL = ND ( openprice + trstart );
            // If the current close price is larger than opening price + TrailingStart
            if ( Bid > newSL )
            {          
               // Modify the order with a new SL
               wasmodified = OrderModify( par_ticket, openprice, newSL, 0, 0, Blue );  
               // If the order could not be modified with a new SL then print out an error message          
               if ( wasmodified == FALSE )
                  Print ( "Attempt to trail SL for profitable order# ", par_ticket, " failed! Last error = ", GetLastError(),", OrderType = ", OrderType(),", Bid = ", Bid,", Open price = ", openprice,", OldSL = ", oldSL,", TrailSL = ", newSL );          
            }
         }
         // If we have matching order type
         if ( OrderType() == OP_SELL )
         {
            // Calculate new SL
            newSL = ND ( openprice - trstart );
            // If the current close price is less than the opening price - TrailingStart - TrailingStep
            if ( Ask < newSL )
            {                            
               // Modify the order with a SL
               wasmodified = OrderModify ( par_ticket, openprice, newSL, 0, 0, Blue );
               // If the order could not be modified with a new SL then print out an error message                 
               if ( wasmodified == FALSE )
                  Print ( "Attempt to trail SL for profitable order# ", par_ticket, " failed! Last error = ", GetLastError(),", OrderType = ", OrderType(),", Ask = ", Ask,", Open price = ", openprice,", OldSL = ", oldSL,", TrailSL = ", newSL );          
            }
         }
/*         
         // If the order has been modified with a StopLoss then print message and call sub for deleting matching pending order
         if ( wasmodified > 0 )
         {
            // Print out message that says that the order is now trailing in profit
            Print ( "The order ", string ( par_ticket ), " is trailing SL in profit!" );
         }
*/         
      }
   
   	// The order already has a SL, and a check to see if it can be changed 	
      else
      {
         // If we have matching order type
         if ( OrderType() == OP_BUY )
         {
            // Calculate new SL as current closing price - gap
            newSL = ND ( Bid - gap );
            // If the distance between the new SL and the old SL is more than the trailing step
            if ( ( newSL - oldSL ) > step )
            {
               // Modify the profit order with a new SL that is current close price less trailing, 	
               wasmodified = OrderModify( par_ticket, openprice, newSL, 0, 0, Blue );
               // In case the order couiild not be modified then print out error message
               if ( wasmodified == FALSE )
                  Print ("Modify error. newSl = ", newSL,", oldSl = ", oldSL,", Bid = ", Bid);
            }
         }
         // If we have matching order type and symbol		
         if ( OrderType() == OP_SELL )
         {
            // Calculate a new SL
            newSL = ND ( Ask + gap );
            // If the distance between the new SL and the old SL is more than the trailing step
            if ( ( oldSL - newSL ) > gap )
            {
               // Modify the profit order with a new SL that is current close price plus trailing
               wasmodified = OrderModify( par_ticket, openprice, newSL, 0, 0, Blue );
               // In case the order could not be modified then print out error message
               if ( wasmodified == FALSE )
                  Print ("Modify error. newSl = ", newSL,", oldSl = ", oldSL,", Ask = ", Ask );                  
            }
         }
      }   
   }
}

// Normalize decimals to number of decimals for this currency pair as defined by the broker. Added by Capella
double ND( double par_value )
{
   return ( NormalizeDouble ( par_value, Digits ) );
}