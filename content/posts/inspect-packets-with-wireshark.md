+++
title = "Inspect Packets With Wireshark"
date = "2017-10-19T10:50:52+07:00"
draft = true
+++

I have been trying to understand MQTT packets for this past week. There's already explanations about MQTT packet types and contents in their documentation, but I want to understand how the packets look like in real life.

I started it by creating a dummy environment. I used [vagrant](https://www.vagrantup.com/) to setup 2 vms, they are server and client. The server runs MQTT server, in this case I am using [Mosquitto](https://github.com/eclipse/mosquitto), and the client runs a [benchmark program](https://github.com/krylovsk/mqtt-benchmark) to the server. You can find my setup here in my github [asasmoyo/inspect-mqtt](https://github.com/asasmoyo/inspect-mqtt).

At first, I tried to sniff the packets using Wireshark by setting Wireshark to listen to `vboxnet0` where both vms connected to, it turned out Wireshark wasn't able to capture anything. After a few googling, I learned that Wireshark can only capture packets which are coming to or from the host where Wireshark runs. But in this case, both server are communicating directly in `vboxnet0`, so the packets didn't come to my laptop (in real network you might be able to capture some packets if your switch broadcast the packets to your host... but not all switches do that). That's why my Wireshark didn't capture anything.

So I tried another method, that was by running tshark (cli version of Wireshark, should be included in usual Wireshark package) in the server, save the captures then open it in Wireshark. Running tshark was surprisingly simple. Basically I had to choose which network interface that I want to sniff, set some filter and specify where tshark should write the captured packet to.

First, I checked what interfaces available in the vm:

```
tshark -d
```
