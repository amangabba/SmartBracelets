generic module FakeSensorP () {
    provides interface Read<sensor_status_t>;

    uses interface Random;
} implementation {
    command error_t Read.read () {

    }

    event void readDone () {
        sensor_status_t status
    }
}