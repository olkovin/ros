# Telegram subnets for prioritization
/ip firewall address-list
add address=91.108.12.0/22 list=telegram-ips
add address=149.154.172.0/22 list=telegram-ips
add address=91.108.16.0/22 list=telegram-ips
add address=91.108.56.0/23 list=telegram-ips
add address=149.154.168.0/22 list=telegram-ips
add address=91.108.4.0/22 list=telegram-ips
add address=91.108.8.0/22 list=telegram-ips
add address=91.108.56.0/22 list=telegram-ips
add address=149.154.160.0/20 list=telegram-ips
add address=149.154.164.0/22 list=telegram-ips

# Mangle rules
/ip firewall mangle
add action=log chain=- comment=">>>>>>> MAIN SECTION <<<<<<<"
add action=log chain=- comment="====== PRIO 1 ======"
add action=mark-packet chain=prerouting comment=ICMP log-prefix=\
    icmp_mark_check new-packet-mark=prio_1_pckts passthrough=yes protocol=\
    icmp
add action=mark-packet chain=prerouting comment="DNS TCP" new-packet-mark=\
    prio_1_pckts passthrough=yes port=53 protocol=tcp
add action=mark-packet chain=prerouting comment="DNS UDP" new-packet-mark=\
    prio_1_pckts passthrough=yes port=53 protocol=udp
add action=mark-packet chain=prerouting comment="SMALL TCP ACK PACKETS" \
    new-packet-mark=prio_1_pckts packet-size=0-123 passthrough=yes protocol=\
    tcp tcp-flags=ack
add action=log chain=- comment="====== PRIO 1 ======"
add action=log chain=- comment="====== PRIO 2 ======"
add action=mark-packet chain=prerouting comment="DSCP 40" dscp=40 \
    new-packet-mark=prio_2_pckts passthrough=yes
add action=mark-packet chain=prerouting comment="DSCP 46" dscp=46 \
    new-packet-mark=prio_2_pckts passthrough=yes
add action=mark-connection chain=postrouting comment=\
    "FaceTime 0-512k connection rate" connection-rate=0-512k \
    connection-state=new dst-port=3478,4080,5223 new-connection-mark=\
    facetime-connection passthrough=no protocol=tcp
add action=mark-connection chain=postrouting comment=\
    "FaceTime 0-512k connection rate" connection-rate=0-512k \
    connection-state=new dst-port=16393-16402 new-connection-mark=\
    facetime-connection passthrough=no protocol=udp
add action=mark-connection chain=prerouting comment=\
    "FaceTime 0-512k connection rate" connection-rate=0-512k \
    connection-state=new new-connection-mark=facetime-connection passthrough=\
    no protocol=tcp src-port=3478,4080,5223
add action=mark-connection chain=prerouting comment=\
    "FaceTime 0-512k connection rate" connection-rate=0-512k \
    connection-state=new new-connection-mark=facetime-connection passthrough=\
    no protocol=udp src-port=16393-16402
add action=mark-packet chain=prerouting comment=\
    "FaceTime 0-512k connection rate" connection-mark=facetime-connection \
    connection-state="" new-packet-mark=prio2_pckts passthrough=yes
add action=log chain=- comment="====== PRIO 2 ======"
add action=log chain=- comment="====== PRIO 3 ======"
add action=mark-connection chain=prerouting comment="Google Hangouts" \
    connection-state=new dst-port=19302-19309 new-connection-mark=\
    hangouts-connect passthrough=no protocol=udp
add action=mark-connection chain=prerouting comment="Google Hangouts" \
    connection-state=new dst-port=19305-19309 new-connection-mark=\
    hangouts-connect passthrough=no protocol=tcp
add action=mark-packet chain=prerouting comment="Google Hangouts" \
    connection-mark=hangouts-connect new-packet-mark=prio_3_pckts \
    passthrough=yes
add action=mark-connection chain=prerouting comment="Slack calls" \
    connection-state=new dst-port=22466 new-connection-mark=slack-connect \
    passthrough=no protocol=udp
add action=mark-connection chain=prerouting comment="Slack calls" \
    connection-state=new dst-port=22466 new-connection-mark=slack-connect \
    passthrough=no protocol=tcp
add action=mark-packet chain=prerouting comment="Slack calls" \
    connection-mark=slack-connect new-packet-mark=prio_3_pckts passthrough=\
    yes
add action=mark-connection chain=prerouting comment=\
    "RTP generall UDP ports with 0-512k connection rate limit " \
    connection-rate=0-512k connection-state=new dst-port=10000-20000 \
    log-prefix="RTP ports:" new-connection-mark=rtp-connection passthrough=no \
    protocol=udp
