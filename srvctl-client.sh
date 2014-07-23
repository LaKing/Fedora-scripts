#!/bin/bash
## install as follows:

## curl https://raw.githubusercontent.com/LaKing/Fedora-scripts/master/srvctl-client.sh > srvctl-client.sh && chmod +x srvctl-client.sh

## The version of this file should 
## - be consistent with srvctl
## - running on any Linux distribution
## - running on OsX
## - running on windows git bash - http://msysgit.github.io/ 

## lets start ... 

## source or set here as default
U=$(whoami)
H="r2.d250.hu" ## customize here if you wish

if [ -f srvctl-user ]
then
	source srvctl-user
else
	## TODO add line-break for windos
	echo 'U='$U >> srvctl-user
	echo 'H="r2.d250.hu"' >> srvctl-user
fi

## check for update of this script
curl https://raw.githubusercontent.com/LaKing/Fedora-scripts/master/srvctl-client.sh > srvctl-client.tmp

if diff srvctl-client.tmp $0 
then
	echo "This script seems to be up to date."
else
	cat srvctl-client.tmp > srvctl-client.sh 
	chmod +x srvctl-client.sh
	rm -f srvctl-client.tmp

	echo "Script updated. Please restart this script."
	exit
fi


echo "STARTED"

NOW=$(date +%Y.%m.%d-%H:%M:%S)

## create keypair if necessery
if [ -f ~/.ssh/id_rsa ] 
then
	echo "RSA ID - IS OK, .."
else
	echo  "NO ID rsa, create key as $USER@$HOSTNAME ..."
	mkdir -p ~/.ssh
	ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N '' -C "$USER@$HOSTNAME $NOW"
fi

## check for existence of id_rsa
if [ -f ~/.ssh/id_rsa.pub ]
then
	echo ".. public key ok."
else
	echo "ERR. No public key!"
	exit
fi

## add host-key to known_hosts
hosthash=$(ssh-keyscan -t rsa -H $H )
touch ~/.ssh/known_hosts

if grep -q "${hosthash:68}" ~/.ssh/known_hosts
then
	echo "Host is known."
else
	echo "Saving host-key."
	echo $hosthash >> ~/.ssh/known_hosts
fi

## test connectivity
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

## Create client local folder 
if [ -d ~/$H ]
then
	echo "Local $H folder exists."
else
	echo "Createing local ~/$H folder."
	mkdir -p ~/$H
fi

## from here, use git or rsync

## test if rsync is available
rsync_avail=false
test_client=$(rsync --version 2> /dev/null | grep version)
if [ ! -z "$test_client" ]
then
	## this is not really necessery, but we should do it right.
	test_server=$(ssh $U@$H "rsync --version 2> /dev/null | grep version")
	if [ ! -z "$test_server" ]
	then
		echo "Method rsync available."
		rsync_avail=true
	else
		echo "Method rsync not available."
	fi
fi

## test if git is available
rsync_avail=false
test_client=$(git --version 2> /dev/null | grep version)
if [ ! -z "$test_client" ]
then
	## this is not really necessery, but we should do it right.
	test_server=$(ssh $U@$H "git --version 2> /dev/null | grep version")
	if [ ! -z "$test_server" ]
	then
		echo "Method git available."
		rsync_avail=true
	else
		echo "Method git not available."
	fi
fi

## here @ dev
exit

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

echo "Done."
exit
