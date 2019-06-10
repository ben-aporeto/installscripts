#!/bin/sh
# =============================================================================
# newss 	NEW Shell Script
#
#	Version:
#		1.00
#
#	Description:
#		For each name in $@, create a new executable file containing
#		empty head and tail comments, with name, as in this script.
#		If a name already exists, skip it.
#
#		If the filename begins with / , use that filename literally.
#		If there is no initial / , then place it into $defbin.
#
#		Skeletal help, usage, warn and die functions are created
#		automatically.  The help function causes the comment block
#		at the top of the script to be displayed through "more".
#
#	Primary Application:
#		Unix shell script development.  Create initial (empty)
#		script with standardized command header, to be edited
#		by programmer.
#
#	Usage:
#		newss scriptname [scriptname...]
#
#
#	Files:
#		Output script $defbin/scriptname
#
#
#	Author:
#		David Nester, Aporeto, May 2019
#
#
# =============================================================================


prog=`basename $0`
defbin=./bin

if [ $# -eq 0 ] ; then
	echo "usage: $prog scriptname [scriptname...]" 1>&2
	exit 1
fi

if [ "x$defbin" = x ] ; then
	echo "$prog: SANITY: defbin is not set" 1>&2
	exit 1
fi

for file in $@ ; do
	case "$file" 
	in
		/*)	
		;;
		*)	
		file="$defbin/$file" 
		;;
	esac
	if [ -f $file ] ; then
		echo "$prog: ERROR: $file already exists -- skipping" 1>&2
		continue
	fi
	cat /dev/null > $file
	if [ $? != 0 ] ; then
		echo "$prog: ERROR: can't create $file -- skipping" 1>&2
		continue
	fi
	sfn=`basename $file`
	cat << EOF > $file
#!/bin/sh
# =============================================================================
# $sfn		SHORT DESCRIPTION
#
#	Version:
#		1.00
#
#	Description:
#		LONG DESCRIPTION
#
#	Primary Application:
#		What do we mainly use this script for?
#
#	Usage:
#		$sfn [ARGS]
#
#	Error and Alert Notification:
#		How do we notify the user of error and alert conditions?
#
#	Logging and Log Maintenance:
#		Where are the logs (if any) ?  How do we manage, prune
#		and archive them (if applicable) ?
#
#	Files:
#		What config or other files are used by this script?
#		If required, default config file is $HOME/etc/$sfn.conf .
#
#	Remarks:
#		Various helpful comments
#
#	Suggested enhancements:
#		Features / performance we should add later
#
#	Change History:
#
#	Author:
#		$LOGNAME@`hostname` Aporeto `date '+%m/%d/%Y'`
#
# =============================================================================

prog=\`basename \$0\`
logdir="$HOME/REPORTS"
date=\`date '+%Y%m%d'\`

PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/ucb"
export PATH

#
#	Functions.
#


die () {
        echo "\$prog: FATAL: \$1" 1>&2
        exit 1
}
warn () {
        echo "\$prog: WARNING: \$1" 1>&2
}
usage () {
	echo "usage: \$prog [ options ]" 1>&2
	exit 1
}
help () {
	awk '{if(NR>1)print;if(NF==0)exit(0)}' < "\$0"
}


#
# 	Signal Handling
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
# 	Main.
#


echo "This is new shell script created by $prog."
echo "It has evidently not yet been edited."

help | \${PAGER-more}

(usage)

warn "testing the warn() function"
die "testing the die() function"


# =============================================================================
# END of $sfn
# =============================================================================
EOF
	if [ $? != 0 ] ; then
		echo "$prog: ERROR: couldn't create $file -- skipping" 1>&2
		continue
	fi
	chmod 750 $file
	if [ $? != 0 ] ; then
		echo "$prog: ERROR: can't set permissions on $file" 1>&2
		continue
	fi
	echo Created new shell script \"$file\"
done
exit 0

# =============================================================================
# END of newss
# =============================================================================