add action=mark-packet chain=prerouting comment=\
    "RTP generall UDP ports with 0-512k connection rate limit " \
    connection-mark=rtp-connection connection-rate=0-512k log-prefix=\
    "RTP ports:" new-packet-mark=prio_3_pckts passthrough=yes
add action=mark-connection chain=prerouting comment=\
    "SIP UDP ports overall with 0-512k rate limit" new-connection-mark=\
    sip-connection passthrough=no port=5060-5082 protocol=udp
add action=mark-packet chain=prerouting comment=\
    "SIP UDP ports overall with 0-512k rate limit" connection-mark=\
    sip-connection new-packet-mark=prio_3_pckts passthrough=yes
add action=mark-connection chain=prerouting comment=\
    "Telegram connections TO with 0-2m connection rate" connection-rate=0-2M \
    connection-state=new dst-address-list=telegram-ips new-connection-mark=\
    telegram-connections passthrough=no
add action=mark-connection chain=prerouting comment=\
    "Telegram connections FROM with 0-2m connection rate" connection-rate=\
    0-2M connection-state=new new-connection-mark=telegram-connections \
    passthrough=no src-address-list=telegram-ips
add action=mark-connection chain=prerouting comment=\
    "Telegram connections 0-2m connection rate" connection-rate=0-2M \
    connection-state=new new-connection-mark=telegram-connections \
    passthrough=no port=599,1400 protocol=udp
add action=mark-packet chain=prerouting comment="Telegram packets" \
    connection-mark=telegram-connections new-packet-mark=prio_3_pckts \
    passthrough=yes
add action=mark-connection chain=prerouting comment="SSH connections" \
    connection-state=new dst-port=22 new-connection-mark=ssh-connection \
    passthrough=no protocol=tcp
add action=mark-packet chain=prerouting comment="SSH connections" \
    connection-mark=ssh-connection new-packet-mark=prio_3_pckts passthrough=\
    yes
add action=log chain=- comment="====== PRIO 3 ======"
add action=log chain=- comment="====== PRIO 4 ======"
add action=mark-connection chain=prerouting comment=\
    "RDP connections | Prio 4" connection-state=new new-connection-mark=\
    rdp-connection passthrough=no port=3389 protocol=tcp
add action=mark-connection chain=prerouting comment=\
    "RDP connections | Prio 4" connection-state=new new-connection-mark=\
    rdp-connection passthrough=no port=3389 protocol=udp
add action=mark-packet chain=prerouting comment="RDP connections | Prio 4" \
    new-packet-mark=prio_4_pckts passthrough=yes
add action=log chain=- comment="====== PRIO 4 ======"
add action=log chain=- comment="====== PRIO 5 ======"
add action=mark-connection chain=prerouting comment="WEB traffic | Prio 5" \
    connection-state=new new-connection-mark=web-traffic-connection \
    passthrough=no port=80,443,8080,8443 protocol=tcp
add action=mark-packet chain=prerouting comment="WEB traffic | Prio 5" \
    connection-mark=web-traffic-connection new-packet-mark=prio_5_pckts \
    passthrough=yes
add action=log chain=- comment="====== PRIO 5 ======"
add action=log chain=- comment=">>>>>>> MAIN SECTION <<<<<<<"

# Queue tree section
# Make sure you set max-limit at your maximum uplink interface bandwith
/queue tree
add max-limit=1G name=QoS_global parent=global priority=1
add comment="Priority 1 traffic" name=prio_1 packet-mark=prio_1_pckts parent=\
    QoS_global priority=1 queue=ethernet-default
add comment="Priority 2 traffic" name=prio_2 packet-mark=prio_2_pckts parent=\
    QoS_global priority=2 queue=ethernet-default
add comment="Priority 3 traffic" name=prio_3 packet-mark=prio_3_pckts parent=\
    QoS_global priority=3 queue=ethernet-default
add comment="Priority 4 traffic" name=prio_4 packet-mark=prio_4_pckts parent=\
    QoS_global priority=4 queue=ethernet-default
add comment="Priority 7 traffic" name=prio_7 packet-mark=no-mark parent=\
    QoS_global priority=7 queue=ethernet-default
add comment="Priority 5 traffic" name=prio_5 packet-mark=prio_5_pckts parent=\
    QoS_global priority=5 queue=ethernet-default
add comment="Priority 6 traffic" name=prio_6 packet-mark=prio_6_pckts parent=\
    QoS_global priority=6 queue=ethernet-default