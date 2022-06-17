// H FILE

#ifndef SMARTBRACELET_H
#define SMARTBRACELET_H

// PAYLOAD MESSAGE
typedef nx_struct smart_msg {
    nx_uint8_t msg_type;

    nx_uint8_t data[20]; // 20 to be able to send the key

    nx_uint16_t coord_x; // coordinate x of the child
    nx_uint16_t coord_y; // coordinate y of the child
} smart_msg_t;

typedef struct sensor_status {
    uint8_t status[8];

    uint16_t coord_x;
    uint16_t coord_y;
} sensor_status_t;

enum {
    AM_SMART_MSG = 6,
};

#endif