#!/bin/bash
# Last update:2014.07.17-15:48:17
# version 1.7.8
#
# Installer script for Fedora
#
# D250 Laboratories / D250.hu
# Author: István király
# LaKing@D250.hu
# 
# 2014.01.12 - Inital release for Fedora 20.
# 2014.01.15 - Added features and bugfixes
# - added hint/help and a default value to the question que
# - broke up single line yum commands to multiple lines, as if a package is broken the whole operation fails
# 2014.01.18 - Added Oracle java installation to chrome
#
# Please read all licencses in advance. I assume that you have read all license agreements, and you agree.
#
# Finetune this script by checking the functions.
# Comment / uncomment / alter constants.
#
## download, update with:
# curl http://d250.hu/scripts/install-workstation.sh > install.sh 
## run with bash 
# && bash install.sh
#
## Source URL
URL="http://d250.hu/scripts/install-workstation.sh"
## Timestamp
NOW=$(date +%Y.%m.%d-%H:%M:%S)
## logfile
LOG=$(pwd)/install.log
## current dir
DIR=$(pwd)
## temporal backup and work directory
TMP=/temp
## A general message string 
MSG="## D250 Laboratories "$0" @ "$NOW
## The "default user" also the first argument
USR=$1

## Any enemy in sight? :)
clear

if [ -z "$1" ]; then
## there is no argument
    if [ "$UID" -ne "0" ]
    then
     ## calling user is not root
     USR=$(whoami)
    else
     ## user is root, and a default user is needed
     USR=$(ls /home | grep -m 1 '')
     
    fi
else
## an argument was given
    if [ -d "/home/$1" ]; then
     # This is a valid user
     echo "Invoked with a valid user argument" >> $LOG
    else
     # arguments are not valid, maybe the user needs help?
     echo "Usage: $0 [USER]"
     echo "Start a workstation installation script, to install and fine-tune Fedora 20"
     echo "Please visit d250.hu for details."
     exit
    fi
fi

## If user is root or runs on root privileges, continiue.
if [ "$UID" -ne "0" ]
then
  echo "Root privileges needed to run this script. Trying with sudo."
  ## Attemt to get root privileges with sudo, and run the script
  sudo bash $0 $USR
  exit
fi



## Author info
# echo "István Király - D250 Laboratories. LaKing@D250.hu"

## Version info
if [[ $(cat /etc/fedora-release) == "Fedora release 20 (Heisenbug)" ]]
then
    echo "This is the workstation installer for Fedora 20."
else
    echo $(cat /etc/fedora-release)" detected!"
    echo "Fedora 20"
fi

if [ -z "$USR" ]; then echo "No user could be located."; else
echo "Started with user: "$USR
echo "Started with user: "$USR >> $LOG
fi
echo $MSG
mkdir -p $TMP


