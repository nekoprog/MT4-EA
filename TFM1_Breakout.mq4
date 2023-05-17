//+------------------------------------------------------------------+
//|                                                TFM1_Breakout.mq4 |
//|                                        Copyright 2015, Neko Prog |
//|                         https://www.mql5.com/en/users/megahentai |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Neko Prog"
#property link      "https://www.mql5.com/en/users/megahentai"
#property version   "1.00"
#property description "TFM1 Breakout Scalper."
#property strict

extern string	TradingSettings = "==== Trade Settings ====";
extern double LotPercent = 0.01;
extern double MinLot = 0.01;
extern double MaxLot = 99;
extern double TakeProfit = 100;
extern double StopLoss = 500;
//extern string TimeSettings = "==== Time Settings ====";
ENUM_TIMEFRAMES TimeFrame = PERIOD_M5;
extern string	OtherSettings = "==== Other Settings ====";
extern int OrderMagic = 1502;
extern string	Copyright = "==== \x00A9 2015 Neko Prog ====";

double lot,ASK,BID,Balance,Equity;
double prevHighBBM5,prevLowBBM5,HighBBM5,LowBBM5,BBDiff;
double markHigh,markLow,prevClose;
datetime currtime,prevtime;
//+------------------------------------------------------------------+
//| Expert core function                                             |
//+------------------------------------------------------------------+

void sendOrder(int orderPos,double orderLot,double orderPrice,double orderSL,double orderTP,color orderColor)
  {
   OrderSend(Symbol(),orderPos,orderLot,orderPrice,3,orderSL,orderTP,"TFM1_Breakout",OrderMagic,0,orderColor);
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
  
void drawLine(string objName,color objColor,double objVal)
  {
   ObjectDelete(ChartID(),objName);
   ObjectCreate(objName,OBJ_TREND,0,Time[3],objVal,Time[0],objVal); //todo: draw line from first and last bar of today, along period separator
   ObjectSet(objName,OBJPROP_COLOR,objColor);
   ObjectSet(objName,OBJPROP_WIDTH,2);
   ObjectSetText(objName,string(objVal),10,"Arial",clrBlack);
  }
  
void BB()
  {
   prevHighBBM5 = NormalizeDouble(iBands(Symbol(),PERIOD_M5,20,2,0,PRICE_CLOSE,MODE_UPPER,2),Digits);
   HighBBM5 = NormalizeDouble(iBands(Symbol(),PERIOD_M5,20,2,0,PRICE_CLOSE,MODE_UPPER,1),Digits);
         
   prevLowBBM5 = NormalizeDouble(iBands(Symbol(),PERIOD_M5,20,2,0,PRICE_CLOSE,MODE_LOWER,2),Digits);
   LowBBM5 = NormalizeDouble(iBands(Symbol(),PERIOD_M5,20,2,0,PRICE_CLOSE,MODE_LOWER,1),Digits);
         
   BBDiff = (HighBBM5-LowBBM5)/Point;
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //Init code block
   markHigh = 0;
   markLow = 0;
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
              "\nHigh= ",markHigh,
              "\nLow= ",markLow,
              "\nBBDiff= ",BBDiff,
              "\nLots= ",lot,
              "\nNext Candle= ",TimeToStr(Period()*60+Time[0]-TimeCurrent(),TIME_MINUTES|TIME_SECONDS) );
      
      // Check for breakout
      if (OrdersTotal()==0 && markHigh!=0 && markLow!=0)
        {
         BB();
         prevClose = Close[1];
         if (prevClose>markHigh && BBDiff>100) //Buy
           {
            brokerInfo();
            sendOrder(OP_BUY,lot,ASK,0,0,clrGreen);
            markHigh = 0;
            markLow = 0;
            ObjectsDeleteAll(0,0,OBJ_TREND);
           }
           
         if (prevClose<markLow && BBDiff>100) //Sell
           {
            brokerInfo();
            sendOrder(OP_SELL,lot,BID,0,0,clrRed);
            markHigh = 0;
            markLow = 0;
            ObjectsDeleteAll(0,0,OBJ_TREND);
           }
        }
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
                 double BuyTP,BuySL;
                 BuyTP = NormalizeDouble(OrderOpenPrice()+TakeProfit*Point,Digits);
                 BuySL = NormalizeDouble(OrderOpenPrice()-StopLoss*Point,Digits);
                 
                 brokerInfo();
                 if (TakeProfit>0 && BID>=BuyTP) OrderClose(OrderTicket(),OrderLots(),BID,3,clrBlue); //TP
                 if (StopLoss>0 && BID<=BuySL) OrderClose(OrderTicket(),OrderLots(),BID,3,clrBlue); //SL
                }
              
              //Sell 
              if (tip==1)
                {
                 double SellTP,SellSL;
                 SellTP = NormalizeDouble(OrderOpenPrice()-TakeProfit*Point,Digits);
                 SellSL = NormalizeDouble(OrderOpenPrice()+StopLoss*Point,Digits);
                 
                 brokerInfo();
                 if (TakeProfit>0 && ASK<=SellTP) OrderClose(OrderTicket(),OrderLots(),ASK,3,clrBlue); //TP
                 if (StopLoss>0 && ASK>=SellSL) OrderClose(OrderTicket(),OrderLots(),ASK,3,clrBlue); //SL
                }
             }   
          }
        }
      
      // New CS, mark high low bb
      if (newTime()==true && OrdersTotal()==0 && markHigh==0 && markLow==0)
        {
         BB();
         if (prevHighBBM5==HighBBM5 && BBDiff<100)
          {
           markHigh = HighBBM5;
           markLow = LowBBM5;
           
           drawLine("markHigh",clrRed,markHigh);
           drawLine("markLow",clrRed,markLow);
          }
        }
     }
     
   else { Alert("Trade run on ",EnumToString(TimeFrame)," timeframe only."); } 
   return(0);
  }
//+------------------------------------------------------------------+
