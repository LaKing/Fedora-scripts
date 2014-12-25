#!/bin/bash
# Last update:2014.02.17-09:21:43
# version 0.6.6
#
# Installer script for Fedora
#
# D250 Laboratories / D250.hu
# Author: István király
# LaKing@D250.hu
#
# Please read all licencses in advance. I assume that you have read all license agreements, and you agree.
#
# Finetune this script by checking the functions.
# Comment / uncomment / alter constants.
#
## download, update with:
# curl http://d250.hu/scripts/install-ep_codepad.sh > install.sh 
## run with bash 
# && bash install.sh
#
## Source URL
URL="http://d250.hu/scripts/install-ep_codepad.sh"
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

## any enemy in sight? :)
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

if [ "$UID" -ne "0" ]
then
  echo "Root privileges needed to run this script. Trying with sudo."
  ## Attemt to get root privileges with sudo, and run the script
  sudo bash $0 $USR
  exit
fi
## user is root or runs on root privileges, continiue.


## Author info
# echo "István Király - D250 Laboratories. LaKing@D250.hu"

## Version info
if [[ $(cat /etc/fedora-release) == "Fedora release 20 (Heisenbug)" ]]
then
    echo "This is the labpad installer for Fedora 20."
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
##url_response=$(curl --write-out %{http_code} --silent --output $TMP/install-ep_codepad-latest.sh http://d250.hu/scripts/install-ep_codepad.sh)
url_response=0
if [ "$url_response" -ne "200" ]
then
   echo "Failed to download latest version of this script." >> $LOG
else
   echo "checking: "$0" against "$URL >> $LOG
   if  diff  $TMP/install-ep_codepad-latest.sh $0 >> $LOG
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
     bash install-ep_codepad-latest.sh
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
    ## check if the content string is present, and add if necessery
    ## filename=$1 content=$2

    if [ -f $1 ];
     then bak $1
    fi

    if grep -q $2 "$1"; then
     echo "adding "$1
     echo "$2" > $1
    else
     echo $1" already has "$1
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
    $item
    echo "== "$item" finished =="
  done

  echo "Finished. "$MSG >> $LOG
}

## NOTE: question / function should be consistent

#question create_a_local_backup 'A local backcup of the /home and /etc folders could be created in '$TMP', just in case it might come handy.' yes
function create_a_local_backup {
echo Creating a backup copy of /home and /etc to $TMP .. might take a while.
    rsync -av /home $TMP >> $LOG
    rsync -av /etc $TMP >> $LOG
}



question install_devtools "Software development tools for nodejs. " no
function install_devtools {

    yum -y install nodejs
    yum -y install npm
    yum -y install gzip git-core curl python openssl-devel
    yum -y install postgresql-devel
    yum -y install mc
}

question cleanup_etherpad "delete etherpad files" no
function cleanup_etherpad {

    rm -r -f etherpad-lite
    ls -l
}

question install_etherpad "The Original Etherpad. " no
function install_etherpad {
    pwd
    echo "into home of user" $USR

    su $USR -c "git clone git://github.com/ether/etherpad-lite.git"
    cd etherpad-lite
    su $USR -c "git pull origin"

    #su $USR -c "cat settings.json.template >> settings.json"

}


question install_etherpad_plugins "Install plugins with verifyed functionality " no
function install_etherpad_plugins {

cd etherpad-lite

## So the main thing is, ...
su $USR -c 'npm install ep_codepad'

## cursortrace might come handy. As it does not need any finetuning, it is seperate plugin.
su $USR -c 'npm install ep_cursortrace'


## github authentication might come handy, but it does not work without setting the right parameters.
# su $USR -c 'npm install ep_github'

echo "ep_github needs all parameters set!"
su $USR -c echo '/* Github authentication
"users": {
    "github": {
        "appId": "Replace with you app id",
        "appSecret": "Replace with your app secret",
        "callback": "Replace with full url (including http) + /auth/github_callback: (http:\/\/localhost:9001/auth/github_callback)",
        "org": "Replace with your organisation"
    }
},
*/' 
# >> settings.json





## all plugins installed
cd ..

}


