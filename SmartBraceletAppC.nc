#include "SmartBracelet.h"

configuration SmartBraceletAppC {}

implementation {
    /* Components */
    components MainC, SmartBraceletC as App;

    components new AMSenderC(AM_SMART_MSG);
    components new AMReceiverC(AM_SMART_MSG);
    
    components new TimerMilliC() as MilliTimerPair;
    components new TimerMilliC() as MilliTimerMsg;
    components new TimerMilliC() as MilliTimerAlarm;
    
    components ActiveMessageC;
    components new FakeSensorC();

    /* Interfaces */
    App.Boot -> MainC.Boot;

    App.Receive -> AMReceiverC;
    App.AMSend -> AMSenderC;

    App.SplitControl -> ActiveMessageC;

    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.PacketAcknowledgements -> ActiveMessageC;

    App.MilliTimerPair -> MilliTimerPair;
    App.MilliTimerMsg -> MilliTimerMsg;
    App.MilliTimerAlarm -> MilliTimerAlarm;

    App.Read -> FakeSensorC; // to implement
}
