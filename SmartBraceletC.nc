#include "SmartBracelet.h"
#include "Timer.h"

#define PARENT 1    // TOS_NODE_ID
#define CHILD 2     // TOS_NODE_ID

#define PAIR_REQ 0
#define PAIR_RESP 1
#define INFO 2

#define PAIR_PERIOD 250
#define MSG_PERIOD 10000
#define MISSING_ALARM_PERIOD 60000

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
    bool locked = FALSE;
    bool paired = FALSE;
    message_t packet;
    sensor_status_t last;

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

            mess->msg_type = PAIR_REQ;
            strcpy(mess->data, KEY); // TODO: Need to implement the random generation part
            mess->x = 0;
            mess->y = 0;
            
            if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(smart_msg_t))) {
                dbg("Radio", "Broadcast pairing message with key: %s\n", mess->data);
                locked = TRUE;
            }

        }
    }

    event void MilliTimerMsg.fired () { // Transmit INFO
        call Read.read(); // Fake sensor will give back information in 10seconds
    }

    event void MilliTimerAlarm.fired () { // MISSING Alarm
        dbg_clear("ALERT: MISSING! Last known location: (%hhu, %hhu)\n", );
    }

    event void AMSend.sendDone (message_t* buf, error_t err) { // When message is sent!
        if (&packet == buf && err == SUCCESS) {
            locked = FALSE; // free to send again!
        }
        else { // Message was not sent correctly!
            dbgerror("radio_send", "Error! Message was not sent correctly!\n");
            return;
        }
        if (paired == FALSE) { // In pairing mode

        }
        else { // Paired
            if ()
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
 
            if (call AMPacket.destination(buf) == AM_BROADCAST_ADDR && mess->msg_type == PAIR_REQ) { // Pairing message received
                // TODO: Manage randomly generated keys
                if (!strcmp(mess->data, KEY)) { // Parent or child is pairing!
                    if (locked == FALSE) {
                        sender_address = call AMPacket.source(buf);
                        smart_msg_t* mess = (smart_msg_t*) call Packet.getPayload(&packet, sizeof(smart_msg_t));

                        mess->msg_type = PAIR_RESP;
                        strcpy(mess->data, KEY); // TODO: Manage randomly generated keys
                        
                        call PacketAcknowledgements.requestAck(&packet);
                        if (call AMSend.send(sender_address, &packet, sizeof(smart_msg_t)) == SUCCESS) {
                            locked = TRUE;
                        }
                    }
                }
            }
            else if (call AMPacket.destination(buf) == TOS_NODE_ID && mess->msg_type == PAIR_RESP) { // Pairing response received
                paired = TRUE;
                call MilliTimerPair.stop();
                if (TOS_NODE_ID == CHILD) {
                    MilliTimerMsg.startPeriodic(MSG_PERIOD);
                }
            }
            else if (mess->msg_type == INFO) {
                dbg_clear("Node %hhu received info: [%hhu, (%hhu, %hhu)]", TOS_NODE_ID, mess->data, mess->x, mess->y);
                strcpy(last.status, mess->data);
                last.x = mess->x;
                last.y = mess->y;

                call MilliTimerAlarm.startOneShot(MISSING_ALARM_PERIOD);

                if (strcmp(mess->data, 'FALLING') == 0) {
                    dbg_clear("ALERT: FALLING!\n");
                }
            }
        }
        return buf;
    }
    
    event void Read.readDone (error_t result, sensor_status_t sensor_status) {
        smart_msg_t* mess = (smart_msg_t*) (call Packet.getPayload(&packet, sizeof(smart_msg_t)));
        if (mess == NULL) {
            return;
        }
        mess->msg_type = INFO;
        strcpy(mess->data, sensor_status.status);
        mess->x = sensor_status.x;
        mess->y = sensor_status.y;

        call PacketAcknowledgements.requestAck(&packet);
        if (locked == FALSE) {
            if (call AMSend.send(PARENT, &packet, sizeof(smart_msg_t)) == SUCCESS) { // Sent successfully!
                dbg_clear("radio_pack", "Node %hhu sending info [ %hhu, %hhu, %hhu, %hhu]\n", TOS_NODE_ID, mess->msg_type, mess->data, mess->x, mess->y);
                locked = TRUE;
            }
            else { // Failed!
                dbg_clear("radio_pack", "Node %hhu was not able to send the information!\n", TOS_NODE_ID);
            }
        }
    }
}