##################################################
#     ______ _____  __  ____   __   _____   __   #
#    / __/ // / _ |/ / / / /  / /  /  _/ | / /   #
#   _\ \/ _  / __ / /_/ / /__/ /___/ / | |/ /    #
#  /___/_//_/_/ |_\____/____/____/___/ |___/     #
#                                                #
##################################################
#!/bin/bash
#Begin Remote to local server sync loop
#Version 7
#Change: added options -o and -g to preserve owner and group
# state of lock file
lock=$(cat rsyncfiles.lock)
# log level to write
log=$(sed -n "s/^log_state=//p" rsyncfiles.conf)
# log location to write
loglocal=$(sed -n "s/^log_location=//p" rsyncfiles.conf)
# total locations to sync
synctotal=$(sed -n "s/^sync_locations=//p" rsyncfiles.conf)
# current sync cycle
syncnum=1

while [ $syncnum -le $synctotal ]
do
    # sync remote servers to local server
    # if [ $log -gt XX ] is a check for log level
    if [ $lock -eq 0 ]
    then
        if [ $log -gt 10 ]; then echo "$(date) : BEGIN rsync remote to local operations $syncnum"  >> $loglocal; fi
        echo 1 > rsync.lock
        if [ $log -gt 11 ]; then echo "$(date) : lock file remote to local to 1" >> $loglocal; fi
        # local location for sync
        synclinelocal=$(sed -n "s/^local[$syncnum]=//p" rsyncfiles.conf)
        if [ $log -gt 11 ]; then echo "$(date) : synclinelocal set to $synclinelocal" >> $loglocal; fi
        #remote location to sync
        synclineremote=$(sed -n "s/^remote[$syncnum]=//p" rsyncfiles.conf)
        if [ $log -gt 11 ]; then echo "$(date) : synclineremote set to $synclineremote" >> $loglocal; fi
        if [ $log -eq 12 ]
        then
            #run rsync with highest log level, includes the following options
            # -r: recurse into directories
            # -t: preserve modification times
            # -u: skip files that are newer on the receiver
            # -h: output numbers in a human-readable format
            # -v: increase verbosity
            # -p: preserve permissions
            # -o: preserve owner
            # -g: preserve group
            # --stats: This tells rsync to print a verbose set of statistics on the file transfer
            # --progress: show progress during transfer
            rsync -rtuhvpog --stats --progress $synclineremote $synclinelocal >> $loglocal
        elif [ $log -eq 11 ]
        then
            # run rsync with medium log level
            rsync -rtuhvpog $synclineremote $synclinelocal >> $loglocal
        else
            # run rsync with lowest log level
            rsync -rtupog $synclineremote $synclinelocal >> $loglocal
        fi
        if [ $log -gt 11 ]; then echo "$(date) : end sync $synclineremote > $synclinelocal" >> $loglocal; fi
        echo 0 > /root/rsync/rsync.lock
        if [ $log -gt 11 ]; then echo "$(date) : lock file remote to local to 0" >> $loglocal; fi
        if [ $log -gt 10 ]; then echo "$(date) : END remote to local rsync operations $syncnum" >> $loglocal; fi
    else
        if [ $log -gt 10 ]; then echo "$(date) : PREVIOUS operation is still running" >> $loglocal; fi
    fi
    # advance to the next sync cycle
    syncnum=$(( $syncnum + 1 ))
done
#Begin Local to remote server sync loop
#duplicate of the remote to local loop with rsync send an drecieve locations changed
lock=$(cat /root/rsync/rsync.lock)
synctotal=$(sed -n "s/^sync_locations=//p" /root/rsync/rsyncfiles.conf)
syncnum=1

while [ $syncnum -le $synctotal ]
do
    # sync rlocal server to remote servers
    if [ $lock -eq 0 ]
    then
        if [ $log -gt 10 ]; then echo "$(date) : BEGIN rsync local to remote operations $syncnum"  >> $loglocal; fi
        echo 1 > rsync.lock
        if [ $log -gt 11 ]; then echo "$(date) : lock file local to remote to 1" >> $loglocal; fi
        synclinelocal=$(sed -n "s/^local[$syncnum]=//p" rsyncfiles.conf)
        if [ $log -gt 11 ]; then echo "$(date) : synclinelocal set to $synclinelocal" >> $loglocal; fi
        synclineremote=$(sed -n "s/^remote[$syncnum]=//p" rsyncfiles.conf)
        if [ $log -gt 11 ]; then echo "$(date) : synclineremote set to $synclineremote" >> $loglocal; fi
        if [ $log -eq 12 ]
        then
            rsync -rtuhvpog --dry-run --stats --progress $synclinelocal $synclineremote >> $loglocal
        elif [ $log -eq 11 ]
        then
            rsync -rtuhvpog --dry-run $synclinelocal $synclineremote >> $loglocal
        else
            rsync -rtupog --dry-run $synclinelocal $synclineremote >> $loglocal
        fi
        if [ $log -gt 11 ]; then echo "$(date) : end sync $synclinelocal > $synclineremote" >> $loglocal; fi
        echo 0 > /root/rsync/rsync.lock
        if [ $log -gt 11 ]; then echo "$(date) : lock file local to remote to 0" >> $loglocal; fi
        if [ $log -gt 10 ]; then echo "$(date) : END local to remote rsync operations $syncnum" >> $loglocal; fi
    else
        if [ $log -gt 10 ]; then echo "$(date) : PREVIOUS operation is still running" >> $loglocal; fi
    fi
    syncnum=$(( $syncnum + 1 ))
done
