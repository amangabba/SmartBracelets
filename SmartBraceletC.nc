#include "SmartBracelet.h"
#include "Timer.h"

#define PARENT 1    // TOS_NODE_ID
#define CHILD 2     // TOS_NODE_ID

#define PAIR_REQ 'Pair Request'
#define PAIR_RESP 'Pair Response'
#define OPERATIONAL 'Operational'
#define ALARM 'Alarm'

#define PAIR_PERIOD 250
#define MSG_PERIOD 10000
#define ALARM_PERIOD 60000

#define KEY 'ABCDEFGHIJKLMNOPQRST'

module SmartBraceletC {
    uses {
        interface Boot;

        interface Receive;
        interface AMSend;
        interface Packet;
        interface SplitControl;

        interface Timer<TMilli> as MilliTimerPair;
        interface Timer<TMilli> as MilliTimerMsg;
        interface Timer<TMilli> as MilliTimerAlarm;

        interface PacketAcknowledgements; // not sure if need it

        interface Read<uint16_t>;
    }
} implementation {
    /* Variables initialization */
    bool locked;
    message_t packet;



    event void Boot.booted() {
        dbg("boot", "Application booted on node %u.\n", TOS_NODE_ID);
        call SplitControl.start();
    }

    event void SplitControl.startDone (error_t err) {
        if (err == SUCCESS) { // Radio ON!
            call MilliTimerPair.startPeriodic(PAIR_PERIOD); // Start pairing whether it's node 1 or 2
        }
        else { // Radio OFF! Retrying...
            call SplitControl.start();
        }
    }
    
    event void SplitControl.stopDone (error_t err) {
        // Radio stopped!
    }

    event void MilliTimerPair.fired () { // Used for pairing, stopped once pairing is done!
        if (locked == FALSE) {
            smart_msg_t* mess = (smart_msg_t*) call Packet.getPayload(&packet, sizeof(smart_msg_t));

            mess->msg_type = PAIR;
            // TODO: Need to implement the random generation part
            mess->data = KEY;
            mess->coord_x = 0;
            mess->coord_y = 0;
            
            if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(smart_msg_t))) {
                dbg("Radio", "Broadcast pairing message with key: %s\n", mess->data);
                locked = TRUE;
            }

        }
    }

    event void MilliTimerMsg.fired () { // Timer every 10 seconds

    }

    event void MilliTimerAlarm.fired () { // Timer every minute

    }

    event void AMSend.sendDone (message_t* buf, error_t err) { // When message is sent!
        if (&packet == buf && err == SUCCESS) {
            locked = FALSE; // free to send again!
        }
        else { // Message was not sent correctly!
            dbgerror("radio_send", "Error! Message was not sent correctly!\n");
            return;
        }

        if (call PacketAcknowledgements.wasAcked(&packet)) { // Message was acknowledged!
            if (TOS_NODE_ID == 1) {

            }
            if (TOS_NODE_ID == 2) {

            }
        }
    }

    event message_t* Receive.receive (message_t* buf, void* payload, uint8_t len) { // When message is received
        if (len != sizeof(smart_msg_t)) {
            dbg("radio_pack", "Error! Message was not received correctly!\n");
            return buf;
        }
        else { // Message received correctly!
            smart_msg_t* mess = (smart_msg_t*) payload;
 
            if (call AMPacket.destination(buf) == AM_BROADCAST_ADDR && mess->msg_type == PAIR) { // Pairing message
                // TODO: Manage randomly generated keys
                if (!strcmp(mess->data, KEY)) { // Parent or child is pairing!
                    
                }
            }

        }

    }
    
    event void Read.readDone (error_t result, uint16_t data) {
        smart_msg_t* mess = (smart_msg_t*) (call Packet.getPayload(&packet, sizeof(smart_msg_t)));
        if (mess == NULL) {
            return;
        }
        mess->msg_type = RESP; // Not sure if needed
        mess->data = "";
        mess->x = 0;
        mess->y = 0;

        call PacketAcknowledgements.requestAck(&packet);
        if (call AMSend.send(PARENT, &packet, sizeof(smart_msg_t)) == SUCCESS) { // Sent successfully!
            dbg_clear("radio_pack", "[ %hhu, %hhu, %hhu, %hhu]\n", mess->msg_type, mess->data, mess->x, mess->y);
        }
        else {
            // Failed!
        }

    }



}