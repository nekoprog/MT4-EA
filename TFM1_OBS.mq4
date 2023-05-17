//+------------------------------------------------------------------+
//|                                                     TFM1_OBS.mq4 |
//|                                        Copyright 2015, Neko Prog |
//|                         https://www.mql5.com/en/users/megahentai |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Neko Prog"
#property link      "https://www.mql5.com/en/users/megahentai"
#property version   "1.00"
#property description "TFM1 Stoch Overbuy Oversell Scalper."
#property strict

extern string TradingSettings = "==== Trade Settings ====";
extern double LotPercent = 0.01;
extern double MinLot = 0.01;
extern double MaxLot = 99;
extern double TakeProfit = 100;
extern string MartingaleSettings = "==== Martingale Settings ====";
extern double LotExponent = 2.5;
extern double MartingaleGap = 200;
extern double MartingaleProfit = 300;
//extern string TimeSettings = "==== Time Settings ====";
ENUM_TIMEFRAMES TimeFrame = PERIOD_M5;
extern string OtherSettings = "==== Other Settings ====";
extern int OrderMagic = 1501;
extern string Copyright = "==== \x00A9 2015 Neko Prog ====";

double lot,lastLot,ASK,BID,Balance,Equity;
datetime currtime,prevtime;
double buyTP,sellTP,newLevel;
//+------------------------------------------------------------------+
//| Expert core function                                             |
//+------------------------------------------------------------------+

void sendOrder(int orderPos,double orderLot,double orderPrice,double orderSL,double orderTP,color orderColor)
  {
   OrderSend(Symbol(),orderPos,orderLot,orderPrice,3,orderSL,orderTP,"TFM1_OBS",OrderMagic,0,orderColor);
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
   lot = NormalizeDouble((AccountEquity()*LotPercent/100),2);
   if (lot<MinLot) lot = MinLot;
   if (lot>MaxLot) lot = MaxLot;
  }
  
void brokerInfo()
  {
   RefreshRates();
   ASK = NormalizeDouble(Ask,Digits);
   BID = NormalizeDouble(Bid,Digits);
   Balance = NormalizeDouble(AccountBalance(),2);
   Equity = NormalizeDouble(AccountEquity(),2);
  }
  
