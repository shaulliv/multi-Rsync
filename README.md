# multi-Rsync
Rsync folders between multiple servers.

**A word on Architecture**

This script is built to sync in the following way:<br />
1. The "server" sync everything from the "clients" to itself.<br />
Overwriting only files that are newer than what it has.
2. the "server" syncs everything from itself to the "clients".<br />
Again overwriting only files that are newer that what is on the Client.
3. All machines has the latest versions of all files.

**Prerequisites**

Install Rsync for your Distro.

**Configuring rsyncd.conf**

This file is located in the directory /etc, if it doesn't already exists, we need to create it there. 

`sudo nano /etc/rsyncd.conf`

In this file we add the following lines:

- lock file = /var/run/rsync.lock
- log file = /var/log/rsyncd.log
- pid file = /var/run/rsyncd.pid

For Rsync Client Machines we need to also add sync locations, modifiying as necessary:
```
[documents]
    path = /home/juan/Documents
    comment = The documents folder of Juan
    uid = root
    gid = root
    read only = no
    list = yes
    auth users = root
    secrets file = /etc/rsyncd.secrets
    hosts allow = 192.168.1.0/255.255.255.0
```
_Please note to write the path without a / at the end._<br />
_path=/home/juan/Documents/- **incorrect**_<br />
_path=/home/juan/Documents - **correct**_

**Explanation of rsync.d file**
We can divide this file in two sections, the global parameters and the modules section. The global parameters define the overall behavior of rsync. Besides the three parameters that I use here and which I explain below, we can also configure things such as the port rsync will listen too, but we are going to go with the default 873.

- lock file is the file that rsync uses to handle the maximum number of connections 
- log file is where rsync will save any information about it's activity; when it started running, when and from where does other computers connect, and any errors it encounters. 
- pid file is where the rsync daemon will write the process id that has been assigned to it, this is useful because we can use this process id to stop the daemon. 

After the global parameters, we have the modules section, every module is a folder that we share with rsync, the important parts here are:

- [name] is the name that we assign to the module. Each module exports a directory tree. The module name can not contain slashes or a closing square bracket. 
- path is the path of the folder that we are making available with rsync 
- comment is a comment that appears next to the module name when a client obtain the list of all available modules 
- uid When the rsync daemon is run as root, we can specify which user owns the files that are transfer from and to. 
- gid This allows us to set the group that own the files that are transferred if the daemon is run as root 
- read only determines if the clients who connect to rsync can upload files or not, the default of this parameter is true for all modules. 
- list allows the module to be listed when clients ask for a list of available modules, setting this to false hides the module from the listing. 
- auth users is a list of users allowed to access the content of this module, the users are separated by comas. The users don't need to exist in the system, they are defined by the secrets file. 
- secrets file defines the file that contains the usernames and passwords of the valid users for rsync 
- hosts allow are the addresses allowed to connect to the system. Without this parameter all hosts are allowed to connect. 

After the global parameters, we have the modules section, which is not used on a server.

**Creating the secrets file**

Once rsyncd.conf is properly set, we need to create the secrets file. This file contains all of the usernames and passwords that will be able to log in to the rsync daemon, this usernames and passwords are independent of the user that exist in the system, so we can create users whom already exist in the system without problems. As we specified the file /etc/rsyncd.secrets in rsyncd.conf, we will create and edit this file it in our favorite text editor:

`sudo nano /etc/rsyncd.secrets`

In this file we add the usernames and the passwords, one per line, separated by a colon:

`root:root01`

Finally, change the permission of this file so it can't be read or modified by other users, rsync will fail if the permissions of this file are not appropriately set:

`sudo chmod 600 /etc/rsyncd.secrets`

**Launching rsync with the --daemon attribute on Client Machines**

Once everything is set, one of the ways to use rsync as a daemon is launching it with the --daemon parameter, if you followed the previous instructions you can simply use this command:

`sudo rsync --daemon`

We can check if it is running by seeing the log file that we defined in rsyncd.conf, in our example this is located in /var/log/rsyncd.log. Additionally, if the daemon is running, the file /var/run/rsyncd.pid will contain the process ID of rsync.

If we launched rsync in this manner, we can stop it by killing its process. We can obtaining the process ID by reading the contents of the file /var/run/rsyncd.pid and then invoke kill with this process ID. We can pass it directly to kill using:

`sudo kill `cat /var/run/rsyncd.pid``

**Configuring firewall**

- `Sudo firewall-cmd --permanent --add-port=873/tcp`
- `Sudo firewall-cmd --reload`

**Configuring password variable**

To set it permanently, and **system wide** (all users, all processes) add set variable in /etc/environment:

`sudo -H gedit /etc/environment`

This file only accepts variable assignments like:

`RSYNC\_PASSWORD=root01`

Do not use the export keyword here.

You need to logout from current user and login again, so environment variables changes take place.

### **Configuring rsyncfiles script**
Copy the rsyncfiles folder to the root folder on the server. 

Open the rsyncfiles.conf file, this should be its contents:
```
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
local1=/opt/tomcat/webapps/Phrases/
remote2=rsync://root@172.16.5.47/documents
local2=/root/rsync/rsync\_test/
remote3=rsync://root@172.16.5.53/phrases
local3=/home/juan/Documents/
remote4=
local4=
remote5=
local5=
```
_Please note to write the local sync location with a / at the end._<br />
_local1=/opt/tomcat/webapps/Phrases/- **correct**_<br />
_local1=/opt/tomcat/webapps/Phrases - **incorrect**_

The configuration file has 3 sections, log section, number of sync locations and the sync locations.

- The log section has 3 levels and the location of the log file.
  - 10 - won't write to log at all.
  - 11 – will write basic log and sync information
  - 12 – will write every step of the script and detailed sync information at the individual synced file.
- Number of sync locations **MUST** correspond to the actual amount of individual sync locations.
- Sync locations is the section that holds the sync locations themselves.
  - Each remote/local section holds a pair of sync locations.
  - Sync locations can be added in consecutive numbers.

The script will first sync all the remote locations to their corresponding local location on the server and then it will sync all the local locations to the remote locations.

**Configuring CRON job**

Edit the cron file for the user root.

`\# crontab -e`

and add the following command at the bottom of the file:

`\* \* \* \* \* cd /root/rsyncfiles && ./rsyncfiles.sh`

The job will run once a minute (the script checks if another process is already running)

**Troubleshooting**:

If sync fails with no permissions on remote side (and the permissions are correct) try the following:

You can run the command `getenforce` to see if SELinux is enabled on the machine.

In my situation I ended up just disabling SELINUX completely because it wasn't needed. To disable, open `/etc/selinux/config` and set `SELINUX=disabled`. To temporarily disable you can run the command setenforce 0 which will set SELinux into a permissive state rather then enforcing state which causes it to print warnings instead of enforcing.

