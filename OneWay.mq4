//+------------------------------------------------------------------+
//|                                                       OneWay.mq4 |
//|                                        Copyright 2015, Neko Prog |
//|                         https://www.mql5.com/en/users/megahentai |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Neko Prog"
#property link      "https://www.mql5.com/en/users/megahentai"
#property version   "1.00"
#property strict

extern string	TradingSettings = "==== Trade Settings ====";
extern double LotExponent = 0.1;
extern double MinLot = 0.01;
extern double MaxLot = 99;
extern double TakeProfit = 100;
extern double LayerAfter = 20;
extern ENUM_TIMEFRAMES TimeFrame = PERIOD_M5;
extern string	StochSettings = "==== Stoch Settings ====";
extern int Kperiod = 9;
extern int Dperiod = 3;
extern int Slowing = 5;
extern string	OtherSettings = "==== Other Settings ====";
extern int OrderMagic = 44342;
extern string	Copyright = "==== \x00A9 2015 Neko Prog ====";

double lots,currLots,stoplevel,orderProfit,totalProfit,lastPrice;
string lastSignal,dispToday;
int totalOrder;
datetime currTime,prevTime;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   //ObjectsDeleteAll(); // clear the chart graphical objects
   //Comment(""); // clear the chart comments
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert core function                                             |
//+------------------------------------------------------------------+
void sendOrder(int orderPos,double orderLot,double orderPrice,double orderSL,double orderTP,color orderColor)
  {
   bool order;
   order = OrderSend(Symbol(),orderPos,orderLot,orderPrice,3,orderSL,orderTP,"OneWay_nEk0_v1",OrderMagic,0,orderColor);
  }

bool newTime()
  {
   currTime=iTime(Symbol(),TimeFrame,0);
   if (prevTime!=currTime)
     {
      prevTime=currTime;
      return true;
     }
   
   else {return false;}
  }

void lotRegulator()
  {
   stoplevel = MarketInfo(Symbol(),MODE_STOPLEVEL);
   lots = NormalizeDouble((AccountEquity()*LotExponent/10000),2);
   if (lots<MinLot) lots = MinLot;
   if (lots>MaxLot) lots = MaxLot;
  }

int countOrder()
  {
   totalOrder = 0;
   for (int i=0; i<OrdersTotal(); i++)
     {                                            
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if (OrderSymbol()!=Symbol()||OrderMagicNumber()!=OrderMagic) continue;
         
          else {totalOrder++;}
        }
     }
   
   return totalOrder;
  }
  
double countProfit()
  {
   totalProfit = 0;
   int tip;
   for (int i=0; i<OrdersTotal(); i++)
     {                                            
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if (OrderSymbol()!=Symbol()||OrderMagicNumber()!=OrderMagic) continue;
         
          else
            {
             tip=OrderType();
             if (tip==0)
               {
                lastSignal = "buy";
                if (lastPrice==0 || OrderOpenPrice()<lastPrice) lastPrice = OrderOpenPrice();
               }
               
             if (tip==1)
               {
                lastSignal = "sell";
                if (lastPrice==0 || OrderOpenPrice()>lastPrice) lastPrice = OrderOpenPrice();
               }
             orderProfit = (OrderProfit()+OrderCommission()+OrderSwap())/OrderLots()/MarketInfo(OrderSymbol(),MODE_TICKVALUE);
             totalProfit = totalProfit+orderProfit;
            }
        }
     }
   
   return NormalizeDouble(totalProfit,0);
  }

