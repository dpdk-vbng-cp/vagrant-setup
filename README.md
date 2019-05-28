# vagrant-setup

Create local control plane setup with vagrant

## Create local environment

1. Checkout submodules: `git submodule update --init --recursive`
2. Create keys: `for k in master minion; do salt-key --gen-keys-dir=./salt/key
   --gen-keys=$k; done`
3. Create environment: `vagrant up`

## Configuring authentication with chap
Before starting the `loadbalancer` app, please configure to allow the authentication of the clients.

Steps to configure the authentication procedure: 

`sudo nano /etc/ppp/chap-secrets`

paste the below in the chap file:

`intel           *       bng_admin`

## Configuring interfaces of client1 and client2

Before starting the app please ssh to both of your client machine:
in our case 

`vagrant ssh accel1`
`vagrant ssh accel2`

Update the accel-ppp.conf file:

`sudo nano /etc/accel-ppp.conf`

check the interface for `pppoe` & `ipoe` funtion on the file and replace the interface name with your own interface:
in our case interface = `eth1`
save the file and restart the `accel-ppp` service.

`sudo systemctl restart accel-ppp.service`


## Architecure

```
+=======================================+
|                 HOST                  |
|          +------+   +------+          |
|          |accel1|   |accel2|          |
|          |  vm  |   |  vm  |          |
|          +------+   +------+          |
|               \       /               |
|                +-----+                |
|                | OVS |                |
|                +-----+                |
|                |     |                |
|           client-1  client-2          |
|                                       |
+=======================================+
```

## Connect the ryu loadbalancer app

1. Clone the ryu loadbalancer app: `git clone https://github.com/dpdk-vbng-cp/loadbalancer.git`
2. Go into the project: `cd loadbalancer`
3. Run the ryu app with ryu-manager: `ryu-manager ryu-app/simple_switch_13.py`
4. Open new terminal and connect the controller to the ovs bridge: `sudo
   ovs-vsctl set-controller ovs-br0 tcp:0.0.0.0`

You can test the loadbalancer by connecting your clients to the accel-ppps:

Client 1:

```
sudo ip netns exec client-1 pppd pty "/usr/sbin/pppoe -I vpeer-client-1 -T 80 -U -m 1412" noccp ipparam vpeer-client-1 linkname vpeer-client-1 noipdefault noauth default-asyncmap defaultroute hide-password updetach mtu 1492 mru 1492 noaccomp nodeflate nopcomp novj novjccomp lcp-echo-interval 40 lcp-echo-failure 3 user intel
```

Client 2:

```
sudo ip netns exec client-2 pppd pty "/usr/sbin/pppoe -I vpeer-client-2 -T 80 -U -m 1412" noccp ipparam vpeer-client-2 linkname vpeer-client-2 noipdefault noauth default-asyncmap defaultroute hide-password updetach mtu 1492 mru 1492 noaccomp nodeflate nopcomp novj novjccomp lcp-echo-interval 40 lcp-echo-failure 3 user intel
```

The output from the ryu app shows you that traffic has been balanced between
the accel instances:

```
packet in 266163930899022 f2:13:1e:8d:a2:4e 33:33:00:00:00:fb 4294967294
packet in 266163930899022 42:29:9c:16:f8:84 ff:ff:ff:ff:ff:ff 1
Received BROADCAST 266163930899022 42:29:9c:16:f8:84 ff:ff:ff:ff:ff:ff 1
Forwarding to destination accel 00:00:00:00:00:a1 3
packet in 266163930899022 42:29:9c:16:f8:84 ff:ff:ff:ff:ff:ff 1
Received BROADCAST 266163930899022 42:29:9c:16:f8:84 ff:ff:ff:ff:ff:ff 1
Forwarding to destination accel2 00:00:00:00:00:b1 4
packet in 266163930899022 42:29:9c:16:f8:84 ff:ff:ff:ff:ff:ff 1
Received BROADCAST 266163930899022 42:29:9c:16:f8:84 ff:ff:ff:ff:ff:ff 1
Forwarding to destination accel 00:00:00:00:00:a1 3
packet in 266163930899022 ce:e3:c1:73:62:df ff:ff:ff:ff:ff:ff 2
Received BROADCAST 266163930899022 ce:e3:c1:73:62:df ff:ff:ff:ff:ff:ff 2
Forwarding to destination accel2 00:00:00:00:00:b1 4
packet in 266163930899022 ce:e3:c1:73:62:df ff:ff:ff:ff:ff:ff 2
Received BROADCAST 266163930899022 ce:e3:c1:73:62:df ff:ff:ff:ff:ff:ff 2
Forwarding to destination accel 00:00:00:00:00:a1 3
packet in 266163930899022 ce:e3:c1:73:62:df ff:ff:ff:ff:ff:ff 2
Received BROADCAST 266163930899022 ce:e3:c1:73:62:df ff:ff:ff:ff:ff:ff 2
Forwarding to destination accel2 00:00:00:00:00:b1 4
```
