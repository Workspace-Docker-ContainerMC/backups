#!/bin/bash
#
#                        _____       _____ 
#                       /  _/ |     / /   |
#                       / / | | /| / / /| |
#                     _/ /  | |/ |/ / ___ |
#                    /___/  |__/|__/_/  |_|
#
#       Created by WolfAURman aka IKrell aka Furry__wolf aka RickAURman
#
# Install p7zip p7zip-plugins for Fedora/CentOS/RockyLinux.
# Install p7zip-full (Debian/Ubuntu) if you use 7z in variable $TYPE
# 
#
DATE=$(date "+%d-%m-%Y") # Date for backup names
DAY=30 # Number of days after which the old backups will be deleted
LOG_FILE=/home/minecraft/backups/backup.log # Path to log file
SFOLDER=/home/minecraft/server # Folder where is found minecraft server
BFOLDER=/home/minecraft/backups # Folder for backups
COMPOSE=/home/minecraft/velocity+dionysus-docker-compose.yml # Path to compose files
HASH=sha256 # sha256/sha512/md5
TYPE=gzip # gzip/7z/bzip2. Recommend gzip

# Here the choice is based on the variable $TYPE
function choice () {
  case "${TYPE,,}" in 
    "gzip"  ) FORMAT=tar.gz  ;;
    "7z"    ) FORMAT=7z      ;;
    "bzip2" ) FORMAT=tar.bz2 ;;
	esac
}

choice

# Checking and deleting old log file
if [ -f "$LOG_FILE" ]; then
    rm -rf "$LOG_FILE"
fi

# Stopping all containers via compose file
podman-compose -f $COMPOSE down >> "$LOG_FILE" 2>&1

function backup () {
if [ "$TYPE" == "gzip" ]; then
    cd "$BFOLDER" && tar -czvf "backup_$DATE.$FORMAT" "$SFOLDER" >> "$LOG_FILE" 2>&1
elif [ "$TYPE" == "7z" ]; then
    cd "$BFOLDER" && 7z a "backup_$DATE.$FORMAT" "$SFOLDER" >> "$LOG_FILE" 2>&1
elif [ "$TYPE" == "bzip2" ]; then
    cd "$BFOLDER" && tar -xjvf "backup_$DATE.$FORMAT" "$SFOLDER" >> "$LOG_FILE" 2>&1
fi
}

backup

function hash () {
if [ "$HASH" == "md5" ]; then
    md5sum "$BFOLDER/backup_$DATE.$FORMAT" > "$BFOLDER/backup_$DATE.$FORMAT.md5"
elif [ "$HASH" == "sha256" ]; then
    sha256sum "$BFOLDER/backup_$DATE.$FORMAT" > "$BFOLDER/backup_$DATE.$FORMAT.sha256"
elif [ "$HASH" == "sha512" ]; then
    sha512sum "$BFOLDER/backup_$DATE.$FORMAT" > "$BFOLDER/backup_$DATE.$FORMAT.sha256"
fi
}

hash

# CleanUp old backup files
find "$BFOLDER" -type f -mtime +"$DAY" -delete >> "$LOG_FILE" 2>&1

# Start all containers via compose file
podman-compose -f $COMPOSE up -d >> "$LOG_FILE" 2>&1