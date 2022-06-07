#include <stdio.h>

#include "contiki.h"
#include "sys/timer.h"
#include "net/rime/rime.h" // For Broadcast

struct BraceletStruct {
    char key[21];
};

PROCESS(parent, "Parent process");
PROCESS(child, "Child process");

PROCESS_THREAD(parent, ev, data) {
    BraceletStruct parent_data;
    PROCESS_BEGIN();

    // PAIRING
    bool paired = false;
    while(!paired) {
        // SEND BROADCAST
        broad
    }

    while(1) {
        // START TIMER

    }

    PROCESS_END;
}

PROCESS_THREAD(child, ev, data) {
    BraceletStruct child_data;
    PROCESS_BEGIN();

    // PAIRING
    bool paired = false;
    while(!paired) {
        // SEND BROADCAST
    }

    PROCESS_END();
}
