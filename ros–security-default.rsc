# RouterOS Default Security Deployer
# SecurityDeployerScript
# t.me/olekovin
# last update 17.02.2022
#####################################################
## Here you can specify the WAN and LAN interfaces ##
:local WANinterfaces ""
:local LANinterfaces ""
:log info ""
:log info ""
:log warning "Starting do some security magic :)"
:log info ""
:do {
    :log warning "Clearing current firewall rules..."
    /ip firewall filter remove [find where comment!="all"]
    :delay 2
} on-error={:log error "Error when removing current firewall rules, please check this code section."}

: do {
    :log warning "Creating interface lists..."
    /interface list add name=WAN
    /interface list add name=LAN
    :delay 1
    :log warning "Creating interface lists finished!"
} on-error={:log error "Error when creating interface lists , maybe one of them are exist..."}

: do {
    :log warning "Adding default firewall address-lists..."
     /ip firewall address-list
        add address=acs.wcdi.cc list=mgmt-acl
        add address=acs.wcdi.cc list=block-immunity
        add address=acl.k2o.cc list=mgmt-acl
        add address=acl.k2o.cc list=block-immunity
        add address=8.8.8.8 list=block-immunity
        add address=8.8.4.4 list=block-immunity
        add address=1.1.1.1 list=block-immunity
        add address=9.9.9.9 list=block-immunity
    :delay 1
    :log warning "Adding default firewall address-lists finished!"
} on-error={:log error "Error when adding default firewall address-lists, maybe one of them are exist..."}
:do {
    :log warning "Adding description...."
    /ip firewall filter
add action=passthrough chain=- comment=\
    "=============== DECSRIPTION ==============="
/ip firewall filter
add action=passthrough chain=- comment=\
    "Firewall by t.me/olekovin"
/ip firewall filter
add action=passthrough chain=- comment=\
    "Version from 13.02.2022"
/ip firewall filter
add action=passthrough chain=- comment=\
    "All rights reserved (C)"
/ip firewall filter
add action=passthrough chain=- comment=\
    "=============== DECSRIPTION ==============="
    :log warning "Adding description finished!"
} on-error={:log error "Error when adding firewall description, check this code section."}

