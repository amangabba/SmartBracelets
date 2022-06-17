#include "SmartBracelet.h"

configuration SmartBraceletAppC {}

implementation {
    /* Components */
    components MainC, SmartBraceletC as App;

    components new AMSenderC(AM_SMART_MSG);
    components new AMReceiver(AM_SMART_MSG);
    components new TimerMilliC();
    components ActiveMessageC;
    components new FakeSensorC();

    /* Interfaces */
    App.Boot -> MainC.Boot;

    App.Receive -> AMReceiverC;
    App.AMSend -> AMSenderC;

    App.SplitControl -> ActiveMessageC;

    App.Packet -> AMSenderC;
    App.PacketAcknowledgements -> ActiveMessageC;

    App.MilliTimer -> TimerMilliC;

    App.Read -> FakeSensorC; // to implement
}