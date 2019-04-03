#!/bin/bash

OVS_BRIDGE=ovs-br0
NAMESPACES="client-1 client-2"

enable_forwarding() {
    echo "Enabling forwarding."
    echo 1 >&1 | sudo tee /proc/sys/net/ipv4/ip_forward
}

create_bridge() {
    bridge=$1

    if sudo ip l show $bridge 2>&1; then
      >&2 echo "Bridge $bridge already exists."
      exit 1
    else
        echo "Creating bridge $bridge."
        sudo ovs-vsctl add-br $bridge
    fi
    sudo ip link set $bridge up

}

delete_bridge() {
    bridge=$1

    if ! sudo ip l show $bridge >/dev/null 2>&1; then
      >&2 echo "Bridge $bridge does not exist. Nothing to do."
    else
        sudo ovs-vsctl del-br $bridge
    fi
}

configure_namespace() {
    ns=$1
    hostif=$2
    nsif=$3
    bridge=$4

    echo "Creating peer interfaces $hostif $nsif for namespace $ns."
    sudo ip link add $hostif type veth peer name $nsif
    sudo ip link set $nsif netns $ns
    sudo ip netns exec $ns ip link set $nsif up
    sudo ip link set $hostif up
    sudo ovs-vsctl add-port $bridge $hostif
}

create_namespaces() {
    bridge=$1
    shift
    namespaces=$@

    for ns in $namespaces; do
        veth=veth-${ns}
        vpeer=vpeer-${ns}
        echo "Creating namespace $ns."
        if sudo ip netns add $ns; then
            configure_namespace $ns $veth $vpeer $bridge
        else
            >&2 echo "Namespace $ns already exists."
        fi
    done
}

delete_namespaces() {
    namespaces=$@

    for ns in $namespaces; do
        echo "Deleting namespace $ns."
        sudo ip netns delete $ns 2> /dev/null
    done
}

cleanup_environment() {
    delete_bridge $OVS_BRIDGE
    delete_namespaces $NAMESPACES
}

create_environment() {
    enable_forwarding
    create_bridge $OVS_BRIDGE
    create_namespaces $OVS_BRIDGE $NAMESPACES
}

    case $1 in
        create)
            create_environment
            exit 0
            ;;
        delete)
            cleanup_environment
            exit 0
            ;;
        *)
            echo "ERROR: unknown parameter \"$1\""
            exit 1
            ;;
    esac
    shift
