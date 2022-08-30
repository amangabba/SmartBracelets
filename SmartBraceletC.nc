#include "SmartBracelet.h"
#include "Timer.h"

#define PARENT 1    // TOS_NODE_ID
#define CHILD 2     // TOS_NODE_ID

#define PAIR_PERIOD 3000
#define MSG_PERIOD 10000
#define MISSING_ALARM_PERIOD 60000


module SmartBraceletC {
    uses {
        interface Boot;

        interface Receive;
        interface AMSend;
        interface Packet;
        interface AMPacket;
        interface SplitControl;

        interface Timer<TMilli> as MilliTimerPair;
        interface Timer<TMilli> as MilliTimerMsg;
        interface Timer<TMilli> as MilliTimerAlarm;

        interface PacketAcknowledgements; // not sure if need it

        interface Read<sensor_status_t>;
    }
} implementation {

    /* Variables initialization */
    bool locked = FALSE;
    bool paired = FALSE;
    message_t packet;
    sensor_status_t last;
    uint16_t sender_address;
    uint8_t key[2][20] = {	{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    						{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    						{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    						{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}};
    uint8_t j;

    event void Boot.booted() {
        dbg("boot", "[%s]Application booted on node %u.\n",sim_time_string(), TOS_NODE_ID);
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
    	// dbg("radio", "Pairing on Node %u!\n", TOS_NODE_ID);
        if (locked == FALSE) {
            pair_msg_t* mess = (pair_msg_t*) call Packet.getPayload(&packet, sizeof(pair_msg_t));

            mess->msg_type = PAIR_REQ;
            mess->address = TOS_NODE_ID;
            
            for (j=0; j<20; j++) {
            	mess->key[j] = key[(TOS_NODE_ID-1)/2][j];
            }
            // mess->key = key[TOS_NODE_ID / 2]; // TODO: Need to implement the random generation part
            
            if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(pair_msg_t)) == SUCCESS) {
                dbg("radio", "[%s | PAIRING] Broadcast pairing message with key:", sim_time_string());
                for (j=0; j<20; j++) {
            		dbg_clear("radio", "%u", mess->key[j]);
            	}
            	dbg_clear("radio", "\n");
                locked = TRUE;
            }

        }
    }

    event void MilliTimerMsg.fired () { // Transmit INFO
        call Read.read(); // Fake sensor will give back information in 10seconds
    }

    event void MilliTimerAlarm.fired () { // MISSING Alarm
        // dbg("radio", "ALERT: MISSING! Last known location: \n");
        dbg("radio", "[%s | ALERT > MISSING] Last known location received from child [x: %hhu, y: %hhu, ", sim_time_string(), last.x, last.y);
                if (last.status == STANDING) {
                	dbg_clear("radio", "Standing]\n");
                }
                else if (last.status == WALKING) {
                	dbg_clear("radio", "Walking]\n");
                }
                else if (last.status == RUNNING) {
                	dbg_clear("radio", "Running]\n");
                }
                else if (last.status == FALLING) {
                	dbg_clear("radio", "Falling]\n");
                }
                else {
                	dbg_clear("radio", "UNKNOWN STATE]\n");
                }
    }

    event void AMSend.sendDone (message_t* buf, error_t err) { // When message is sent!
    
        if ((&packet == buf) && (err == SUCCESS)) {
            // locked = FALSE; // free to send again!
            
            pair_msg_t* pair_mess = (pair_msg_t*) call Packet.getPayload(&packet, sizeof(pair_msg_t));
			
			
			// dbg("radio", "Message of type %u was sent!\n", pair_mess->msg_type);
        	if (paired == FALSE && pair_mess->msg_type == PAIR_RESP) { // In pairing mode
                if (call PacketAcknowledgements.wasAcked(buf)) {
                    call MilliTimerPair.stop();
                    paired = TRUE;
                    dbg("radio", "[%s | PAIRING] (Node %u) has paired with (Node %u)!\n", sim_time_string(), TOS_NODE_ID, sender_address);
                    if (TOS_NODE_ID % 2 == 0) { // IF CHILD
                        call MilliTimerMsg.startPeriodic(MSG_PERIOD);
                    }
                }
            }
            
            else { // Paired
            
        	}
        	
        	locked = FALSE;
        }
    
        else { // Message was not sent correctly!
            // dbg("radio_send", "Error! Message was not sent correctly!\n");
            return;
        }
    }

    event message_t* Receive.receive (message_t* buf, void* payload, uint8_t len) { // When message is received
    	bool flagKey = TRUE;
    	smart_msg_t* smart_mess = (smart_msg_t*) payload;
        pair_msg_t* pair_mess = (pair_msg_t*) payload;
        
        if (len != sizeof(smart_msg_t) && len != sizeof(pair_msg_t)) {
            dbg("radio_pack", "[%s | ERROR] Message was not received correctly!\n", sim_time_string());
            return buf;
        }
        else { // Message received correctly!
 			// PAIRING MESSAGE
 			// dbg("radio", "Message received!\n");
 			flagKey = TRUE;
 			for (j=0; j<20; j++) {
					if (pair_mess->key[j] != key[(TOS_NODE_ID-1)/2][j]) {
						flagKey = FALSE;
					}
				}
            if (call AMPacket.destination(buf) == AM_BROADCAST_ADDR && pair_mess->msg_type == PAIR_REQ && paired == FALSE) { // Pairing message received
            	sender_address = pair_mess->address;
                if (flagKey == TRUE) { // Parent or child is pairing!
                	dbg("radio", "[%s | PAIRING] (Node %u) has sent a pairing request!\n", sim_time_string(), sender_address);
                    if (locked == FALSE) {
                        // sender_address = call AMPacket.source(buf);
                        
                        pair_mess = (pair_msg_t*) call Packet.getPayload(&packet, sizeof(pair_msg_t));

                        pair_mess->msg_type = PAIR_RESP;
                        pair_mess->address = TOS_NODE_ID;

                        for (j=0; j<20; j++) {
            				pair_mess->key[j] = key[(TOS_NODE_ID-1)/2][j];
            			}
                        
                        call PacketAcknowledgements.requestAck(&packet);
                        if (call AMSend.send(sender_address, &packet, sizeof(pair_msg_t)) == SUCCESS) {
                            locked = TRUE;
                        }
                    }
                }
                else { // Other bracelets pairing
                	dbg("radio", "[%s | PAIRING] Pairing message received from other bracelets (Node %u)!\n", sim_time_string(), sender_address);
                }
            }
            else if (call AMPacket.destination(buf) == TOS_NODE_ID && pair_mess->msg_type == PAIR_RESP && flagKey) { // Pairing response received
            	dbg("radio", "[%s | PAIRING] Pairing response received from node %u.\n", sim_time_string(), pair_mess->address);
                sender_address = pair_mess->address;
                call MilliTimerPair.stop();
                paired = TRUE;
                dbg("radio", "[%s | PAIRING] (Node %u) has paired with (Node %u)!\n", sim_time_string(), TOS_NODE_ID, sender_address);
                
                if (TOS_NODE_ID % 2 == 0) { // IF CHILD
                    call MilliTimerMsg.startPeriodic(MSG_PERIOD);
                }
            }
            else if (smart_mess->msg_type == INFO && paired == TRUE) {
                // dbg_clear("radio", "Node %hhu received info: [%hhu, (%hhu, %hhu)]", TOS_NODE_ID, smart_mess->status, smart_mess->x, smart_mess->y);
                dbg("radio", "[%s | INFORMATION] Node %hhu received info [x: %hhu, y: %hhu, ", sim_time_string(), TOS_NODE_ID, smart_mess->x, smart_mess->y);
                if (smart_mess->status == STANDING) {
                	dbg_clear("radio", "Standing]\n");
                }
                else if (smart_mess->status == WALKING) {
                	dbg_clear("radio", "Walking]\n");
                }
                else if (smart_mess->status == RUNNING) {
                	dbg_clear("radio", "Running]\n");
                }
                else if (smart_mess->status == FALLING) {
                	dbg_clear("radio", "Falling]\n");
                }
                else {
                	dbg_clear("radio", "UNKNOWN STATE]\n");
                }
                last.status = smart_mess -> status;
                last.x = smart_mess->x;
                last.y = smart_mess->y;

                call MilliTimerAlarm.startOneShot(MISSING_ALARM_PERIOD);

                if (smart_mess->status == FALLING) {
                    dbg("radio", "[%s | ALERT > FALLING] The child has fallen down at location [x: %hhu, y: %hhu]\n", sim_time_string(), smart_mess->x, smart_mess->y);
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
        mess->status = sensor_status.status;
        mess->x = sensor_status.x;
        mess->y = sensor_status.y;

        call PacketAcknowledgements.requestAck(&packet);
        if (locked == FALSE) {
            if (call AMSend.send(sender_address, &packet, sizeof(smart_msg_t)) == SUCCESS) { // Sent successfully!
                dbg("radio", "[%s | INFORMATION] Node %hhu sending info [x: %hhu, y: %hhu, ", sim_time_string(), TOS_NODE_ID, mess->x, mess->y);
                if (mess->status == STANDING) {
                	dbg_clear("radio", "Standing]\n");
                }
                else if (mess->status == WALKING) {
                	dbg_clear("radio", "Walking]\n");
                }
                else if (mess->status == RUNNING) {
                	dbg_clear("radio", "Running]\n");
                }
                else if (mess->status == FALLING) {
                	dbg_clear("radio", "Falling]\n");
                }
                else {
                	dbg_clear("radio", "UNKNOWN STATE]\n");
                }
                locked = TRUE;
            }
            else { // Failed!
                dbg_clear("radio_pack", "[%s | ERROR] Node %hhu was not able to send the information!\n", sim_time_string(), TOS_NODE_ID);
            }
        }
        return;
    }
}
