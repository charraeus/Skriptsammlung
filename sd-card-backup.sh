#!/bin/bash
###############################################################################
# sd-card-backup.sh
# backup der SD-Karte per cifs auf den server
#
# Autor:   Christian Harraeus
# Version: 1.0
#
# Voraussetzung:
#   * PiShrink ist installiert --> https://github.com/Drewsif/PiShrink
#
# Aufbau der Credentials-Datei:
#   +----------------------------------+  
#   | # SMB-Credentials für server     |
#   | domain=<Samba-Domain> (optional) |
#   | username=<SMB-Username>          |
#   | password=<SMB-Passwort>          |
#   +----------------------------------+
###############################################################################

Debug=False

# lokal auf dem Raspi
Host=$(hostname)
PiShrink=$(which pishrink.sh)
MountPoint="/mnt/raspi_backup"
SDCardPartition="/dev/mmcblk0"

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

#-------------------------------------------------------------------------------
#--------- ab hier nichts ändern ------------------
#-------------------------------------------------------------------------------

# ein paar Variablen für leichteres Handling anlegen
readonly ScriptName=$(basename $0)
readonly Startzeit=$(date '+%F %T')
readonly Share="//${TargetService}/${TargetShare}/"
readonly TargetFilePath="${MountPoint}/${TargetDir}/${TargetFileName}"

# Logger-Funktionen
function LogNotice() {
  echo "$@"
  logger --priority user.notice --id=$$ --tag $ScriptName "$@"
}

function LogErr() {
  #echo "$@" >&2
  logger --stderr --priority user.err --id=$$ --tag $ScriptName "$@"
}

LogNotice "Skript '$ScriptName' gestartet: ${Startzeit}"

# Check, ob PiShrink installiert ist
if [ ! -x "$PiShrink" ]; then
    LogErr "PiShrink nicht gefunden! Abbruch des Skripts."
    exit 1
fi

# Check, ob das Skript als sudo gestartet wurde
if [ "$USER" != "root" ]; then
    LogErr "Bitte dieses Skript als 'root' oder mit 'sudo' ausführen."
    exit 1
fi

# Check, ob die Samba-Credentials für das Target vorhanden sind
# und die Samba-Credentials zusammenbauen
if [ ! -z "$SMBCredentialsFile" ]; then
    SMBCredentials="credentials=${SMBCredentialsFile} "
elif [[ -z "$SMBUser" || -z "$SMBPasswort" ]]; then
    LogErr "Samba-Credentials fehlen. Abbruch des Skripts."
    exit 1
else
    SMBCredentials="username=${SMBUser},password=${SMBPasswort} "
fi

# Variablen ausgeben
if [ ${Debug} == True ]; then
    LogNotice "Host='${Host}'"
    LogNotice "PiShrink='${PiShrink}'"
    LogNotice "MountPoint='${MountPoint}'"
    LogNotice "SDCardPartition='${SDCardPartition}'"
    LogNotice "SMBUser='${SMBUser}'"
    LogNotice "SMBPasswort='${SMBPasswort}'"
    LogNotice "SMBCredentialsFile='${SMBCredentialsFile}'"
    LogNotice "SMBCredentials='${SMBCredentials}'"
    LogNotice "TargetService='${TargetService}'"
    LogNotice "TargetShare='${TargetShare}'"
    LogNotice "TargetDir='${TargetDir}'"
    LogNotice "TargetFileName='${TargetFileName}'"
    LogNotice "Share='${Share}'"
    LogNotice "TargetFilePath='${TargetFilePath}'"
fi

# Check und ggf. Anlegen des Mount-Points
if [ -d "${MountPoint}" ]; then
    LogNotice "Mount point '${MountPoint}' existiert. Ok."
else
    mkdir -p ${MountPoint}
    if [ $? -ne 0 ]; then
        LogErr "Fehler beim Anlegen des Mount-Points '${MountPoint}'." \
            "Abbruch des Skripts."
        exit 1
    else
        LogNotice "Mount-Point '${MountPoint}' erfolgreich angelegt."
    fi
fi

# Server-Verzeichnis mounten am Mount-Point
mount --verbose --read-write --types cifs --options ${SMBCredentials} \
    ${Share} ${MountPoint}
if [ $? -ne 0 ]; then
    LogErr "Fehler beim Mounten des Serververzeichnisses '${Share}'." \
        "Abbruch des Skripts."
    exit 1
else
    echo "ok."
fi

# Check und ggf. Anlegen des Zielverzeichnisses
Error=False
if [ -d "${MountPoint}/${TargetDir}" ]; then
    LogNotice "Zielverzeichnis '${TargetDir}' in '${Share}' existiert. Ok."
else
    mkdir -p ${MountPoint}/${TargetDir}
    if [ $? -ne 0 ]; then
        LogErr "Zielverzeichnis '${TargetDir}' konnte nicht angelegt werden." \
            "Abbruch des Skripts."
        Error=True
    fi
fi

if [ $Error == False ]; then
    # @todo Check ob die zu kopierende Partition existiert und  ggf. abbrechen
    
    # SD-Karte kopieren - das dauert...
    LogNotice "SD-Karte wird kopiert ..."
    dd if=${SDCardPartition} of=${TargetFilePath} bs=1MB
    if [ $? -eq 0 ]; then
        LogNotice "Kopieren erfolgreich. Name der Imagedatei: " \
            "'${TargetFilePath}'."
        LogNotice "Imagedatei schrumpfen ..."
        ${PiShrink} -rzpd ${TargetFilePath}
        if [ $? -eq 0 ]; then
            LogNotice "Imagedatei erfolgreich geschrumpft:" \
                "'${TargetFilePath}.gz'."
        else
            LogErr "Fehler beim Schrumpfen. Die ungeschrumpfte Datei müsste " \
                "noch vorhanden sein."
        fi
    fi
fi

# Server-Verzeichnis wieder unmounten
umount "${Share}"
if [ $? -eq 0 ]; then
    LogNotice "'${MountPoint}' unmounten: ok."
fi

LogNotice "Skript gestartet: ${Startzeit}"
LogNotice "Skript beendet:   $(date '+%F %T')"
