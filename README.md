# Skriptsammlung
Sammlung diverser Shell-Skripte.

## Für Raspberry Pi
### sd-card-backup.sh
Sichern der SD-Karte im laufenden Betrieb auf einen entfernten Server.
* Voraussetzungen: 
  * Die bash-Shell muss installiert sein (ist normalerweise standarmäßig der Fall).
  * [PiShrink](https://github.com/Drewsif/PiShrink) ist installiert.
  * Der Samba-**Client** ist installiert. Der Samba-Server (smbd) wird **nicht** benötigt.
  * gzip ist installiert (sollte normalerweise standardmäßig der Fall sein).
* Zur Anpassung müssen 
  * die Variablen am Skriptanfang ggf. angepasst werden (siehe unten) sowie 
  * entweder die Samba-Credentials-Datei mit Username und Passwort für den Sambashare erstellt werden,
  * oder die Samba-Credentials direkt im Skript eingetragen werden (nicht empfohlen).
```
# lokal auf dem Raspi
Host=$(hostname)                    <-- Hostname des Raspi - muss in der Regel nicht angepasst werden
PiShrink=$(which pishrink.sh)       <-- Pfad zum PiShrink-Skript muss in der Regel nicht angepasst werden
MountPoint="/mnt/raspi_backup"      <-- Mountpoint auf dem Raspi, auf dem der Samba-Share eingebunden wird
SDCardPartition="/dev/mmcblk0"      <-- SD-Karte im Raspi - muss in der Regel nicht angepasst werden

# Samba-Credentials für den Zielserver
SMBCredentialsFile="/home/pi/.smb-credentials-server"
SMBUser=username
SMBPasswort=passwort

# Zielserver: server, der per Samba eingebunden und 
# auf dem das image gespeichert wird
TargetService="server.fritz.box"
TargetShare="Backup"
TargetDir="raspi_backup"
TargetFileName="${Host}_sd-card-32G_$(date +'%F_%H-%M-%S').img"
```
