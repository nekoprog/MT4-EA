//+------------------------------------------------------------------+
//|                                                     TFM1_MACD.mq4 |
//|                                        Copyright 2015, Neko Prog |
//|                         https://www.mql5.com/en/users/megahentai |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Neko Prog"
#property link      "https://www.mql5.com/en/users/megahentai"
#property version   "1.00"
#property description "TFM1 MACD Crosses Scalper."
#property strict

extern string TradingSettings = "==== Trade Settings ====";
extern double LotPercent = 0.01;
extern double MinLot = 0.01;
extern double MaxLot = 99;
extern double TakeProfit = 100;
extern double StopLoss = 250;
//extern string TimeSettings = "==== Time Settings ====";
ENUM_TIMEFRAMES TimeFrame = PERIOD_M5;
extern string OtherSettings = "==== Other Settings ====";
extern int OrderMagic = 1503;
extern string Copyright = "==== \x00A9 2015 Neko Prog ====";

double lot,lastLot,ASK,BID,SPREAD,Balance,Equity;
datetime currtime,prevtime;
double buyTP,buySL,sellTP,sellSL;
//+------------------------------------------------------------------+
//| Expert core function                                             |
//+------------------------------------------------------------------+

void sendOrder(int orderPos,double orderLot,double orderPrice,double orderSL,double orderTP,color orderColor)
  {
   bool order;
   order = OrderSend(Symbol(),orderPos,orderLot,orderPrice,3,orderSL,orderTP,"TFM1_MACD",OrderMagic,0,orderColor);
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
   SPREAD = NormalizeDouble(MarketInfo(Symbol(),MODE_SPREAD),Digits);
   Balance = NormalizeDouble(AccountBalance(),2);
   Equity = NormalizeDouble(AccountEquity(),2);
  }
  
string signal()
  {
   double prevMain,prevSig,currMain,currSig,prevClose,currClose,ema20;
   
   ema20 = iMA(Symbol(),PERIOD_M5,20,0,MODE_EMA,PRICE_CLOSE,1);
   prevClose = iClose(Symbol(),PERIOD_M5,2);
   currClose = iClose(Symbol(),PERIOD_M5,1);
   prevMain = iMACD(Symbol(),PERIOD_M5,35,45,25,PRICE_CLOSE,MODE_MAIN,2);
   prevSig = iMACD(Symbol(),PERIOD_M5,35,45,25,PRICE_CLOSE,MODE_SIGNAL,2);
   currMain = iMACD(Symbol(),PERIOD_M5,35,45,25,PRICE_CLOSE,MODE_MAIN,1);
   currSig = iMACD(Symbol(),PERIOD_M5,35,45,25,PRICE_CLOSE,MODE_SIGNAL,1);
   
   //Upward crosses level -0.0003, Buy signal
   if (prevClose<currClose && currClose>ema20 && prevSig<currSig && prevSig<-0.0003 && currSig>-0.0003) return("buy");
       
   //Downward crosses level 0.0003, Sell signal    
   if (prevClose>currClose && currClose<ema20 && prevSig>currSig && prevSig>0.0003 && currSig<0.0003) return("sell");
   
   if (currSig>currMain) return("cutbuy");
   if (currSig<currMain) return("cutsell");
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
                 brokerInfo();
                 if (signal()=="cutbuy") close = OrderClose(OrderTicket(),OrderLots(),BID,3,clrBlue); //Cut Loss
                 if (TakeProfit>0 && BID>=buyTP) close = OrderClose(OrderTicket(),OrderLots(),BID,3,clrBlue); //TP
                 if (StopLoss>0 && BID<=buySL) close = OrderClose(OrderTicket(),OrderLots(),BID,3,clrBlue); //SL
                }
              
              //Sell 
              if (tip==1)
                {
                 brokerInfo();
                 if (signal()=="cutsell") close = OrderClose(OrderTicket(),OrderLots(),ASK,3,clrBlue); //Cut Loss
                 if (TakeProfit>0 && ASK<=sellTP) close = OrderClose(OrderTicket(),OrderLots(),ASK,3,clrBlue); //TP
                 if (StopLoss>0 && ASK>=sellSL) close = OrderClose(OrderTicket(),OrderLots(),ASK,3,clrBlue); //SL
                }
             }   
          }
        }
      
      // New CS, send order if no order yet
      if (newTime()==true && OrdersTotal()==0)
        {
         if (signal()=="buy")
           {
            brokerInfo();
            sendOrder(OP_BUY,lot,ASK,0,0,clrGreen);
            buyTP = NormalizeDouble(ASK+TakeProfit*Point,Digits);
            buySL = NormalizeDouble(ASK-StopLoss*Point,Digits);
           }
         
         if (signal()=="sell")
           {
            brokerInfo();
            sendOrder(OP_SELL,lot,BID,0,0,clrRed);
            sellTP = NormalizeDouble(BID-TakeProfit*Point,Digits);
            sellSL = NormalizeDouble(BID+StopLoss*Point,Digits);
           }
        }
     }
   
   else { Alert("Trade run on ",EnumToString(TimeFrame)," timeframe only."); } 
   return(0);
  }
//+------------------------------------------------------------------+
