# Reasoning

PAIR:
```
struct {
  char key[21];
  address;
} obj_struct
  

parent = createObject(PARENT);
child = createObject(CHILD);

onStartUp():
  bool paired = false;
  while(!paired):
    send_broadcast(key);
    onReception(received_key, received_address){
      if (received_key == key):
        paired = true;
        address = received_address;
        send_unicast('stop', received_addresss);

```
OPERATE:
```
timer.fired():
  if (time() - received_message.time > 60 seconds):
    trigger_alarm('missing');
    print(received_message.coordinates);
  send_info(coordinates, status, time);
 
onMessageReceive():
  received_message = getInfo();

if (received_message.status == 'fall'):
  trigger_alarm('falling');
  print(received_message.coordinates);
```
