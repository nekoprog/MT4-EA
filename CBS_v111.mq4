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
 * Ver 1.11
 * -Replace pending orders with direct order based on candle close beyond marker with Stoch overbuy and oversell to filter out false signal
 * -Add Marking and Trading time to make ea even more dynamic to be used as London Breakout or so
 * -Add options for user to chose how many previous candles to use as marker
 * -Add options for user to use previous high low or previous close as marker
 *
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
#property version   "1.11"
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
extern double PendingGap = 10;
extern double TakeProfit = 75;
extern double StopLoss = 50;
extern bool DeletePreviousMarker = true;
extern bool TradeAllCandle = true;
extern int MinCandleVolume = 100;
extern string TimeSettings = "==== Time Settings ====";
extern ENUM_TIMEFRAMES MarkerTF = PERIOD_H1;
extern bool EnableMarkerTime = false;
extern int MarkerStartHour = 0;
extern int MarkerStartMinute = 0;
extern int MarkerEndHour = 23;
extern int MarkerEndMinute = 00;
extern bool MarkHiLo = false;
extern int MarkerShift = 1;
extern ENUM_TIMEFRAMES TradeTF = PERIOD_M5;
extern bool EnableTradeTime = false;
extern int TradeStartHour = 0;
extern int TradeStartMinute = 0;
extern int TradeEndHour = 23;
extern int TradeEndMinute = 0;
extern string TrailSettings = "=== Trail Profit ==="; // Added by Capella
extern bool UseTrailProfit = TRUE; // Trail profit or not
extern double TrailStart = 35; // Points in profit to start trailing StopLoss
extern double TrailGap = 10; // Points distance between current price and new StopLoss
extern double TrailStep = 10;  // Points for a new SL increase before modifying trailing (to avoid unnecessary OrderModify)
extern string OtherSettings = "==== Other Settings ====";
extern int OrderMagic = 44342;   // Changed to extern by Capella
extern string	Copyright = "==== \x00A9 2015 Neko Prog ====";

double lots,stoplevel;
double orderBuyTP,orderBuySL,orderSellTP,orderSellSL;
double csVolume,prevHigh,prevLow,prevClose;
double markClose,markHigh,markLow;
int highIndex,lowIndex;
double BrokerTime,LocalTime/*,CurrentTime*/;
double MarkerStartTime,MarkerEndTime,TradeStartTime,TradeEndTime;
int today,prevDay;
string dispBrokerTime,dispLocalTime,dispStartTime,dispEndTime,dispToday;
datetime currTime,prevTime;
string signal;
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
   bool deleted;  // Added by Capella for the use of OrderDelete command. See correction below!
   int tip;
   for (int i=0; i<OrdersTotal(); i++)
     {                                               
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if (OrderSymbol()!=Symbol()||OrderMagicNumber()!=OrderMagic) continue;
         tip=OrderType();
         
         // Buy/Sell Stop
         if (tip==4||tip==5) deleted = OrderDelete(OrderTicket());  // Added by Capella
        }   
     }
  }

void newTrade(string todo)
  {
   double prevSignal,prevMain,currSignal,currMain;
   prevSignal = iStochastic(Symbol(),TradeTF,9,3,5,MODE_SMA,0,MODE_SIGNAL,2);
   prevMain = iStochastic(Symbol(),TradeTF,9,3,5,MODE_SMA,0,MODE_MAIN,2);
   currSignal = iStochastic(Symbol(),TradeTF,9,3,5,MODE_SMA,0,MODE_SIGNAL,1);
   currMain = iStochastic(Symbol(),TradeTF,9,3,5,MODE_SMA,0,MODE_MAIN,1);
   
   if (todo=="buy" && prevMain<=20 && currMain>20 && currMain>currSignal)
     {
      RefreshRates();
      sendOrder(OP_BUY,lots,Ask,0,0,clrBlue);
     }
     
   if (todo=="sell" && prevMain>=80 && currMain<80 && currMain<currSignal)
     {
      RefreshRates();
      sendOrder(OP_SELL,lots,Bid,0,0,clrOrange);
     }
  }

bool newTime()
  {
   bool allowTrade = MarketInfo(Symbol(), MODE_TRADEALLOWED);
   if (MarkerTF==PERIOD_D1)
     {
      readTime();
      readDay();
      if (/*allowTrade==true &&*/ prevDay!=today)
        {
         prevDay = today;
         return true;
        }
        
      else {return false;}
     }
   
   else
     {
      currTime=iTime(Symbol(),MarkerTF,0);
      if (/*allowTrade==true &&*/ prevTime!=currTime)
        {
         prevTime=currTime;
         return true;
        }
        
      else {return false;}
     }
  }

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
               //wasmodified = OrderModify( par_ticket, openprice, newSL, 0, 0, Blue );  
               orderBuySL = newSL;
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
               //wasmodified = OrderModify ( par_ticket, openprice, newSL, 0, 0, Blue );
               orderSellSL = newSL;
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
               //wasmodified = OrderModify( par_ticket, openprice, newSL, 0, 0, Blue );
               orderBuySL = newSL;
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
               //wasmodified = OrderModify( par_ticket, openprice, newSL, 0, 0, Blue );
               orderSellSL = newSL;
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