question patch_etherpad "Some fine source hack's and workarounds " no
function patch_etherpad {

## set admin user with a default password
set_file etherpad-lite/settings.json '/* ep_codepad-devel settings*/
{
  "ep_codepad": { 
    "project_path": "/tmp",
    "play_url": "http://www.d250.hu"
  },
  "title": "codepad-devel",
  "favicon": "favicon.ico",
  "ip": "0.0.0.0",
  "port" : 9001,
  "sessionKey" : "0123456789ABC",
  "dbType" : "dirty",
  "dbSettings" : {
                   "filename" : "var/dirty.db"
                 },
  "defaultPadText" : "Welcome to Etherpad-codepad!\n\nThis is a test.",
  "requireSession" : false,
  "editOnly" : false,
  "minify" : true,
  "maxAge" : 21600, 
  "abiword" : null,
  "requireAuthentication": false,
  "requireAuthorization": false,
  "trustProxy": false,
  "disableIPlogging": false,  
  "users": {"admin": {"password": "xxxxxx","is_admin": true},"user": {"password": "xxx","is_admin": false}},
  "socketTransportProtocols" : ["xhr-polling", "jsonp-polling", "htmlfile"],
  "loglevel": "INFO",
  "logconfig" :
    { "appenders": [
        { "type": "console"}
      ]
    }
}'

chown $USR:$USR etherpad-lite/settings.json

## increase import filesize limitation
sed_file etherpad-lite/src/node/db/PadManager.js '    if(text.length > 100000)' '    if(text.length > 1000000) /* D250 Laboratories customization for file import via webAPI*/'

### The line containing:  return /^(g.[a-zA-Z0-9]{16}\$)?[^$]{1,50}$/.test(padId); .. but mysql is limited to 100 chars, so path it.
sed_file etherpad-lite/src/node/db/PadManager.js '{1,50}$/.test(padId);' '{1,100}$/.test(padId); /* D250 Laboratories customization for file import via webAPI*/'

## TODO patch pad.js from plugin dir

}


question run_etherpad "Run the original Etherpad" no
function run_etherpad {


    #su $USR -c "mcedit settings.json"
    echo "Attempt to run ./bin/run.sh - run it manually from the console"

    su $USR -c "gnome-terminal -e ./etherpad-lite/bin/run.sh"
    read -p "Press [Enter] to continiue - is etherpad is running..."
}





SRCFOLDER='etherpad-lite/node_modules/ep_codepad/static/js'
APIKEY=$(cat etherpad-lite/APIKEY.txt)
HOST=127.0.0.1:9001

## createpad filepath(name) content
function createpad {
    f=$1

    ## in this version / is referred as ___ 
    ## TODO work on urlencoding

    filepath=$(echo ${f:2} | sed 's|/|___|g')
    url='http://127.0.0.1:9001/api/1/createPad'
    #curl -d "apikey=$APIKEY&padID=$filepath&text=$(cat $f)"  $url
    #curl -d "apikey=$APIKEY" -d "padID=$filepath" -d --data-urlencode "text=$(cat $f)"  $url

    curl -d "apikey=$APIKEY" --data-urlencode "padID=${f:2}" --data-urlencode "text=$(cat $f)"  $url

    echo ' '$f
}

question import_src "Import files from "$SRCFOLDER yes
function import_src {

    echo 'Importing files, padID requirements: 100 chars.'
    echo "APIKEY: "$APIKEY
    cd $SRCFOLDER

    for f in $(find .)
    do
    #echo "Processing $f file..."
    # take action on each file. $f store current file name
     if [ -e $f ] 
     then

     ## Process file depending on extension


        if [[ $f == *.json ]]
         then
            createpad $f
         fi

        if [[ $f == *.md ]]
         then
            createpad $f
         fi


        if [[ $f == *.txt ]]
         then
            createpad $f
         fi

        if [[ $f == *.js ]]
         then
            createpad $f
         fi

        if [[ $f == *.rb ]]
         then
            createpad $f
         fi

        if [[ $f == *.css ]]
         then
            createpad $f
         fi

    fi
    done

} # end of import_src


## Finalize will do the job!
finalize
exit
