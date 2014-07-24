#!/bin/bash
## install as follows:

## curl https://raw.githubusercontent.com/LaKing/Fedora-scripts/master/srvctl-client.sh > srvctl-client.sh && chmod +x srvctl-client.sh

## The version of this file should 
## - be consistent with srvctl
## - running on any Linux distribution
## - running on OsX
## - running on windows git bash - http://msysgit.github.io/ 

## lets start ... 
CWD=$(pwd)

## source or set here as default
U=$(whoami)
H="r2.d250.hu" ## customize here if you wish


if [ -f srvctl-user ]
then
	source srvctl-user
else
	## TODO add line-break for windos
	echo 'U='$U >> srvctl-user
	echo 'H=r2.d250.hu' >> srvctl-user
fi

## check for update of this script

if [ "$1" == "update" ]
then
	echo "Downloading latest version, ..."
	curl https://raw.githubusercontent.com/LaKing/Fedora-scripts/master/srvctl-client.sh > srvctl-client.tmp

	cat srvctl-client.tmp > srvctl-client.sh 
	chmod +x srvctl-client.sh
	rm -f srvctl-client.tmp

	echo "Script updated. Please restart this script."
	exit
fi

echo "OK - STARTED"


NOW=$(date +%Y.%m.%d-%H:%M:%S)

## create keypair if necessery
if [ -f ~/.ssh/id_rsa ] 
then
	echo "OK - ID rsa exists."
else
	echo  "NO ID rsa, create key as $USER@$HOSTNAME ..."
	mkdir -p ~/.ssh
	ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N '' -C "$USER@$HOSTNAME $NOW"
fi

## check for existence of id_rsa
if [ -f ~/.ssh/id_rsa.pub ]
then
	echo "OK - public key exists."
else
	echo "ERR. No public key! Exiting."
	exit
fi

## add host-key to known_hosts
hosthash=$(ssh-keyscan -t rsa -H $H 2> /dev/null)
touch ~/.ssh/known_hosts

if grep -q "${hosthash:68}" ~/.ssh/known_hosts
then
	echo "OK - Host $H is known."
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
	echo "OK - SSH connected."
fi

## Create client local folder 
if [ -d ~/$H ]
then
	echo "OK - Local $H folder exists."
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
		echo "OK - Method rsync available."
		rsync_avail=true
	fi
fi

## test if git is available
git_avail=false
test_client=$(git --version 2> /dev/null | grep version)
if [ ! -z "$test_client" ]
then
	## this is not really necessery, but we should do it right.
	test_server=$(ssh $U@$H "git --version 2> /dev/null | grep version")
	if [ ! -z "$test_server" ]
	then
		echo "OK - Method git available."
		git_avail=true
	fi
fi


if $rsync_avail || $git_avail
then
	if [ -z "$1" ]
	then
	    echo "OK -  interactive mode!" 
	fi
	
else
	echo "STOP - no syncronisation methods. Install git and/or rsync"
	exit
fi




function comment {

upload=false
## ask user what to do or go with the arguments
if [ -z "$1" ]
then

    echo "Upload, or Download? .."
    read -s -r -p "[Up/Down] " -n 1 key
    if [[ $key == u ]]; then
	echo "!!  UPLOAD !!"
	upload=true
    else
        echo "!!  DOWNLOAD !!"
    fi
else
    key=$1
fi


use_git=false
## ask user what to do or go with the arguments
if [ -z "$1" ] && $git_avail
then
    echo "Use git or rsync: .."
    read -s -r -p "[Git/Rsync] " -n 1 key
    if [[ $key == g ]]; then
	echo "!!  USE GIT !!"
	use_git=true
    else
        echo "!!  RSYNC !!"
    fi
else
    key=$1
fi

}




echo "Processing container-shares."


function process_folder {
	#echo -e " --- "$F

	has_git=false
	options='Skip'

	if $git_avail
	then
		# check for remote repository
		#git_status=$(ssh $U@$H 'cd /home/'$U'/'$D'/'$F' && git status 2&>1 1> /dev/null && echo $?')
		git_status=$(ssh $U@$H 'cd /home/'$U'/'$D'/'$F'/.git 2> /dev/null && echo $?')
		#echo " --- "$F" git: "$git_status
		if [ "$git_status" == "0" ]
		then
			echo "HAS GIT repo"
			has_git=true

			options=$options"/Clone"

			if [ -d ~/$H/$D/$F/.git ]
			then
				options=$options"-pull/Push"
			fi

		else
			options=$options"/Init"
		fi
		

	fi


	if $rsync_avail
	then
		options=$options"/Download/Upload"
	fi

	read -s -r -p " --- $F [$options] " -n 1 key
	echo '... '$key	

	if [ ! -z "$key" ]
	then

	if $git_avail && ! $has_git
	then
		if [ "$key" == i ] || [ "$key" == I ]
		then
			ssh $U@$H 'cd /home/'$U'/'$D'/'$F'/ && git init && git add . && git commit -m '$U@$(hostname)

			## and then clone
			key=c
		fi		
	fi

	if $git_avail && $has_git
	then
		if [ "$key" == c ] || [ "$key" == C ]
		then
			if [ -d ~/$H/$D/$F/.git ]
			then
				ssh $U@$H 'cd /home/'$U'/'$D'/'$F'/ && git commit -a -m '$U@$(hostname)
				cd ~/$H/$D/$F			
				git pull  
			else
				mkdir -p ~/$H/$D/$F
				git clone $U@$H:$D/$F ~/$H/$D/$F
			fi
		fi

		if [ "$key" == p ] || [ "$key" == P ]
		then
			if [ -d ~/$H/$D/$F/.git ]
			then
				cd  ~/$H/$D/$F 
				git commit -a -m $U@$(hostname)
				#git remote add origin $U@$H:$D/$F
				git push master
			fi
		fi	
	fi

	if $rsync_avail
	then
		if [ "$key" == d ] || [ "$key" == D ]
		then
			echo 'Downloading '$F
    			rsync -chavzP --stats $U@$H:$D/$F ~/$H/$D
			echo '... ready'
		fi

		if [ "$key" == u ] || [ "$key" == U ]
		then
			echo 'Uploading '$F
    			rsync -chavzP --stats ~/$D/$F $U@$H:~/$D
			echo '... ready'
		fi
	fi

	fi
}

## list domains on server
for D in $(ssh -q $U@$H ls) 
do
	## if the directory contains a dot, then its most likely a container
	if [[ $D == *.* ]]
	then
	  echo " - "$D
	  mkdir -p ~/$H/$D
	  for F in $(ssh -q $U@$H ls $D)
	  do
		process_folder
	  done
	fi
done



## here @ dev
exit



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

cd $CWD
echo "Done."
exit