string signal()
  {
   double prevMain,prevSignal,currMain,currSignal;
   double prevUpperH1,currUpperH1,prevMidH1,currMidH1,prevLowerH1,currLowerH1;
   double prevUpperH4,currUpperH4,prevMidH4,currMidH4,prevLowerH4,currLowerH4;
   double H1Close,H4Close;
   
   //H1 BB
   H1Close = iClose(Symbol(),PERIOD_H1,1);
   prevUpperH1 = iBands(Symbol(),PERIOD_H1,20,2,0,PRICE_CLOSE,MODE_UPPER,2);
   prevMidH1 = iBands(Symbol(),PERIOD_H1,20,2,0,PRICE_CLOSE,MODE_MAIN,2);
   prevLowerH1 = iBands(Symbol(),PERIOD_H1,20,2,0,PRICE_CLOSE,MODE_LOWER,2);
   currUpperH1 = iBands(Symbol(),PERIOD_H1,20,2,0,PRICE_CLOSE,MODE_UPPER,1);
   currMidH1 = iBands(Symbol(),PERIOD_H1,20,2,0,PRICE_CLOSE,MODE_MAIN,1);
   currLowerH1 = iBands(Symbol(),PERIOD_H1,20,2,0,PRICE_CLOSE,MODE_LOWER,1);
   
   //H4 BB
   H4Close = iClose(Symbol(),PERIOD_H4,1);
   prevUpperH4 = iBands(Symbol(),PERIOD_H4,20,2,0,PRICE_CLOSE,MODE_UPPER,2);
   prevMidH4 = iBands(Symbol(),PERIOD_H4,20,2,0,PRICE_CLOSE,MODE_MAIN,2);
   prevLowerH4 = iBands(Symbol(),PERIOD_H4,20,2,0,PRICE_CLOSE,MODE_LOWER,2);
   currUpperH4 = iBands(Symbol(),PERIOD_H4,20,2,0,PRICE_CLOSE,MODE_UPPER,1);
   currMidH4 = iBands(Symbol(),PERIOD_H4,20,2,0,PRICE_CLOSE,MODE_MAIN,1);
   currLowerH4 = iBands(Symbol(),PERIOD_H4,20,2,0,PRICE_CLOSE,MODE_LOWER,1);
   
   
   prevMain = iStochastic(Symbol(),TimeFrame,Kperiod,Dperiod,Slowing,MODE_SMA,0,MODE_MAIN,2);
   prevSignal = iStochastic(Symbol(),TimeFrame,Kperiod,Dperiod,Slowing,MODE_SMA,0,MODE_SIGNAL,2);
   currMain = iStochastic(Symbol(),TimeFrame,Kperiod,Dperiod,Slowing,MODE_SMA,0,MODE_MAIN,1);
   currSignal = iStochastic(Symbol(),TimeFrame,Kperiod,Dperiod,Slowing,MODE_SMA,0,MODE_SIGNAL,1);
   
   if (//Uptrend, look for buy only
       currUpperH1>prevUpperH1 &&
       currMidH1>prevMidH1 &&
       H1Close>currMidH1 &&
       
       currUpperH4>prevUpperH4 &&
       currMidH4>prevMidH4 &&
       H4Close>currMidH4 &&
       
       //Oversell, Buy signal
       currMain>prevMain &&
       currMain>currSignal &&
       currMain>=20 &&
       currMain<=30
       ) return("buy");
           
   if (//Downtrend, look for sell only
       currLowerH1<prevLowerH1 &&
       currMidH1<prevMidH1 &&
       H1Close<currMidH1 &&
       
       currLowerH4<prevLowerH4 &&
       currMidH4<prevMidH4 &&
       H4Close<currMidH4 &&
       
       //Overbuy, Sell signal
       currMain<prevMain &&
       currMain<currSignal &&
       currMain<=80 &&
       currMain>=70
       ) return("sell");
       
   else {return("no signal");}
  }

void readDay()
  {
   switch(DayOfWeek())
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
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if (Period()==TimeFrame)
     {
      readDay();
      lotRegulator();
      
      // For debug purpose, can be commented out
      Comment("Current Day : ",dispToday,
              "\nBroker Time : ",TimeCurrent(),
              "\nLocal Time : ",TimeLocal(),
              "\nASK : ",NormalizeDouble(Ask,Digits),
              "\nBID : ",NormalizeDouble(Bid,Digits),
              "\nBalance : ",NormalizeDouble(AccountBalance(),2),
              "\nEquity : ",NormalizeDouble(AccountEquity(),2),
              "\nStop Level : ",stoplevel,
              "\nSpread : ",MarketInfo(Symbol(),MODE_SPREAD),
              "\nLots : ",lots,
              "\nTotal Orders : ",countOrder(),
              "\nProfit in Pips : ",countProfit(),
              "\nTime Left : ",TimeToStr(Period()*60+Time[0]-TimeCurrent(),TIME_MINUTES|TIME_SECONDS) );
              
      if (newTime())
        {
         // No order, send order
         if (countOrder()==0)
           {
            lotRegulator();
            currLots = lots;
            if (signal()=="buy")
              {
               RefreshRates();
               sendOrder(OP_BUY,currLots,Ask,0,0,clrBlue);
               lastPrice = Ask;
               lastSignal = "buy";
              }
            
            if (signal()=="sell")
              {
               RefreshRates();
               sendOrder(OP_SELL,currLots,Bid,0,0,clrOrange);
               lastPrice = Bid;
               lastSignal = "sell";
              }
           }
         
         // Have order, layer if price goes away
         if (countOrder()>0 /*&& totalOrder<5*/)
           {
            if (countProfit()<TakeProfit)
              {
               if (lastSignal=="buy" && lastPrice>=Ask+LayerAfter*Point)
                 {
                  RefreshRates();
                  sendOrder(OP_BUY,currLots,Ask,0,0,clrBlue);
                  lastPrice = Ask;
                 }
               
               if (lastSignal=="sell" && lastPrice<=Bid-LayerAfter*Point)
                 {
                  RefreshRates();
                  sendOrder(OP_SELL,currLots,Bid,0,0,clrOrange);
                  lastPrice = Bid;
                 }
              }
           }
        }
        
      // Have order, take profit
      if (countOrder()>0)
        {
         if (countProfit()>=TakeProfit)
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
                     RefreshRates();
                     close = OrderClose(OrderTicket(),OrderLots(),Bid,3,clrGreen); //TP
                     lastPrice = Ask;
                     continue;
                    }
             
                  //Sell 
                  if (tip==1)
                    {
                     RefreshRates();
                     close = OrderClose(OrderTicket(),OrderLots(),Ask,3,clrGreen); //TP
                     lastPrice = Bid;
                     continue;
                    }
                 }
              }
           }
        }
     }
     
   else {Print("Trade run on ",EnumToString(TimeFrame)," timeframe only.");}
  }
//+------------------------------------------------------------------+
