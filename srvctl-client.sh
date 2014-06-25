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
	echo "Friss verzió."
else
	cat srvctl-client.tmp > srvctl-client.sh && chmod +x srvctl-client.sh
	echo "A szkript frissítésére került sor, kérlek indítsd el ujra."
	exit
fi


echo "A szinkronizáció-varázsló elindult."

NOW=$(date +%Y.%m.%d-%H:%M:%S)

if [ -f ~/.ssh/id_rsa ] 
then
    echo "RSA ID - rendben, .."
    else
    echo  "Nincs rsa ID, kulcspár-generálás $USER@$HOSTNAME számára. ...pill."

    mkdir -p ~/.ssh
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N '' -C "$USER@$HOSTNAME $NOW"
fi

if [ -f ~/.ssh/id_rsa.pub ]
then
    echo ".. publikus kulcs van."
else
    echo "ERR. Nincs publikus kulcs!"
    exit
fi


hosthash=$(ssh-keyscan -t rsa -H $H )
touch ~/.ssh/known_hosts

if grep -q "${hosthash:68}" ~/.ssh/known_hosts
then
    echo "Ismert Host"
else
    echo "Host hashelés."
    echo $hosthash >> ~/.ssh/known_hosts
fi

ssh -q $U@$H exit
if [ "$?" == 255 ] 
then
    echo "ERR. Kapcsolódás sikertelen. $U@$H"
    echo "A publikus kulcs hozzáadása szükséges a $H kiszolgálón. A kulcs:"
    echo ""
    cat ~/.ssh/id_rsa.pub
    exit
else
    echo "SSH Kapcsolódás rendben."
fi

if [ -d ~/$H ]
then
    echo "A helyi $H mappa létezik."
else
    echo "Helyi ~/$H mappa létrehozása"
    mkdir -p ~/$H
fi

if [ -z "$1" ]
then
    echo "Feltöltés, vagy letöltés? .."
    read -s -r -p "[Fel/Le] " -n 1 key
    if [[ $key == f* ]]; then
	key="U"
	echo "!!  FELTÖLTÉS !!"
    else
        key="D";
        echo "!!  LETÖLTÉS !!"
    fi
else
    key=$1
fi

echo ""

if [ $key == "D" ]
then

    # sync down
    for D in $(ssh -q $U@$H ls)
    do
    echo "==== $D ===="
    ssh $U@$H "rsync -chavP root@$D:/var/www/html ~/$D"
    rsync -chavzP --stats $U@$H:$D ~/$H
    ssh $U@$H "rm -rf ~/$D/html"
    done

else

    ## sync up
    for D in ~/$H/*
    do
    echo "==== $D ===="
    ssh $U@$H "rsync -chavP root@$D:/var/www/html ~/$D"
    rsync -chavzP --stats $D $U@$H:~
    ssh $U@$H "ssh root@$D 'chown apache:apache ~/$D/html'"
    ssh $U@$H "rsync -chavP ~/$D/html root@$D:/var/www"
    ssh $U@$H "rm -rf ~/$D/html"
    done

fi

echo "kész."
exit
