# IGMP discovery tool

A simple utility that leverages SNMP to discover active IGMP memberships by looking up a device's last IGMP reports.

It might come in handy if you wish to find out which multicast group(s) one or more hosts are currently interested in, typically for troubleshooting purposes.

## Dependencies
The SNMP gem is the only dependency needed (https://github.com/hallidave/ruby-snmp)

## Configuration
The 'igmp-discovery.yaml' configuration file is currently used to map the igmpCacheLastReporter SNMP object id for the device you are targetting.

Generally, you wouldn't need to do any mappings if the translation is handled by the device SNMP MIB. However, depending on the device (Juniper, Arista etc.), you would need to have that installed.

## Usage
The command-line usage is pretty straight-forward. The following example should be enough to get you going:

```
./igmp-discovery.rb -c public swi1.example.org --ns-lookup
IGMP subscriptions discovered on swi1.example.org @ Fri Mar 06 10:34:22 +0100 2015
----------------
Interface: Vlan14 ("vlan14.example.org")
IGMP reporters:
  10.0.14.41 (host41.vlan14.example.org)
    - 224.0.0.9
    - 224.0.0.11
    - 224.0.0.13
    - 224.0.0.56
  10.0.14.42 (host42.vlan14.example.org)
    - 224.0.1.1
    - 224.0.1.3
    - 224.0.1.5
    - 224.0.1.7
    - 224.0.1.102
    - 224.0.1.108
    - 224.0.1.114
    - 224.0.10.1
  10.0.14.43 (host43.vlan14.example.org)
    - 224.0.31.1
    - 224.0.31.3
    - 224.0.31.5
    - 224.0.31.7

Interface: Vlan21 ("vlan21.example.org")
IGMP reporters:
  10.0.21.11 (host11.vlan21.sc.cha)
    - 239.32.0.4
    - 239.32.0.5
    - 239.43.0.4
    - 239.42.10.50
  10.0.21.12 (host12.vlan21.sc.cha)
    - 239.20.0.15
    - 239.20.0.20
    - 239.20.0.21
    - 239.21.0.1
    - 239.21.0.3
```
