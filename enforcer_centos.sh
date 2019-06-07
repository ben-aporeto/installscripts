#!/bin/bash
# =============================================================================
# apolinux_centos         Install for APOCTL and Enforcerd on CENTOS
#
#       Version:
#               1.00
#
#       Description:
#               The script will help automate the creation and setup
#               of appcreds as well as the enforcer agent as a linux
#               container. 
#
#       Usage:
#               enforcer_centos.sh (no args)
#
#
#       Logging and Log Maintenance:
#               Logs are kept via the path as indicated below
#
#
#       Change History:
#               
#               03/08/2019 -- Initial write
#                       - David Nester
#
#               04/04/2019 -- Added disable_userland modification
#                       - David Nester
#
#
#       Author:
#               David Nester, Aporeto
#
# =============================================================================


#
#       Variables
#
prog=`basename $0`
logdir="/tmp/REPORTS"
date=`date '+%Y%m%d'`
apoctl="/usr/local/bin/apoctl"
tmp="/tmp/.$prog.$$"
tmp2="/tmp/.$prog.$$.2"
osuf=".$prog.orig"
docker="/usr/bin/docker"
daemonjson="/etc/docker/daemon.json"
docker_compose="/usr/bin/docker-compose"
nsuf=".$prog.1"
log="/var/tmp/$prog.log.`date +%Y%m%d.%H%M%S`"
version="1.00"

PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/ucb"
export PATH


#
#       Functions.
#


die() {
        echo "$prog: FATAL: $1" 1>&2
        exit 1
}
warn() {
        echo "$prog: WARNING: $1" 1>&2
}
usage() {
        echo "usage: $prog [ no options yet ]" 1>&2
        exit 1
}
help() {
        awk '{if(NR>1)echo;if(NF==0)exit(0)}' < "$0"
}

#
#       Install apoctl
#

install_apoctl() {
        sudo curl -o /usr/local/bin/apoctl \
        https://download.aporeto.com/releases/release-3.7.0-r1/apoctl/linux/apoctl && \
        sudo chmod 755 /usr/local/bin/apoctl
}


#
#       installs enforcer as docker container
#

init_enforcer(){

	#
	#	Add repo and Grab package
	#

	echo -e "[Aporeto]\nname=aporeto\nbaseurl=https://repo.aporeto.com/centos/\$releasever/\ngpgkey=https://download.aporeto.com/aporeto-packages.gpg\ngpgcheck=1\nrepo_gpgcheck=1\nenabled=1\n" > /etc/yum.repos.d/Aporeto.repo

	#
	#	Grab enforcer
	#

	sudo yum install -y enforcerd

	#	Starting enforcerd

	sudo systemctl start enforcerd
	
	#
	#	End of enforcer function
	#
}


#
#	Disable docker userland proxy
#

disable_userland(){
	
	#
	#	check for daemon.json
	#
		
	if [ ! -f "$daemonjson" ] ; then 
		echo "$daemonjson does not exist.  Creating...."
		sudo mkdir -p /etc/docker/ && echo -e "{ \n \"userland-proxy\": false \n }"  >> $daemonjson
	else 
		echo "$daemonjson already there. Modifying..." 
		echo "Making a backup..."
		sudo cp $daemonjson $daemonjson.$date
		sed -i '/}/i \"userland-proxy\": false' $daemonjson
	fi
	
	#
	#	end of daemon.json
	#
}

#
#       update apt
#

aptget(){
        sudo apt-get update 2>&1
}

#
#       Signal Handling
#

trap 'echo "Dying on signal[1]: Hangup" ; exit 1' 1
trap 'echo "Dying on signal[2]: Interrupt" ; exit 2' 2
trap 'echo "Dying on signal[3]: Quit" ; exit 3' 3
trap 'echo "Dying on signal[4]: Illegal Instruction" ; exit 4' 4
trap 'echo "Dying on signal[6]: Abort" ; exit 6' 6
trap 'echo "Dying on signal[8]: Arithmetic Exception" ; exit 8' 8
trap 'echo "Dying on signal[9]: Killed" ; exit 9' 9
trap 'echo "Dying on signal[10]: Bus Error" ; exit 10' 10
trap 'echo "Dying on signal[11]: Segmentation Fault" ; exit 11' 11
trap 'echo "Dying on signal[12]: Bad System Call" ; exit 12' 12
trap 'echo "Dying on signal[13]: Broken Pipe" ; exit 13' 13
trap 'echo "Dying on signal[15]: Dying on signal" ; exit 15' 15
trap 'echo "Dying on signal[30]: CPU time limit exceeded" ; exit 30' 30
trap 'echo "Dying on signal[31]: File size limit exceeded" ; exit 31' 31

