// H FILE

#ifndef SMARTBRACELET_H
#define SMARTBRACELET_H

// STATUS
#define STANDING 1
#define WALKING 2
#define RUNNING 3
#define FALLING 4

// MESSAGE TYPE
#define PAIR_REQ 0
#define PAIR_RESP 1
#define INFO 2

// PAYLOAD MESSAGE
typedef nx_struct smart_msg {
    nx_uint8_t msg_type;

    nx_uint8_t status;

    nx_uint16_t x; // coordinate x of the child
    nx_uint16_t y; // coordinate y of the child
} smart_msg_t;

typedef nx_struct pair_msg {
    nx_uint8_t msg_type;

    nx_uint8_t key[20]; // 20 to be able to send the key
    nx_uint16_t address;
} pair_msg_t;



typedef struct sensor_status { // Read from the fake sensore
    uint8_t status; // kinematic status: STANDING (8), WALKING (7), RUNNING (7), FALLING (7)

    uint16_t x;
    uint16_t y;
} sensor_status_t;

enum {
    AM_SMART_MSG = 6,
};

#endif