string signal()
  {
   double prevMainM1,prevSignalM1,MainM1,SignalM1,prevMainM5,prevSignalM5,MainM5,SignalM5,prevMainM15,prevSignalM15,MainM15,SignalM15;
   
   prevMainM1 = iStochastic(Symbol(),PERIOD_M1,9,3,5,MODE_SMA,0,MODE_MAIN,2);
   prevMainM5 = iStochastic(Symbol(),PERIOD_M5,9,3,5,MODE_SMA,0,MODE_MAIN,2);
   prevMainM15 = iStochastic(Symbol(),PERIOD_M15,9,3,5,MODE_SMA,0,MODE_MAIN,2);
   
   prevSignalM1 = iStochastic(Symbol(),PERIOD_M1,9,3,5,MODE_SMA,0,MODE_SIGNAL,2);
   prevSignalM5 = iStochastic(Symbol(),PERIOD_M5,9,3,5,MODE_SMA,0,MODE_SIGNAL,2);
   prevSignalM15 = iStochastic(Symbol(),PERIOD_M15,9,3,5,MODE_SMA,0,MODE_SIGNAL,2);
   
   MainM1 = iStochastic(Symbol(),PERIOD_M1,9,3,5,MODE_SMA,0,MODE_MAIN,1);
   MainM5 = iStochastic(Symbol(),PERIOD_M5,9,3,5,MODE_SMA,0,MODE_MAIN,1);
   MainM15 = iStochastic(Symbol(),PERIOD_M15,9,3,5,MODE_SMA,0,MODE_MAIN,1);
   
   SignalM1 = iStochastic(Symbol(),PERIOD_M1,9,3,5,MODE_SMA,0,MODE_SIGNAL,1);
   SignalM5 = iStochastic(Symbol(),PERIOD_M5,9,3,5,MODE_SMA,0,MODE_SIGNAL,1);
   SignalM15 = iStochastic(Symbol(),PERIOD_M15,9,3,5,MODE_SMA,0,MODE_SIGNAL,1);
   
   //Oversell, Buy signal
   if (//prevMainM1<20 &&
       prevMainM5<20 &&
       //prevMainM15<20 &&
       
       //prevSignalM1<20 &&
       //prevSignalM5<20 &&
       //prevSignalM15<20 &&
       
       //MainM1<20 &&
       //MainM5<20 &&
       //MainM15<20 &&
       
       //SignalM1<20 &&
       //SignalM5<20 &&
       //SignalM15<20 &&
       
       //prevMainM1<MainM1 &&
       //prevMainM5<MainM5 &&
       //prevMainM15<MainM15 &&
       
       //prevSignalM1<SignalM1 &&
       //prevSignalM5<SignalM5 &&
       //prevSignalM15<SignalM15 &&
       
       //prevMainM5>prevSignalM5 &&
       
       //MainM1>SignalM1 &&
       MainM5>SignalM5 //&&
       //MainM15>SignalM15
       ) return("buy");
       
   //Overbuy, Sell signal    
   if (//prevMainM1>80 &&
       prevMainM5>80 &&
       //prevMainM15>80 &&
       
       //prevSignalM1>80 &&
       //prevSignalM5>80 &&
       //prevSignalM15>80 &&
       
       //MainM1>80 &&
       //MainM5>80 &&
       //MainM15>80 &&
       
       //SignalM1>80 &&
       //SignalM5>80 &&
       //SignalM15>80 &&
       
       //prevMainM1>MainM1 &&
       //prevMainM5>MainM5 &&
       //prevMainM15>MainM15 &&
       
       //prevSignalM1>SignalM1 &&
       //prevSignalM5>SignalM5 &&
       //prevSignalM15>SignalM15 &&
       
       //prevMainM5<prevSignalM5 &&
       
       //MainM1<SignalM1 &&
       MainM5<SignalM5 //&&
       //MainM15<SignalM15
       ) return("sell");
       
   else {return("no signal");}
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //Init code block
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
   if (Period()==TimeFrame)
     {
      lotRegulator();
      brokerInfo();
      
      // For debug purpose, can be commented out
      Comment("ASK= ",ASK,
              "\nBID= ",BID,
              "\nBalance= ",Balance,
              "\nEquity= ",Equity,
              "\nLots= ",lot,
              "\nNext Candle= ",TimeToStr(Period()*60+Time[0]-TimeCurrent(),TIME_MINUTES|TIME_SECONDS) );
      
      // Check order for possible hit Hidden TP/SL
      if (OrdersTotal()>0)
        {
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
                 brokerInfo();
                 if (TakeProfit>0 && BID>=buyTP) OrderClose(OrderTicket(),OrderLots(),BID,3,clrBlue); //TP
                 if (MartingaleGap>0 && BID<=newLevel) //Martingale
                   {
                    lastLot = lastLot+(lastLot/LotExponent);
                    sendOrder(OP_BUY,lastLot,ASK,0,0,clrGreen);
                    buyTP = NormalizeDouble(ASK+MartingaleProfit*Point,Digits);
                    newLevel = NormalizeDouble(ASK-MartingaleGap*Point,Digits);
                   }
                }
              
              //Sell 
              if (tip==1)
                {
                 brokerInfo();
                 if (TakeProfit>0 && ASK<=sellTP) OrderClose(OrderTicket(),OrderLots(),ASK,3,clrBlue); //TP
                 if (MartingaleGap>0 && ASK>=newLevel) //Martingale
                   {
                    lastLot = lastLot+(lastLot/LotExponent);
                    sendOrder(OP_SELL,lastLot,BID,0,0,clrRed);
                    sellTP = NormalizeDouble(BID-MartingaleProfit*Point,Digits);
                    newLevel = NormalizeDouble(BID+MartingaleGap*Point,Digits);
                   }
                }
             }   
          }
        }
      
      // New CS, send order if no order yet
      if (newTime()==true && OrdersTotal()==0)
        {
         double HighBBM5,LowBBM5,prevClose;
   
         prevClose = Close[1];
         HighBBM5 = iBands(Symbol(),PERIOD_M5,20,2,0,PRICE_CLOSE,MODE_UPPER,1);
         LowBBM5 = iBands(Symbol(),PERIOD_M5,20,2,0,PRICE_CLOSE,MODE_LOWER,1);
         
         if (prevClose<LowBBM5 && signal()=="buy")
           {
            brokerInfo();
            lastLot = lot;
            buyTP = NormalizeDouble(ASK+TakeProfit*Point,Digits);
            newLevel = NormalizeDouble(ASK-MartingaleGap*Point,Digits);
            sendOrder(OP_BUY,lot,ASK,0,0,clrGreen);
           }
         
         if (prevClose>HighBBM5 && signal()=="sell")
           {
            brokerInfo();
            lastLot = lot;
            sellTP = NormalizeDouble(BID-TakeProfit*Point,Digits);
            newLevel = NormalizeDouble(BID+MartingaleGap*Point,Digits);
            sendOrder(OP_SELL,lot,BID,0,0,clrRed);
           }
        }
     }
   
   else { Alert("Trade run on ",EnumToString(TimeFrame)," timeframe only."); } 
   return(0);
  }
//+------------------------------------------------------------------+
