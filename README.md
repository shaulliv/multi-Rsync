# multi-Rsync
Rsync folders between multiple servers

**Installing RSYNC**

Download the rsync package from this URL: <https://pkgs.org/download/rsync>
Download the latest version for centos 7.

After you copied the package to the server install it by executing the following command:

yum localinstall rsync-….rpm

in case this did not work you can try:

rpm -i package-….rpm

**Configuring rsyncd.conf**

This file is located in the directory /etc, if it doesn't already exists, we need to create it there. 

sudo nano /etc/rsyncd.conf

In this file we add the following lines:

lock file = /var/run/rsync.lock
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid

We can divide this file in two sections, the global parameters and the modules section. The global parameters define the overall behavior of rsync. Besides the three parameters that I use here and which I explain below, we can also configure things such as the port rsync will listen too, but we are going to go with the default 873.

- lock file is the file that rsync uses to handle the maximum number of connections 
- log file is where rsync will save any information about it's activity; when it started running, when and from where does other computers connect, and any errors it encounters. 
- pid file is where the rsync daemon will write the process id that has been assigned to it, this is useful because we can use this process id to stop the daemon. 

After the global parameters, we have the modules section, which is not used on a server.



**Creating the secrets file**

Once rsyncd.conf is properly set, we need to create the secrets file. This file contains all of the usernames and passwords that will be able to log in to the rsync daemon, this usernames and passwords are independent of the user that exist in the system, so we can create users whom already exist in the system without problems. As we specified the file /etc/rsyncd.secrets in rsyncd.conf, we will create and edit this file it in our favorite text editor:

sudo nano /etc/rsyncd.secrets

In this file we add the usernames and the passwords, one per line, separated by a colon:


root:root01

Finally, change the permission of this file so it can't be read or modified by other users, rsync will fail if the permissions of this file are not appropriately set:

sudo chmod 600 /etc/rsyncd.secrets

**Configuring firewall**

- Sudo firewall-cmd --permanent --add-port=873/tcp
- Sudo firewall-cmd --reload

**Configuring password variable**

To set it permanently, and **system wide** (all users, all processes) add set variable in /etc/environment:

sudo -H gedit /etc/environment

This file only accepts variable assignments like:

RSYNC\_PASSWORD=root01

Do not use the export keyword here.

You need to logout from current user and login again, so environment variables changes take place.
### **Configuring rsyncfiles script**
Copy the rsyncfiles folder to the root folder on the server. 

Open the rsyncfiles.conf file, this should be its contents:

#script log state
\# 10 is off
\# 11 is low
\# 12 is high
log\_state=12
log\_location=/var/log/rsyncfiles.log

\# number of sync locations
sync\_locations=3

\# sync locations
remote1=rsync://root@172.16.5.47/phrases
local1=/opt/tomcat/webapps/Phrases\_itnav/
remote2=rsync://root@172.16.5.47/documents
local2=/root/rsync/rsync\_test/
remote3=rsync://root@172.16.5.53/phrases
local3=/opt/tomcat/webapps/Phrases\_itnav/
remote4=
local4=
remote5=
local5=

Please note to write the local sync location with a / at the end.
local1=/opt/tomcat/webapps/Phrases\_itnav/- correct
local1=/opt/tomcat/webapps/Phrases\_itnav - incorrect

The configuration file has 3 sections, log section, number of sync locations and the sync locations.

- The log section has 3 levels and the location of the log file.
  - 10 - won't write to log at all.
  - 11 – will write basic log and sync information
  - 12 – will write every step of the script and detailed sync information at the individual synced file.
- Number of sync locations MUST correspond to the actual amount of individual sync locations.
- Sync locations is the section that holds the sync locations  themselves.
  - Each remote/local section holds a pair of sync locations.
  - Sync locations can be added in consecutive numbers.

The script will first sync all the remote locations to their corresponding local location on the server and then it will sync all the local locations to the remote locations.

**Configuring CRON job**

Edit the cron file for the user root.

\# crontab -e

and add the following command at the bottom of the file:

\* \* \* \* \* cd /root/rsyncfiles && ./rsyncfiles.sh

The job will run once a minute (the script checks if another process is already running)

**Troubleshooting**:

If sync fails with no permissions on remote side (and the permissions are correct) try the following:

You can run the command getenforce to see if SELinux is enabled on the machine.

In my situation I ended up just disabling SELINUX completely because it wasn't needed and already disabled on the server that was working fine and just caused problems being enabled. To disable, open /etc/selinux/config and set SELINUX=disabled. To temporarily disable you can run the command setenforce 0 which will set SELinux into a permissive state rather then enforcing state which causes it to print warnings instead of enforcing.

