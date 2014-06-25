#!/bin/bash

U="colorsound"
H="r2.d250.hu"

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
    echo "LELE"
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
