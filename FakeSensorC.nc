generic configuration FakeSensorC() {

    provides interface Read<sensor_status_t>; // Read type

} implementation {

    components MainC, RandomC;
    components new FakeSensorP();

    Read = FakeSensorP;

    FakeSensorP.Random -> RandomC;
    RandomC <- MainC.SoftwareInit;
}