generic module FakeSensorP () {
    provides interface Read<sensor_status_t>;

    uses interface Random;
    uses interface Timer<TMilli> as Timer;

} implementation {
    command error_t Read.read () {
        call  Timer.startOneShot(10);
        return SUCCESS;
    }

    event void Timer.fired () {
        sensor_status_t ss;
        uint16_t number;

        ss.x = call Random.rand16();
        ss.y = call Random.rand16();

        number = call Random.rand16() % 10; // in range 0 to 9
        if (number < 3) { // 0,1,2: 30%
            ss.status = STANDING; // STANDING
        }
        else if (number <6) { // 3,4,5: 30%
            ss.status = WALKING; // WALKING
        }
        else if (number < 9) { // 6,7,8: 30%
            ss.status = RUNNING; // RUNNING
        }
        else { // 9: 10%
            ss.status = FALLING; // FALLING
        }
        
        signal Read.readDone(SUCCESS, ss);
    }
}
