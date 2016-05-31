# NetworkMerger
Bachelor diploma of SPb ITMO student

The set of bash scripts which allows to join two different networks.
Controlstation will configure stations to create vxlan tunnel between them.

There are two topologies to join th networks:
single and double.
It's cheaper and easier to use single topology to join networks in one cluster,
but double topo allows you to join networks in different clusters. It uses VxLAN L2 OSI incapsulation to build tunnel between stations.

See the deployment guide to build the topology and netm.sh script to configure it.