#
#       Prechecks.
#

if [ ! -x /usr/bin/awk ] ; then
        echo "$prog: SANITY: /usr/bin/awk missing!  Quitting..." 1>&2
        rm -f $tmp $tmp2
        exit 1
fi
awk="/usr/bin/awk"
ostype=`/bin/uname -a | $awk '{echo$1" "substr($3,1,1)}'`
if [ ! -x /usr/bin/id ] ; then
        echo "$prog: SANITY: /usr/bin/id missing!  Quitting..." 1>&2
        rm -f $tmp $tmp2
        exit 1
fi
if [ ! -x $docker ] ; then
        echo "$prog: SANITY: $docker missing!  Warning..." 1>&2
fi

#
#       Clean up old stuff.     
#

enforcer_required="
/var/lib/aporeto/
~/.apoctl/
"

for i in $enforcer_required ; do
        echo "Removing $i..."
        rm -Rf $i
done

#
#       handle CTRL-C
#


trap 'echo "" ; echo Killed | tee $log ; rm -f $tmp $tmp2 ; echo "" ; exit 2' 2

(

clear
echo ""
echo ""
echo "========================================================="
echo ""
echo "Aporeto Linux Enforcerd Installation for CENTOS"
echo "$prog $version"
echo "running on `/bin/hostname`"
echo "date:      `date`"
echo "log file:  $log"
echo ""
echo "========================================================="
echo ""
echo -n "Please enter Aporeto PARENT NAMESPACE, else CTRL-C to quit: "
        read myaccount
echo ""
echo -n "Please enter the Aporeto CHILD NAMESPACE.  If installing to PARENT NAMESPACE, leave empty: "
        read namespace
echo ""

#
#       Update Apt
#

echo ""
echo ""
echo ""
echo "Updating apt-get..."
aptget

#
#       Install APOCTL 
# 

echo "Installing apoctl..." 
install_apoctl 

# 
#       Auth token
#

echo "Getting aporeto token..."
APOCTL_TOK=`apoctl auth aporeto -e --validity 30m --account ${myaccount} | awk '/APOCTL_TOKEN/ {print substr($2,14)}'`
export APOCTL_TOKEN=$APOCTL_TOK 

#
#       Verify token.
#

echo "Verifying token..."
apoctl auth verify 

echo "Checking namespace list..."
apoctl api list namespaces -n /${myaccount}

#
#       Create files for auth
#


if [ -z "$namespace" ] ; then 
        mkdir -p ~/.apoctl && apoctl appcred create administrator-credentials \
                --role @auth:role=namespace.editor \
                -n /${myaccount} > ~/.apoctl/creds.json
else 
        mkdir -p ~/.apoctl && apoctl appcred create administrator-credentials \
                --role @auth:role=namespace.editor \
                -n /${myaccount}/${namespace} > ~/.apoctl/creds.json
fi

unset APOCTL_TOKEN
echo "creds: ~/.apoctl/creds.json" > ~/.apoctl/default.yaml

#
#       Write default.creds
#

mkdir -p /var/lib/aporeto/
apoctl appcred create enforcerd --role "@auth:role=enforcer" > /var/lib/aporeto/default.creds


#
#	Docker User-land 
#

echo -n "Please confirm to disable user-land proxy [yn]: "
	read userland

	case "$userland" 
	in
	[yY]*)
	disable_userland
	;;
	[nN]*)
	echo "Continuing..."
	;;
	*)	
	disable_userland
	;;
	esac


#
#       Install enforcerd
#

echo -n "Would you like to install enforcer? [yn]: "
	read enforceryn

	case "$enforceryn"
	in
	[yY]*)
	init_enforcer
	;;
	[nN]*)
	echo "Continuing..."
	;;
	*)	
	init_enforcer
	;;
	esac



#
#       Closing message
#

echo ""
echo "$prog run on `/bin/hostname` completed on `date`"
echo ""

) | tee $log

rm -f $tmp $tmp
exit 0

# =============================================================================
# END of apolinux_centos.sh
# =============================================================================
