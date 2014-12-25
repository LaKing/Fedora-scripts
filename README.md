Fedora-scripts
==============

Bash scripts for Fedora based systems.

Wokstation installer can be used to add additional software automatically. Browsers, media players, etc.
Status: production-ready.
I installed already several systems. 
If you notice something, or you have an improvement, please let me know.


The server configuration tool srvctl can be used to controll lxc container creation and management. 
Think of it as a virtual serverfarm manager, controlling the host and some VE's.
Status: Beta
As the software packages under it change, this script is always under construction. 
Recommended for administrators / experts, who know what they do! Use it on your own risks!
If you use or plan to use this script you should contact me for support.


On the host,
```
[root@host /root]# /usr/bin/srvctl 
# version 1.47.2
No Command.
 Usage:	srvctl command [argument]

The list of supported commands: 
  version			Display what srvctl version we are using. 
  add-user USERNAME		Add a new user to the system. 
  update-password [USERNAME]	Update password based on .password file 
  SERVICE OP		You can start|stop|restart|status the service via systemctl.  +|-|!|? 
  diagnose			Run a set of diagnostic commands. 

  update-install [all]		This will update srvctl, recompile LXC and update some related packages if necessery. Use 'all' to force to reinstall everything. 
  status			Report status of containers. 
  status-all			Detailed container and system health status report. 
  start VE			Start a container. 
  start-all			Start all containers and services. 
  stop VE			Stop a container. 
  disable VE			Stop and diable container. 
  stop-all			Stop all containers. 
  kill VE			Force all containers to stop. 
  kill-all			Force all containers to stop. 
  reboot VE			Restart a container. 
  reboot-all			Restart all containers. 
  exec-all 'CMD [..]'		Execute a command on all running containers. 
  regenerate [all]		Regenerate configuration files, and restart affected services. 
  remove VE			Remove a container. 
  add VE [USERNAME]		Add new container.

```

On the guest, the VE
```
[root@test.ve /root]# /usr/bin/srvctl 
# version 1.47.2
No Command.
 Usage:	srvctl command [argument]

The list of supported commands:
  version			Display what srvctl version we are using.
  add-user USERNAME		Add a new user to the system.
  update-password [USERNAME]	Update password based on .password file
  SERVICE OP		Y	You can start|stop|restart|status the service via systemctl.  +|-|!|?
  install-mariadb		install MariaDB (mysql) database.

  setup-codepad [apache|node]	Install ep_codepad, an Etherpad based collaborative code editor, and start a new project.
  setup-logio			Install log.io, a web-browser based realtime log monitoring tool.
  add-wordpress [path]		Install Wordpress. Optionally to a folder (URI).
  add-joomla [path]		Install the latest Joomla!

```