## Update this script if possible
url_response=$(curl --write-out %{http_code} --silent --output $TMP/install-workstation-latest.sh http://d250.hu/scripts/install-workstation.sh)
if [ "$url_response" -ne "200" ]
then
   echo "Failed to download latest version of this script." >> $LOG
else
   echo "checking: "$0" against "$URL >> $LOG
   if  diff  $TMP/install-workstation-latest.sh $0 >> $LOG
   then
    echo "This is the latest original release of the script"
   else
    echo "Script has been modified, or is not the latest version."
    echo -n "Do you wish to run the latest release of this script? "
    read -s -r -p "[y/N] " -n 1 -i "y" key
    if [[ $key == y ]]; then
     key="yes"
    else
     key="no";
    fi
    echo $key

    if [[ $key == y* ]]; then
     echo "Switching to latest version." >> $LOG
     cd $TMP
     bash install-workstation-latest.sh
     exit
    fi
   fi
fi
echo "Questioning Installation started." >> $LOG

a=0
n=0
h=0

## Basic helper functions

function question {
    ## Add to the question que asq, with counter a

    (( a++ ))
    asq[$a]=$1
    hlp[$a]=$2
    def[$a]=$3
}

function run {
    ## run the question que. Default answer is no, y is the only other option
    ## y-answered question are added to the executation que
    echo ''
    echo ${hlp[h]}

    key=
    echo -n $1"? " | tr '_' ' '

    default_key=${def[h]:0:1}
    default_str="y/N"

    if [[ $default_key == y* ]]; then
      default_str="Y/n"
    else
      default_str="y/N"
    fi

    read -s -r -p " [$default_str] " -n 1 -i "y" key

    ## Check for default action
    if [ ${#key} -eq 0 ]; then
     ## Enter was hit"
     key=$default_key
    fi

    ## Makre it an ordenary string
    if [[ $key == y ]]; then
     key="yes"
    else
     key="no";
    fi

    echo $key

    ## Que the action if yes
    if [[ $key == y* ]]; then
      echo $1 >> $LOG
      (( n++ ))
      que[$n]=$1 
    fi
}

function bak {
    ## create a backup of the file, with the same name, same location .bak extension
    ## filename=$1
    echo $MSG >> $1.bak
    cat $1 >> $1.bak
    echo $1" has a .bak file"
}

function set_file {
    ## cerate a file with the content overwriting everything
    ## filename=$1 content=$2

    if [ -f $1 ];
     then bak $1
    fi
    echo "creating "$1
    echo "$2" > $1
}

function sed_file {
    ## used to replace a line in a file
    ## filename=$1 oldline=$2 newline=$3
    bak $1
    cat $1 > $1.tmp
    sed "s|$2|$3|" $1.tmp > $1
    rm $1.tmp
}

function add_conf {
    ## check if the content string is present, and add if necessery. Single-line content only.
    ## filename=$1 content=$2

    if [ -f $1 ];
     then bak $1
    fi

    if grep -q "$2" $1; then
     echo $1" already has "$2
    else
     echo "adding "$2
     echo "$2" >> $1
    fi
}


function finalize {
## run the que's, and do the job's. This is the main function.
  echo "=== Confirmation for ${#asq[*]} commands. [Ctrl-C to abort] ==="
  for item in ${asq[*]}
  do
    (( h++ ))
    run $item #?
  done

  echo "=== Running the Que of ${#que[*]} commands. ==="
  for item in ${que[*]}
  do
    echo "== "$item" started! =="
    echo $item]
    $item
    echo "== "$item" finished =="
  done

  echo "=== Post-processing tasks ===";
  for item in ${que[*]}
  do
    if [ "$item" == "install_and_finetune_gnome_desktop" ] 
    then
     # run this graphical tool at the end
     if [ -z "$USR" ]; then echo "No user to tune gnome, skipping question." >> $LOG; else
        echo "Starting the gnome Tweak tool."
        su $USR -c gnome-tweak-tool
     fi
    fi 
  done
  echo "Finished. "$MSG >> $LOG
}

## NOTE: question / function should be consistent

question create_a_local_backup 'A local backcup of the /home and /etc folders could be created in '$TMP', just in case it might come handy.' yes
function create_a_local_backup {
echo Creating a backup copy of /home and /etc to $TMP .. might take a while.
    rsync -av /home $TMP >> $LOG
    rsync -av /etc $TMP >> $LOG
}

question add_rpmfusion 'The rpmfusion repo contains most of the packages that are needed on a proper workstation, to use proprietary software such as mp3 codecs. Recommended on a workstation.' yes
function add_rpmfusion {
    yum -y install --nogpgcheck http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}


question update 'Run a yum update to update all packages?' yes
function update {
    yum -y update
}

question enable_ssh 'Enable the ssh service, and let users log in via shell.' no
function enable_ssh {
    yum -y install fail2ban
    systemctl start fail2ban.service
    systemctl enable sshd.service
    systemctl start sshd.service
}

question limit_bash_history_to_specific_commands 'By default users can use the up and down arrow keys to see their command history. This can be replaced by a set of commands used frequently.' no
function limit_bash_history_to_specific_commands {

    bash_history_path="/home/$USR/.bash_history"
    bash_profile_path="/home/$USR/.bash_profile"
    

    if [ -z "$USR" ]; then
     bash_history_path="/root/.bash_history"
     bash_profile_path="/root/.bash_profile" 
    fi

    add_conf $bash_profile_path 'HISTFILE=/dev/null'

    ## The bash history will be limited to these commands
    echo  'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -L 5901:localhost:5901 -N -f -l 
vinagre localhost:1
sudo mc' > $bash_history_path

    chmod 644 $bash_history_path
}



if [ -z "$USR" ]; then echo "No user to tune gnome, skipping question." >> $LOG; else
question install_and_finetune_gnome_desktop 'Gnome is the default Desktop enviroment, but you might run another spin. It has some options for customization.' yes
fi
function install_and_finetune_gnome_desktop {

    yum -y install @GNOME
    yum -y install gnome-tweak-tool dconf-editor 
    yum -y install wget #ImageMagick

## terminal
echo "Terminal colors dont use system theme"
su $USR -c "dbus-launch gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:"$(gsettings get org.gnome.Terminal.ProfilesList default | head -c -2 | tail -c +2)"/ use-theme-colors false"

## gedit
su $USR -c "dbus-launch gsettings set org.gnome.gedit.preferences.editor scheme cobalt"
su $USR -c "dbus-launch gsettings set org.gnome.gedit.preferences.editor display-line-numbers true"

## get some music

set_file /home/$USR/Music/groovesalad.pls "[playlist]
numberofentries=4
File1=http://uwstream1.somafm.com:80
Title1=SomaFM: Groove Salad (#1 128k mp3): A nicely chilled plate of ambient/downtempo beats and grooves.
Length1=-1
File2=http://sfstream1.somafm.com:8032
Title2=SomaFM: Groove Salad (#2 128k mp3): A nicely chilled plate of ambient/downtempo beats and grooves.
Length2=-1
File3=http://uwstream2.somafm.com:8032
Title3=SomaFM: Groove Salad (#3 128k mp3): A nicely chilled plate of ambient/downtempo beats and grooves.
Length3=-1
File4=http://ice.somafm.com/groovesalad
Title4=SomaFM: Groove Salad (Firewall-friendly 128k mp3) A nicely chilled plate of ambient/downtempo beats and grooves.
Length4=-1
Version=2
"
chown $USR:$USR /home/$USR/Music/groovesalad.pls

## Add some wallpapers

mkdir /home/$USR/Pictures
cd /home/$USR/Pictures

## CC Photo Desktop Wallpapers

wget -nc http://fc05.deviantart.net/fs50/f/2009/339/0/4/Frozen_Heart____Still_Burning_by_D250Laboratories.jpg
wget -nc http://fc06.deviantart.net/fs32/f/2008/233/1/8/Broken_Glass_by_D250Laboratories.jpg
wget -nc http://fc06.deviantart.net/fs32/f/2008/232/1/c/Corn__by_D250Laboratories.jpg
wget -nc http://fc06.deviantart.net/fs31/f/2008/232/2/a/Butterfly_by_D250Laboratories.jpg
wget -nc http://fc00.deviantart.net/fs31/f/2008/230/2/9/Clublife_by_D250Laboratories.jpg
wget -nc http://fc04.deviantart.net/fs31/f/2008/230/3/5/Danceing_Girl_by_D250Laboratories.jpg
wget -nc http://fc08.deviantart.net/fs32/f/2008/233/6/f/Weed_1_of_4_by_D250Laboratories.jpg
wget -nc http://fc07.deviantart.net/fs44/f/2009/124/b/3/MicroEye_by_D250Laboratories.jpg
wget -nc http://fc07.deviantart.net/fs70/f/2009/358/d/6/Merry_Christmas_by_D250Laboratories.jpg
wget -nc http://fc05.deviantart.net/fs32/f/2008/233/f/a/After_the_rain_by_D250Laboratories.jpg
wget -nc http://fc02.deviantart.net/fs36/f/2010/006/b/d/Dust_and_Scraches_by_D250Laboratories.jpg
wget -nc http://fc08.deviantart.net/fs31/f/2008/230/3/7/Leaves_of_the_forest__by_D250Laboratories.jpg

## If you want your backgrounds a bit darker
#mogrify -brightness-contrast -30x-20 *.jpg 

## Standard Destop Wallpapers

wget -nc http://desktopography.net/exhibition/2012/ride/2560x1440/download
wget -nc http://desktopography.net/exhibition/2011/polaus/2560x1440/download
wget -nc http://desktopography.net/exhibition/2010/magnus/2560x1440/download
wget -nc http://www.justinmaller.com/img/projects/wallpaper/WP_Pump-2560x1440_00000.jpg

## Feel free to add your pictures here, and you can recommend your favorites too.

chown -R $USR:$USR /home/$USR/Pictures 

su $USR -c "dbus-launch gsettings set org.gnome.desktop.background picture-uri file:////home/$USR/Pictures/Leaves_of_the_forest__by_D250Laboratories.jpg"

}



if [ -z "$USR" ]; then echo "No autologin question." >> $LOG; else
question set_autologin_for_first_user "User $USR can be enabled to be logged in automatically, without requesting a password when the system is started." no
fi
function set_autologin_for_first_user {

## for GDM 
set_file /etc/gdm/custom.conf '
# GDM configuration storage

[daemon]

AutomaticLoginEnable=True
AutomaticLogin='$USR'

[security]

[xdmcp]

[greeter]

[chooser]

[debug]

'

## for lightdm
set_file /etc/lightdm/lightdm.conf '
[LightDM]
minimum-vt=1
user-authority-in-system-dir=true

[SeatDefaults]
xserver-command=X -background none
greeter-session=lightdm-greeter
session-wrapper=/etc/X11/xinit/Xsession

autologin-in-background=true
autologin-user-timeout=0
autologin-user='$USR'

[XDMCPServer]

[VNCServer]

'

## for lxdm
    sed_file /etc/lxdm/lxdm.conf "# autologin=dgod" "autologin="$USR

} 


question install_basic_system_tools 'There are some basic tools in a proper workstation, such a system monitoring tools, or the Disks tool, exfat support, gkrellm, filezilla, extra vnc clients, brasero, zip, rar, ..' yes
function install_basic_system_tools {
    yum -y install mc yumex yum-plugin-fastestmirror 
    yum -y install gkrellm wget 
    yum -y install gparted 
    yum -y install exfat-utils fuse-exfat 
    yum -y install gnome-disk-utility gnome-system-monitor
    yum -y install unrar p7zip p7zip-plugins 
    yum -y install filezilla 
    yum -y install remmina remmina-plugins-vnc 
    yum -y install brasero
    yum -y install system-config-users
    yum -y install tigervnc-server
}


question install_browsers "Google chrome, Flash player, java support is also part of a a proper desktop workstation, even though its propreitary software." yes
function install_browsers {
    # flash player
    yum -y install http://linuxdownload.adobe.com/adobe-release/adobe-release-i386-1.0-1.noarch.rpm  http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux
    yum -y update
    yum -y install flash-plugin nspluginwrapper alsa-plugins-pulseaudio libcurl

    #install google chrome repository
    set_file /etc/yum.repos.d/google-chrome.repo '[google-chrome]
name=google-chrome - 32-bit
baseurl=http://dl.google.com/linux/chrome/rpm/stable/i386
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub

[google-chrome]
name=google-chrome - 64-bit
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
'
    yum -y install google-chrome-stable firefox midori java java-plugin

    ## install Oracle java - TODO: fix!


    cd $TMP
    MACHINE_TYPE=`uname -m`

    header="Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie"   

    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
      # 64-bit system

	#url="http://download.oracle.com/otn-pub/java/jdk/7u51-b13/jre-7u51-linux-x64.rpm"
	#url="http://download.oracle.com/otn-pub/java/jdk/7u60-b19/jdk-7u60-linux-x64.rpm"
	#url="http://download.oracle.com/otn-pub/java/jdk/8u5-b13/jre-8u5-linux-x64.rpm"

	## If you insist on oracle-download ..
        # wget -nc --no-cookies --no-check-certificate --header $header  $url

	## I assume you are OK, with a mirror. You agree to everything.
	url="http://d250.hu/scripts/mirrored/jre-8u5-linux-x64.rpm"
	wget $url

      yum -y install jre-8u5-linux-x64.rpm
    else
      # 32-bit system

	#url="http://download.oracle.com/otn-pub/java/jdk/7u51-b13/jre-7u51-linux-i586.rpm"
	#url="http://download.oracle.com/otn-pub/java/jdk/7u60-b19/jdk-7u60-linux-i586.rpm"
	#url="http://download.oracle.com/otn-pub/java/jdk/8u5-b13/jre-8u5-linux-i586.rpm"


	## If you insist on oracle-download ...
	## wget -nc --no-cookies --no-check-certificate --header $header $url

	## I assume you are OK, with a mirror. You agree to everything.
	url="http://d250.hu/scripts/mirrored/jre-8u5-linux-i586.rpm"
	wget $url
      
      yum -y install jre-8u5-linux-i586.rpm
    fi

    ## note,  /usr/java/latest has bin, lib, plugin, man folders, and some files. Difference in 7u51 and 7u60 as it seems. So watch out for OUTDATED stuff.
    ## java ## 7u51 
    #alternatives --install /usr/bin/java java /usr/java/latest/jre/bin/java 20000
    ## javaws ## 7u51
    #alternatives --install /usr/bin/javaws javaws /usr/java/latest/jre/bin/javaws 20000

    ## Java Browser (Mozilla) Plugin 32-bit ## 7u51
    #alternatives --install /usr/lib/mozilla/plugins/libjavaplugin.so libjavaplugin.so /usr/java/latest/jre/lib/i386/libnpjp2.so 20000

    ## Java Browser (Mozilla) Plugin 64-bit ## 7u51
    #alternatives --install /usr/lib64/mozilla/plugins/libjavaplugin.so libjavaplugin.so.x86_64 /usr/java/latest/jre/lib/amd64/libnpjp2.so 20000


    ## java ##
    alternatives --install /usr/bin/java java /usr/java/latest/bin/java 20000
    ## javaws ## 
    alternatives --install /usr/bin/javaws javaws /usr/java/latest/bin/javaws 20000

    ## Java Browser (Mozilla) Plugin 32-bit ## 
    alternatives --install /usr/lib/mozilla/plugins/libjavaplugin.so libjavaplugin.so /usr/java/latest/lib/i386/libnpjp2.so 20000

    ## Java Browser (Mozilla) Plugin 64-bit ## 
    alternatives --install /usr/lib64/mozilla/plugins/libjavaplugin.so libjavaplugin.so.x86_64 /usr/java/latest/lib/amd64/libnpjp2.so 20000



    mkdir /opt/google/chrome/plugins
    cd /opt/google/chrome/plugins

    if [ -f /usr/java/latest/lib/amd64/libnpjp2.so ];
    then
     ln -s /usr/java/latest/lib/amd64/libnpjp2.so .
    fi

    if [ -f /usr/java/latest/lib/i386/libnpjp2.so ];
    then
     ln -s /usr/java/latest/lib/i386/libnpjp2.so .
    fi



}

question install_alternative_lightweight_desktops "Lightweight desktops with some traditional look might come handy on a less powerful computer. XFCE and LXDE are such Desktop enviroments." no
function install_alternative_lightweight_desktops {
    yum -y install @XFCE
    yum -y install @LXDE
}


question install_office "Libre office is a proper Office suite, and this will install also the Community version of Kingsoft Wps-Office, a MS office clone with high compatibilty to the MS formats." yes
function install_office {

    ## LibreOffice 
    yum -y groupinstall "Office"
    yum -y install libreoffice-writer libreoffice-calc libreoffice-langpack-de libreoffice-langpack-hu
    yum -y install dia dia-Digital dia-electronic 
    yum -y install scribus

    ## Kingsoft Office
    ## The original
    # kingsoft=http://`curl http://wps-community.org/download.html | grep -Po '^.*?\K(?<=http://).*?(?=.rpm)' | grep -m 1 download`.rpm

    ## Mirrors
    kingsoft=http://d250.hu/scripts/mirrored/kingsoft-office-9.1.0.4280-0.1.a12p4.i686.rpm
    #http://37.247.55.101/a12p4/kingsoft-office-9.1.0.4280-0.1.a12p4.i686.rpm

    mkdir -p $TMP/kingsoft-office
    cd $TMP/kingsoft-office
    wget -nc $kingsoft
    yum -y install $(ls -atr | grep -m 1 '')

}

question install_graphics_tools "Inkscape is powerful vector graphic editor. Darktable can process RAW photos. Gimp is a GNU Image manipulation progran. Blender is for 3D, Dia is a diagram editor." yes
function install_graphics_tools {

    yum -y install gimp 
    yum -y install darktable 
    yum -y install inkscape 
    yum -y install dia 
    yum -y install blender
    #yum -y install gimp-data-extras gimpfx-foundry gimp-lqr-plugin gimp-resynthesizer gnome-xcf-thumbnailer phatch nautilus-phatch

}

question install_media_players "Amarok is a cool media player, and VLC has also some unique features. Mixxx is for Dj's." yes
function install_media_players {

    yum -y install vlc vlc-plugin-jack 
    yum -y install amarok
    yum -y install mixxx

}

question install_media_editors "Edit videos with Kdenlive, sound files with Audacity, compose soundtracks with Ardour,.. " no
function install_media_editors {

    yum -y install kdenlive 
    yum -y install audacity-freeworld 
    yum -y install ardour3
    yum -y install qjackctl a2jmidid alsa-tools ffado alsa-plugins-jack jack-audio-connection-kit-dbus vlc-plugin-jack pulseaudio-module-jack

}



question install_dropbox "Dropbox is a popular file sharing service." no
function install_dropbox {

    #yum -y install caja-dropbox 
    yum -y install nautilus-dropbox

}

question install_chattools "Mumble is a useful free VOIP program, pidgin is a multiprotocol chat client." yes
function install_chattools {

    yum -y install pidgin 
    yum -y install mumble 

}


question install_skype "Skype is bought by MS, however a lot of people use it, and it might be need to stay connected. Currently, the installation process will ask for the root password." no
function install_skype {
    ## TODO: fix so no questions pop up
    ## Quickfix. Currently DISPLAY='' is required to not to use a gui.
	
    ### TODO:  http://www.skype.com/hu/download-skype/skype-for-linux/downloading/?type=fedora32

cd $TMP

wget -nc http://download.skype.com/linux/skype-4.2.0.11-fedora.i586.rpm
yum -y install skype-4.2.0.11-fedora.i586.rpm

    ## If you want to compile from source, ...
    #DISPLAYBAK=$DISPLAY
    #DISPLAY=''
    #yum -y install lpf-skype
    #lpf build skype
    #lpf install skype
    #DISPLAY=$DISPLAYBAK
}
question install_devtools "Software development tools are for programmers and hackers. " no
function install_devtools {

    ## TODO make it more complete

    # The generic Development tools compilation from fedora.
    yum -y groupinstall "Development Tools"

    # some more enviroments
    yum -y install netbeans
    yum -y install eclipse
    yum -y install geany
    yum -y install cssed
    yum -y install anjuta

    # Networking development
    yum -y install wireshark

    # some tools for ruby programming
    yum -y install rubygem-sinatra rubygem-shotgun rubygem-rails rubygem-passenger

    # For local web development. Apache and stuff.
    yum -y install httpd 
    yum -y install phpMyAdmin 
    yum -y install nginx 
    yum -y install nodejs
    yum -y install npm

    ## System development
    set_file /etc/yum.repos.d/webmin.repo  '[Webmin]
name=Webmin Distribution Neutral
#baseurl=http://download.webmin.com/download/yum
mirrorlist=http://download.webmin.com/download/yum/mirrorlist
enabled=1'

	cd $TMP
	wget http://www.webmin.com/jcameron-key.asc
	rpm --import jcameron-key.asc

    yum -y install webmin
}


question disable_selinux "SElinux enhances secutrity by default, but sometimes hard to understand error messages waste your time, especially when selinux is preventing a hack." no
function disable_selinux { 

sed_file /etc/selinux/config "SELINUX=enforcing" "SELINUX=disabled"

}

### Check for NVidia card
if [[ -n $( lspci | grep -E "VGA" | grep "NVIDIA" ) ]]; then
    echo "NVidia Hardware detected." >> $LOG
    ## Yes, the hardware is nvidia .. 
    if [[ -n $( glxinfo | grep "server glx vendor string: NVIDIA Corporation" ) ]]; then
    echo "NVidia Driver already installed." >> $LOG
    else
     question install_nvidia_driver "Install the propietary nVidia graphic driver, and replace the opensurce driver. This installs the akmod package for more recent cards." no
    fi
else
echo "Unknkown VGA driver" >> $LOG
fi

function install_nvidia_driver {

    ## just to make sure 
    add_rpmfusion 

    update_test=$(sudo yum update kernel\* selinux-policy\* | grep "No packages")

    if [ "$update_test" = "No packages marked for update" ]
    then

    ## TODO check for older hardware that need: yum -y install akmod-nvidia-173xx xorg-x11-drv-nvidia-173xx-libs.i686
    yum -y install kernel-devel akmod-nvidia xorg-x11-drv-nvidia-libs.i686

    else
    # update test failed, a package had to be update
    echo "!!REBOOT REQUIRED DUE TO KERNEL UPDATE!! REBOOT AND START OVER TO CONTINIUE INSTALLATION!!"
    echo "!!REBOOT REQUIRED DUE TO KERNEL UPDATE!! REBOOT AND START OVER TO CONTINIUE INSTALLATION!!" >> $LOG

    fi

    # nVidia driver installed
    echo "reboot required to activate driver after installation"
    echo "reboot required to activate driver after installation" >> $LOG

}

## Finalize will do the job!
finalize
exit