:do {
    :log warning "Adding INPUT chain rules...."
/ip firewall filter
add action=passthrough chain=- comment=\
    "=============== INPUT SECTION ==============="
add action=add-src-to-address-list address-list=banned \
    address-list-timeout=2w chain=input comment="TCP portscanners detection" \
    in-interface-list=WAN protocol=tcp psd=21,3s,3,1 src-address-list=\
    !block-immunity
add action=add-src-to-address-list address-list=banned \
    address-list-timeout=2w chain=input comment="UDP portscanners detection" \
    in-interface-list=WAN protocol=udp psd=21,3s,3,1 src-address-list=\
    !block-immunity
add action=jump chain=input comment="Jump to bruteforce scan chain" \
    connection-state=new dst-port=22,3389,8291 jump-target=bruteforce-scan-chain \
    protocol=tcp src-address-list=!block-immunity
add action=accept chain=input comment="Accept established,related" \
    connection-state=established,related in-interface-list=WAN
add action=accept chain=input comment="Accept ALL input from mgmt-acl-list " \
    src-address-list=mgmt-acl
add action=accept chain=input comment="Accept ICMP with PL 5pps" limit=\
    3,5:packet protocol=icmp
add action=accept chain=input comment="Accept remote mgmt on custom port" \
    dst-port=8291 protocol=tcp
add action=accept chain=input comment="Accept GRE" protocol=gre
add action=accept chain=input comment=\
    "Accept incoming L2TP-server connections" dst-port=500,4500,1701 \
    in-interface-list=WAN protocol=udp
add action=accept chain=input comment="Accept IPsec-esp" in-interface-list=WAN \
    protocol=ipsec-esp
add action=accept chain=input comment="Accept IPsec-ah" in-interface-list=WAN \
    protocol=ipsec-ah
add action=drop chain=input comment="Drop DNS external using on input (udp)" \
    dst-port=53 in-interface-list=WAN protocol=udp
add action=drop chain=input comment="Drop DNS external using on input (tcp)" \
    dst-port=53 in-interface-list=WAN protocol=tcp
add action=drop chain=input comment="Drop ALL from input" in-interface-list=WAN  disabled=yes
add action=passthrough chain=- comment=\
    "=============== INPUT SECTION ==============="
    :delay 1
    :log warning "Adding INPUT chain rules finished!"
} on-error={:log error "Error when adding INPUT chain rules, probably one of them exists, or specified interface/interface list doesn't exist.."}
:delay 1
:log info ""
:log info ""
:do {
    :log warning "Adding FORWARD chain rules...."
/ip firewall filter
add action=passthrough chain=- comment=\
    "=============== FORWARD SECTION ==============="
add action=accept chain=forward comment="Accept established,related" \
    connection-state=established,related
add action=drop chain=forward comment="Drop invalid connections on forward" \
    connection-state=invalid in-interface-list=WAN log=yes log-prefix=\
    droped_invalid_connection:
add action=drop chain=forward comment=\
    "Drop incoming forward packets that are not NATted" connection-nat-state=\
    !dstnat connection-state=new in-interface-list=WAN log=yes log-prefix=!NAT
add action=passthrough chain=- comment=\
    "=============== FORWARD SECTION ==============="
    :delay 1
    :log warning "Adding FORWARD chain rules finished!"
} on-error={:log error "Error when adding FORWARD chain rules, probably one of them exists, or specified interface/interface list doesn't exist.."}
:delay 1
:log info ""
:log info ""
:do {
    :log warning "Adding BRUTEFORCE DETECTION chain rules...."
/ip firewall filter
add action=passthrough chain=- comment=\
    "=============== BRUTEFORCE SCAN SECTION ==============="
add action=add-src-to-address-list address-list=banned \
    address-list-timeout=2w chain=bruteforce-scan-chain comment=\
    "Bruteforce detection stage 5" connection-state=new in-interface-list=WAN \
    src-address-list=bruteforce-detection-stage4 disabled=yes
add action=add-src-to-address-list address-list=bruteforce-detection-stage4 \
    address-list-timeout=30s chain=bruteforce-scan-chain comment=\
    "Bruteforce detection stage 4" connection-state=new in-interface-list=WAN \
    src-address-list=bruteforce-detection-stage3 disabled=yes
add action=add-src-to-address-list address-list=bruteforce-detection-stage3 \
    address-list-timeout=25s chain=bruteforce-scan-chain comment=\
    "Bruteforce detection stage 3" connection-state=new in-interface-list=WAN \
    src-address-list=bruteforce-detection-stage2 disabled=yes
add action=add-src-to-address-list address-list=bruteforce-detection-stage2 \
    address-list-timeout=20s chain=bruteforce-scan-chain comment=\
    "Bruteforce detection stage 2" connection-state=new in-interface-list=WAN \
    src-address-list=bruteforce-detection-stage1 disabled=yes
add action=add-src-to-address-list address-list=bruteforce-detection-stage1 \
    address-list-timeout=15s chain=bruteforce-scan-chain comment=\
    "Bruteforce detection stage 1" connection-state=new in-interface-list=WAN disabled=yes
add action=passthrough chain=- comment=\
    "=============== BRUTEFORCE SCAN SECTION ==============="
    :delay 1
    :log warning "Adding BRUTEFORCE DETECTION chain rules finished!"
} on-error={:log error "Error when adding BRUTEFORCE DETECTION chain rules, probably one of them exists, or specified interface/interface list doesn't exist.."}
:delay 1
:log info ""
:log info ""
:do {
    :log warning "Adding dropping bruteforces and portscanners on RAW...."
/ip firewall raw
add action=drop chain=prerouting comment="Drop all banned" in-interface-list=WAN src-address-list=banned disabled=yes
    :delay 1
    :log warning "Adding dropping bruteforces and portscanners on RAW finished!"
} on-error={:log error "Error when adding dropping bruteforces and portscanners on RAW rules, probably one of them exists, or specified interface/interface list doesn't exist.."}

:delay 1
:log info ""
:log info ""

:do {
    :log warning "Disabling all firewall helpers..."

/ip firewall service-port
set ftp disabled=yes
set tftp disabled=yes
set irc disabled=yes
set h323 disabled=yes
set sip disabled=yes
set pptp disabled=yes
set udplite disabled=yes
set dccp disabled=yes
set sctp disabled=yes
    :delay 1
    :log warning "Disabling all firewall helpers finished!"
} on-error={:log error "Disabling all firewall helpers was failed... Check this code section"}
:delay 1
:log info ""
:log info ""
:do {
    :log warning "Doing some minor security stuff..."
/system package update
set channel=long-term
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
/ip neighbor discovery-settings set discover-interface-list=LAN
    :delay 1
    :log warning "Some minor security stuff was done!"
} on-error={:log error "Some minor security stuff was failed... Check this code section"}
:log info ""
:log info ""
:delay 2
/system script remove [find where source~"SecurityDeployerScript"]
:delay 1
:log info ""
:log warning "Some security magic was done, your router secured now :)"
