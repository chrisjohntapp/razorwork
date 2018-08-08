# razorwork

## This is a POC only at the moment

## Introduction
Each top-level directory in the data directory should contain yaml files
representing razor objects of that type. The intention is to have a gitlab
runner triggered whenever a change is committed to any of these files, which
will use SSH to update files on the razor server, and the razor api to update
it's database.

Required files will be copied to /var/local/razor-server (nodes.yaml for
example).

### Provisioning a new node

#### Preparation
Any new server should have it's first network interface connected to a switch
port, not trunked, tagged to the provisioning VLAN. 
Ensure the relevant interface is set to PXE boot.

#### Process
When booted the node will
download the razor microkernel, which will gather facts about the server and
report them to razor. Razor will create a node object in it's database to
represent this server (named "node{$n}").

The file 'nodes.yaml' contains a mapping between the razor nodename and
metadata, including the hostname and anything else relevant to the install.

Mappings can be safely specified in advance of booting the machine as razor
should only operate on the Provisioning VLAN, and there should never be an
installed server on that VLAN.  Or the administrator can wait until a node
object is available for inspection before creating the mapping, if that is
preferred (for example if multiple servers are booted at the same time and
it is not clear in which order they will register with razor).

A hook triggered immediately after the node is registered with razor will
update the node with it's metadata.





