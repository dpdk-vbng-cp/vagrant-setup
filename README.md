# vagrant-setup
Create local control plane setup with vagrant

## Create local environment
Checkout submodules: `git submodule update --init --recursive`
Create keys: `for k in master minion; do salt-key --gen-keys-dir=./salt/key --gen-keys=$k; done`
Create environment: `vagrant up`

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
