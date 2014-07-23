#!/bin/bash
## install as follows:
## curl https://raw.githubusercontent.com/LaKing/Fedora-scripts/master/srvctl-client.sh > srvctl-client.sh && chmod +x srvctl-client.sh

## source or set here as default
U=$(whoami)
H="r2.d250.hu" ## customize here

if [ -f srvctl-user ]
then
	source srvctl-user
else
	echo 'U='$U >> srvctl-user
	echo 'H="r2.d250.hu"' >> srvctl-user
fi

## check for update of this script
curl https://raw.githubusercontent.com/LaKing/Fedora-scripts/master/srvctl-client.sh > srvctl-client.tmp

if diff srvctl-client.tmp $0 
then
	echo "This script seems to be up to date."
else
	cat srvctl-client.tmp > srvctl-client.sh && chmod +x srvctl-client.sh
	echo "Script updated. Please restart this script."
	exit
fi


echo "STARTED"

NOW=$(date +%Y.%m.%d-%H:%M:%S)

if [ -f ~/.ssh/id_rsa ] 
then
    echo "RSA ID - IS OK, .."
    else
    echo  "NO ID rsa, create key as $USER@$HOSTNAME ..."

    mkdir -p ~/.ssh
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N '' -C "$USER@$HOSTNAME $NOW"
fi

if [ -f ~/.ssh/id_rsa.pub ]
then
    echo ".. public key ok."
else
    echo "ERR. No public key!"
    exit
fi


hosthash=$(ssh-keyscan -t rsa -H $H )
touch ~/.ssh/known_hosts

if grep -q "${hosthash:68}" ~/.ssh/known_hosts
then
    echo "Host is known."
else
    echo "Saving host-key."
    echo $hosthash >> ~/.ssh/known_hosts
fi

ssh -q $U@$H exit
if [ "$?" == 255 ] 
then
    echo "ERR. failed to connect. $U@$H"
    echo "A public key is needed for $H. Your public key is:"
    echo ""
    cat ~/.ssh/id_rsa.pub
    exit
else
    echo "SSH connection OK."
fi

if [ -d ~/$H ]
then
    echo "Local $H folder exists."
else
    echo "Createing local ~/$H folder."
    mkdir -p ~/$H
fi

## from here, use git or rsync

if [ -z "$1" ]
then
    echo "Upload, or Download? .."
    read -s -r -p "[Up/Down] " -n 1 key
    if [[ $key == f* ]]; then
	key="rsync-upload"
	echo "!!  UPLOAD !!"
    else
        key="rsync-download";
        echo "!!  DOWNLOAD !!"
    fi
else
    key=$1
fi

echo ""

if [ $key == "rsync-upload" ]
then

    # sync down
    for D in $(ssh -q $U@$H ls)
    do
    echo "==== $D ===="
    rsync -chavzP --stats $U@$H:$D ~/$H
    done

else

    ## sync up
    for D in ~/$H/*
    do
    echo "==== $D ===="

    rsync -chavzP --stats $D $U@$H:~

    #ssh $U@$H "ssh root@$D 'chown apache:apache ~/$D/html'"

    done

fi

echo "kész."
exit