void lotRegulator()
  {
   lots = NormalizeDouble((AccountEquity()*LotExponent/10000),2);
   if (lots<MinLot) lots = MinLot;
   if (lots>MaxLot) lots = MaxLot;
  }

void theMarker()
  {
   if (MarkHiLo==false)
     {
      markClose = iClose(Symbol(),MarkerTF,1);
      markHigh = NormalizeDouble(markClose+PendingGap*Point,Digits);
      markLow = NormalizeDouble(markClose-PendingGap*Point,Digits);
     }
     
   if (MarkHiLo==true)
     {
      highIndex = iHighest(Symbol(),MarkerTF,MODE_HIGH,MarkerShift,1);
      lowIndex = iLowest(Symbol(),MarkerTF,MODE_LOW,MarkerShift,1);
      markHigh = NormalizeDouble(iHigh(Symbol(),MarkerTF,highIndex)+PendingGap*Point,Digits);
      markLow = NormalizeDouble(iLow(Symbol(),MarkerTF,lowIndex)-PendingGap*Point,Digits);
     }
  }

void resetMarker()
 {
  markClose = 0;
  markHigh = 0;
  markLow = 0;
  orderBuyTP = 0;
  orderBuySL = 0;
  orderSellTP = 0;
  orderSellSL = 0;
 }

void drawLine(string objName,color objColor,double objVal)
  {
   ObjectDelete(ChartID(),objName);
   ObjectCreate(objName,OBJ_TREND,0,iTime(Symbol(),MarkerTF,MarkerShift),objVal,Time[0],objVal);
   ObjectSet(objName,OBJPROP_COLOR,objColor);
   ObjectSet(objName,OBJPROP_WIDTH,2);
   ObjectSetText(objName,string(objVal),10,"Arial",clrBlack);
  }

