# SNMPv3-Inventory-Script

This Bash script uses SNMPv3 to inventory Cisco switches, pulling detailed hardware info including hostname, model, serial number, physical description, and stack member IDs. It parses SNMP OIDs to detect mismatched models within a switch stack — helping you spot potential config issues or hardware oddities.

Key features:

AuthPriv SNMPv3 support (AES + SHA)

Bulkwalk-based inventory collection

Detects stack member model mismatches

Outputs clean, tabulated data for easy review

Easily extendable for logging or integration with CMDBs

Ideal for network engineers needing quick visibility into hardware consistency without spinning up bloated tools or management suites.