void readTime()
  {
   // Added hour and minute for current broker server time
   double brokerHour,brokerMinute,localHour,localMinute;
   brokerHour = TimeHour(TimeCurrent());
   brokerMinute = TimeMinute(TimeCurrent());   
   BrokerTime = brokerHour+brokerMinute/60;  
   
   localHour = TimeHour(TimeLocal());
   localMinute = TimeMinute(TimeLocal());
   LocalTime = localHour+localMinute/60;
   
   // Added International time format
   dispBrokerTime = (string) brokerHour + ":" + (string) brokerMinute;
   dispLocalTime = (string) localHour + ":" + (string) localMinute;
   //dispStartTime = (string) StartHour + ":" + (string) StartMinute;
   //dispEndTime = (string) EndHour + ":" + (string) EndMinute;
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
   // Convert from sexagesimal to deciomal
   MarkerStartTime = (double) MarkerStartHour + (double) MarkerStartMinute / 60;
   MarkerEndTime = (double) MarkerEndHour + (double) MarkerEndMinute / 60;
   
   TradeStartTime = (double) TradeStartHour + (double) TradeStartMinute / 60;
   TradeEndTime = (double) TradeEndHour + (double) TradeEndMinute / 60;
   
   //Init code block
   currTime = 0;
   prevTime = 0;
   prevDay = 0;
   today = 0;
   markHigh = 0;
   markLow = 0;
   delPO = false;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   //ObjectsDeleteAll(); // clear the chart graphical objects
   //Comment(""); // clear the chart comments
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   if (Period()==TradeTF)
     {
      readTime();
      readDay();
      //stoplevel = MarketInfo(Symbol(),MODE_STOPLEVEL);
      stoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD);
      stoplevel = NormalizeDouble(stoplevel*Point,Digits);
      lotRegulator();
      
      // For debug purpose, can be commented out
      Comment("Current Day= ",dispToday,
              "\nBroker Time= ",dispBrokerTime,
              "\nLocal Time= ",dispLocalTime,
              //"\nStart Time= ",dispStartTime,
              //"\nEnd Time= ",dispEndTime,
              "\nASK= ",NormalizeDouble(Ask,Digits),
              "\nBID= ",NormalizeDouble(Bid,Digits),
              "\nBalance= ",NormalizeDouble(AccountBalance(),2),
              "\nEquity= ",NormalizeDouble(AccountEquity(),2),
              "\nStop Level= ",stoplevel,
              "\nHigh Marker= ",markHigh,
              "\nBuy TP= ",orderBuyTP,
              "\nBuy SL= ",orderBuySL,
              "\nLow Marker= ",markLow,
              "\nSell TP= ",orderSellTP,
              "\nSell SL= ",orderSellSL,
              "\nLots= ",lots,
              "\nTime Left= ",TimeToStr(Period()*60+Time[0]-TimeCurrent(),TIME_MINUTES|TIME_SECONDS) );
      
      // Start marking high and low
      if (newTime()==true)
        {
         // Reset untriggered markers
         if (DeletePreviousMarker==true)
           {
            if (EnableMarkerTime==true && LocalTime>=MarkerStartTime && LocalTime<=MarkerEndTime) resetMarker();
            if (EnableMarkerTime==false) resetMarker();
           }
         
         // Create marker only if markHigh and markLow is 0
         if (OrdersTotal()==0 && markHigh==0 && markLow==0)
           {
            prevHigh = NormalizeDouble(iHigh(Symbol(),TradeTF,1),Digits);
            prevLow = NormalizeDouble(iLow(Symbol(),TradeTF,1),Digits);
            csVolume = MathAbs(NormalizeDouble(prevHigh-prevLow,Digits)/Point);
            
            if (EnableMarkerTime==true && LocalTime>=MarkerStartTime && LocalTime<=MarkerEndTime)
              {
               if (TradeAllCandle==true) theMarker();
               if (TradeAllCandle==false && csVolume>=MinCandleVolume) theMarker();
              }
              
            if (EnableMarkerTime==false)
              {
               if (TradeAllCandle==true) theMarker();
               if (TradeAllCandle==false && csVolume>=MinCandleVolume) theMarker();
              }
            
            //drawLine("markHigh",clrRed,markHigh);
            //drawLine("markLow",clrRed,markLow);
            sendOrder(OP_BUYSTOP,lots,markHigh+stoplevel,0,0,clrBlue);
            sendOrder(OP_SELLSTOP,lots,markLow-stoplevel,0,0,clrOrange);
            print("PO Buy",markHigh+stoplevel);
            print("PO Sell",markLow-stoplevel);
           }
        }
      
//      // Check whether latest completed candle has break beyond markers
//      if (OrdersTotal()==0 && markHigh!=0 && markLow!=0)
//        {
//         prevClose = NormalizeDouble(iClose(Symbol(),TradeTF,1),Digits);
//         
//         if (EnableTradeTime==true && LocalTime>=TradeStartTime && LocalTime<=TradeEndTime)
//           {
//            if (prevClose>=markHigh) newTrade("buy");
//            if (prevClose<=markLow) newTrade("sell");
//           }
//         
//         if (EnableTradeTime==false)
//           {
//            if (prevClose>=markHigh) newTrade("buy");
//            if (prevClose<=markLow) newTrade("sell");
//           }
//        }
      
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
               
               // Check Trailing - added by Capella
               if (UseTrailProfit==true)
                 CheckTrail(OrderTicket());
               
               //Buy
               if (tip==0)
                 {
                  delPO = true;
                  if (orderBuyTP==0) orderBuyTP = NormalizeDouble(OrderOpenPrice()+TakeProfit*Point,Digits);
                  if (orderBuySL==0) orderBuySL = NormalizeDouble(OrderOpenPrice()-StopLoss*Point,Digits);
                  
                  if (TakeProfit>0 && Bid>=orderBuyTP)
                    {
                     close = OrderClose(OrderTicket(),OrderLots(),Bid,3,clrGreen); //TP
                     resetMarker();
                    }
                    
                  if (StopLoss>0 && Bid<=orderBuySL)
                    {
                     close = OrderClose(OrderTicket(),OrderLots(),Bid,3,clrRed); //SL
                     resetMarker();
                    }
                 }
               
               //Sell 
               if (tip==1)
                 {
                  delPO = true;
                  if (orderSellTP==0) orderSellTP = NormalizeDouble(OrderOpenPrice()-TakeProfit*Point,Digits);
                  if (orderSellSL==0) orderSellSL = NormalizeDouble(OrderOpenPrice()+StopLoss*Point,Digits);
                  
                  if (TakeProfit>0 && Ask<=orderSellTP)
                    {
                     close = OrderClose(OrderTicket(),OrderLots(),Ask,3,clrGreen); //TP
                     resetMarker();
                    }
                    
                  if (StopLoss>0 && Ask>=orderSellSL)
                    {
                     close = OrderClose(OrderTicket(),OrderLots(),Ask,3,clrRed); //SL
                     resetMarker();
                    }
                 }
              }   
           }
        }
         
       //Delete remaining untriggered pending order
       if (OrdersTotal()==1 && delPO==true) DelAllStop();
     }
     
   else { Alert("Trade run on ",EnumToString(TradeTF)," timeframe only."); } 
   return(0);
  }
//+------------------------------------------------------------------+
