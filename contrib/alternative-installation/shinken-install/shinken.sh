#!/bin/bash  

# environnement
export myscripts=$(readlink -f $(dirname $0))
src=$(readlink -f "$myscripts/../../..")
. $myscripts/shinken.conf

function trap_handler()
{
        MYSELF="$0"               # equals to my script name
        LASTLINE="$1"            # argument 1: last line of error occurence
        LASTERR="$2"             # argument 2: error code of last command
        FUNCTION="$3"
        if [ -z "$3" ]
        then
                cecho "[FATAL] Unexpected error on line ${LASTLINE}" red
        else
                cecho "[FATAL] Unexpected error on line ${LASTLINE} in function ${FUNCTION} ($LASTERR)" red
        fi
        exit 2
}

### colorisation de texte dans un script bash ###
cecho ()                    
{

        # Argument $1 = message
        # Argument $2 = foreground color
        # Argument $3 = background color

        case "$2" in
                "black")
                        fcolor='30'
                        ;;
                "red")
                        fcolor='31'
                        ;;
                "green")
                        fcolor='32'
                        ;;
                "yellow")
                        fcolor='33'
                        ;;
                "blue")
                        fcolor='34'
                        ;;
                "magenta")
                        fcolor='35'
                        ;;
                "cyan")
                        fcolor='36'
                        ;;
                "white")
                        fcolor='37'
                        ;;
                *)
                        fcolor=''
        esac
        case "$3" in
                "black")
                        bcolor='40'
                        ;;
               "red")
                        bcolor='41'
                        ;;
                "green")
                        bcolor='42'
                        ;;
                "yellow")
                        bcolor='43'
                        ;;
                "blue")
                        bcolor='44'
                        ;;
                "magenta")
                        bcolor='45'
                        ;;
                "cyan")
                        bcolor='46'
                        ;;
                "white")
                        bcolor='47'
                        ;;
                *)
                        bcolor=""
        esac

        if [ -z $bcolor ]
        then
                echo -ne "\E["$fcolor"m"$1"\n"
        else
                echo -ne "\E["$fcolor";"$bcolor"m"$1"\n"
        fi
        tput sgr0
        return
}

readresponse(){
        case "$2" in
                "black")
                        fcolor='30'
                        ;;
                "red")
                        fcolor='31'
                        ;;
                "green")
                        fcolor='32'
                        ;;
                "yellow")
                        fcolor='33'
                        ;;
                "blue")
                        fcolor='34'
                        ;;
                "magenta")
                        fcolor='35'
                        ;;
                "cyan")
                        fcolor='36'
                        ;;
                "white")
                        fcolor='37'
                        ;;
                *)
                        fcolor=''
        esac
	echo -ne "\E["$fcolor"m"$1
	read response
	echo -ne "\n"
        tput sgr0
}

cline ()                    
{

        # Argument $1 = message
        # Argument $2 = foreground color
        # Argument $3 = background color

        case "$2" in
                "black")
                        fcolor='30'
                        ;;
                "red")
                        fcolor='31'
                        ;;
                "green")
                        fcolor='32'
                        ;;
                "yellow")
                        fcolor='33'
                        ;;
                "blue")
                        fcolor='34'
                        ;;
                "magenta")
                        fcolor='35'
                        ;;
                "cyan")
                        fcolor='36'
                        ;;
                "white")
                        fcolor='37'
                        ;;
                *)
                        fcolor=''
        esac
        case "$3" in
                "black")
                        bcolor='40'
                        ;;
               "red")
                        bcolor='41'
                        ;;
                "green")
                        bcolor='42'
                        ;;
                "yellow")
                        bcolor='43'
                        ;;
                "blue")
                        bcolor='44'
                        ;;
                "magenta")
                        bcolor='45'
                        ;;
                "cyan")
                        bcolor='46'
                        ;;
                "white")
                        bcolor='47'
                        ;;
                *)
                        bcolor=""
        esac
        if [ -z $bcolor ]
        then
                echo -ne "\E["$fcolor"m"$1 
        else
                echo -ne "\E["$fcolor";"$bcolor"m"$1  
        fi
        return
}

function cadre(){
	cecho "+--------------------------------------------------------------------------------" $2
	cecho "| $1" $2
	cecho "+--------------------------------------------------------------------------------" $2
}

function mcadre(){

	if [ "$1" = "mcline" ]
	then
		cecho "+--------------------------------------------------------------------------------" $2
		return
	fi

	OLDIFS=$IFS
	IFS=$'\n'
	for l in $1
	do
		cecho "| $l" $2
	done
	IFS=OLDIFS
}

function check_distro(){
	trap 'trap_handler ${LINENO} $? check_distro' ERR
	cadre "Verifying compatible distros" green

	if [ ! -e /usr/bin/lsb_release ]
	then	
		cecho " > No compatible distribution found" red
		cecho " > maybe the lsb_release utility is not found" red
		cecho " > on redhat like distro you should try yum install redhat-lsb"
		exit 2
	fi

	if [ -z "$CODE" ]
	then
		cecho " > $DIST is not suported" red
		exit 2
	fi

	versionok=0
	distrook=0

	for d in $DISTROS
	do
		distro=$(echo $d | awk -F: '{print $1}')
		version=$(echo $d | awk -F: '{print $2}')
		if [ "$CODE" = "$distro" ]
		then
			cecho " > Found $CODE" green
			if [ "$version" = "" ]
			then
				cecho " > Version checking for $DIST is not needed" green
				versionok=1
				return
			else
				if [ "$VERS" = "$version" ]
				then
					versionok=1
					return
				#else
				#	versionok=0
				fi		
			fi
		fi
	done

	if [ $versionok -ne 1 ]
	then	
		cecho " > $DIST $VERS is not supported" red
		exit 2
	fi

	cecho " > Found $DIST $VERS" yellow 
}

function remove(){
	trap 'trap_handler ${LINENO} $? remove' ERR
	cadre "Removing shinken" green
	skill
	
	if [ -d "$TARGET" ]
	then 
		cecho " > removing $TARGET" green
		rm -Rf $TARGET
	fi
	if [ -h "/etc/default/shinken" ]
	then 
		cecho " > removing defaults" green
		rm -Rf /etc/default/shinken 
	fi
	if [ -f "/etc/init.d/shinken" ]
        then
		cecho " > Removing startup scripts" green
                case $CODE in
                        REDHAT)
                                chkconfig shinken off
                                chkconfig --del shinken
                                ;;
                        DEBIAN)
                                update-rc.d -f shinken remove > /dev/null 2>&1
                                ;;
                esac    
        fi
	rm -f /etc/init.d/shinken*

	return 0
}

function purgeSQLITE(){
	cadre "Purge livestatus db logs" green
	if [ ! -f $TARGET/var/livestatus.db ]
	then
		cecho " > Livestatus db not found " yellow
		exit 1
	fi
	skill > /dev/null 2>&1
	cecho " > we keep $KEEPDAYSLOG days of logs" green
	sqlite3 $TARGET/var/livestatus.db "delete from logs where time < strftime('%s', 'now') - 3600*24*$KEEPDAYSLOG"
	cecho " > Vaccum the sqlite DB" green
	sqlite3 $TARGET/var/livestatus.db VACUUM
}

function skill(){
	/etc/init.d/shinken stop > /dev/null 2>&1
	pc=$(ps -aef | grep "$TARGET" | grep -v "grep" | wc -l )
	if [ $pc -ne 0 ]
	then	
		OLDIFS=$IFS
		IFS=$'\n'
		for p in $(ps -aef | grep "$TARGET" | grep -v "grep" | awk '{print $2}')
		do
			cecho " > killing $p " green
			kill -9 $p
		done

		IFS=$OLDIFS
	fi
	rm -Rf /tmp/bad_start*
	rm -Rf $TARGET/var/*.pid
}

function get_from_git(){
	trap 'trap_handler ${LINENO} $? get_from_git' ERR
	cadre "Getting shinken" green
	cd $TMP
	if [ -e "shinken" ]
	then
		rm -Rf shinken
	fi
	env GIT_SSL_NO_VERIFY=true git clone $GIT > /dev/null 2>&1
	cd shinken
	cecho " > Switching to version $VERSION" green
	git checkout $VERSION > /dev/null 2>&1
	export src=$TMP/shinken
	# clean up .git folder
	rm -Rf .git
}

function setdirectives(){
	trap 'trap_handler ${LINENO} $? setdirectives' ERR
	directives=$1
	fic=$2
	mpath=$3
	
	cecho "    > going to $mpath" green
	cd $mpath

	for pair in $directives
	do
		directive=$(echo $pair | awk -F= '{print $1}')
		value=$(echo $pair | awk -F= '{print $2}')
		cecho "       > setting $directive to $value in $fic" green
		sed -i 's#^\# \?'$directive'=\(.*\)$#'$directive'='$value'#g' $mpath/etc/$(basename $fic)
	done
}

function relocate(){
	trap 'trap_handler ${LINENO} $? relocate' ERR
	cadre "Relocate source tree to $TARGET" green
	# relocate source tree
	cd $TARGET
	
	# relocate macros
	for f in $(find $TARGET/contrib/alternative-installation/shinken-install/tools/macros | grep "\.macro$")
	do
		cecho " > relocating macro $f" green
		sed -i "s#__PREFIX__#$TARGET#g" $f
	done

	# relocate nagios plugin path
	sed -i "s#/usr/lib/nagios/plugins#$TARGET/libexec#g" ./etc/resource.cfg
	sed -i "s#/usr/local/shinken/libexec#$TARGET/libexec#g" ./etc/resource.cfg
	# relocate default /usr/local/shinken path
	for fic in $(find . | grep -v "shinken-install" | grep -v "\.pyc$" | xargs grep -snH "/usr/local/shinken" --color | cut -f1 -d' ' | awk -F : '{print $1}' | sort | uniq)
	do 
		cecho " > Processing $fic" green
		cp "$fic" "$fic.orig" 
		#sed -i 's#/opt/shinken#'$TARGET'#g' $fic 
		sed -i 's#/usr/local/shinken#'$TARGET'#g' "$fic"
	done

	# when read hat 5 try to use python26
	if [ "$CODE" = "REDHAT" ]
	then
		if [ "$VERS" = "5" ]
		then
			cecho " > translating python version to python26" green
			for fic in $(find $TARGET | grep "\.py$") 
			do
				sed -i "s#/usr/bin/env python#/usr/bin/python26#g" $fic
			done
			# also try to translate python script without py extension
			for fic in $(find $TARGET/bin)
			do
				if [ ! -z "$(file $fic | grep "python")" ]
				then
					sed -i "s#/usr/bin/env python#/usr/bin/python26#g" $fic
				fi
			done
		fi
	fi

	# set some directives 
	cadre "Set some configuration directives" green
	directives="workdir=$TARGET/var user=$SKUSER group=$SKGROUP"
	for fic in $(ls -1 etc/*.ini)
	do 
		cecho " > Processing $fic" green;
		setdirectives "$directives" $fic $TARGET
		#cp -f $fic $TARGET/etc/; 
	done
	# relocate default file
	cd $TARGET/bin/default
	cat $TARGET/bin/default/shinken.in | sed  -e 's#LOG\=\(.*\)$#LOG='$TARGET'/var#g' -e 's#RUN\=\(.*\)$#RUN='$TARGET'/var#g' -e  's#ETC\=\(.*\)$#ETC='$TARGET'/etc#g' -e  's#VAR\=\(.*\)$#VAR='$TARGET'/var#g' -e  's#BIN\=\(.*\)$#BIN='$TARGET'/bin#g' > $TARGET/bin/default/shinken
	# relocate init file
	cd $TARGET/bin/init.d
	mv shinken shinken.in
	cat shinken.in | sed -e "s#\#export PYTHONPATH=.*#export PYTHONPATH="$TARGET"#g" > $TARGET/bin/init.d/shinken
}

function fix(){
	trap 'trap_handler ${LINENO} $? fix' ERR
	cadre "Applying various fixes" green
	chmod +x /etc/init.d/shinken
	chmod +x /etc/default/shinken
	chmod +x $TARGET/bin/init.d/shinken
	chown -R $SKUSER:$SKGROUP $TARGET
	chmod -R g+w $TARGET
	# remove tests directory
	rm -Rf $TARGET/test
}

function enable(){
	trap 'trap_handler ${LINENO} $? enable' ERR
	cadre "Enabling startup scripts" green
	cp $TARGET/bin/init.d/shinken* /etc/init.d/
	case $DISTRO in
		REDHAT)
			cecho " > Enabling $DIST startup script" green
			chkconfig --add shinken
			chkconfig shinken on
			;;
		DEBIAN)
			cecho " > Enabling $DIST startup script" green
			update-rc.d shinken defaults > /dev/null 2>&1
			;;
	esac    
}

function sinstall(){
	trap 'trap_handler ${LINENO} $? install' ERR
	#cecho "Installing shinken" green
	check_distro
	check_exist
	prerequisites
	create_user
	cp -Rf $src $TARGET
	relocate
	ln -s $TARGET/bin/default/shinken /etc/default/shinken
	cp $TARGET/bin/init.d/shinken* /etc/init.d/
	mkdir -p $TARGET/var/archives
	fix
	cecho "+------------------------------------------------------------------------------" green
	cecho "| shinken is now installed on your server " green
	cecho "| You can start it with /etc/init.d/shinken start " green
	cecho "| The Web Interface is available at : http://localhost:7767" green
	cecho "+------------------------------------------------------------------------------" green
}

function rheldvd(){
	# this is only for my personal needs
	# dvd mounted ?
	if [ "$CODE" != "REDHAT" ]
	then
		cecho " > Only for REDHAT" red
		exit 2
	fi
	cadre "Setup rhel dvd for yum (this is only for my development purpose)" green
	dvdm=$(cat /proc/mounts | grep "^\/dev\/cdrom")
	if [ -z "$dvdm" ]
	then
		if [ ! -d "/media/cdrom" ]
		then
			mkdir -p "/media/cdrom"
		fi
		cecho " > Insert RHEL/CENTOS DVD and press ENTER" yellow
		read -p " > ENTER when ready "
		mount -t iso9660 -o ro /dev/cdrom /media/cdrom > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			dvdm=$(cat /proc/mounts | grep "^\/dev\/cdrom")
			if [ -z "$dvdm" ]
			then
				cecho " > Unable to mount RHEL/CENTOS DVD !" red
				exit 2
			else
				if [ ! -d "/media/cdrom/Server" ]
				then
					cecho "Invalid DVD" red
					exit 2
				else
					if [ ! -f "/etc/yum.repos.d/rheldvd.repo" ]
					then
						echo "[dvd]" > /etc/yum.repos.d/rheldvd.repo
						echo "name=rhel dvd" >> /etc/yum.repos.d/rheldvd.repo
						echo "baseurl=file:///media/cdrom/Server" >> /etc/yum.repos.d/rheldvd.repo
						echo "enabled=1" >> /etc/yum.repos.d/rheldvd.repo
						echo "gpgcheck=0" >> /etc/yum.repos.d/rheldvd.repo
					fi
				fi
			fi
		else 
			cecho " > Error while mounting DVD" red
		fi	
	fi	
}

function backup(){
	trap 'trap_handler ${LINENO} $? backup' ERR
	cadre "Backup shinken configuration, plugins and data" green
	skill
	if [ ! -e $BACKUPDIR ]
	then
		mkdir $BACKUPDIR
	fi
	mkdir -p $BACKUPDIR/bck-shinken.$DATE
	cp -Rfp $TARGET/etc $BACKUPDIR/bck-shinken.$DATE/
	cp -Rfp $TARGET/libexec $BACKUPDIR/bck-shinken.$DATE/
	cp -Rfp $TARGET/var $BACKUPDIR/bck-shinken.$DATE/
	cecho " > Backup done. Id is $DATE"
}

function backuplist(){
	trap 'trap_handler ${LINENO} $? backuplist' ERR
	cadre "List of available backups in $BACKUPDIR" green
	for d in $(ls -1 $BACKUPDIR | grep "bck-shinken" | awk -F. '{print $2}')
	do
		cecho " > $d" green
	done

}

function restore(){
	trap 'trap_handler ${LINENO} $? restore' ERR
	cadre "Restore shinken configuration, plugins and data" green
	skill
	if [ ! -e $BACKUPDIR ]
	then
		cecho " > Backup folder not found" red
		exit 2
	fi
	if [ -z $1 ]
	then
		cecho " > No backup timestamp specified" red
		backuplist
		exit 2
	fi
	if [ ! -e $BACKUPDIR/bck-shinken.$1 ]
	then
		cecho " > Backup not found : $BACKUPDIR/bck-shinken.$1 " red
		backuplist
		exit 2
	fi
	rm -Rf $TARGET/etc
	rm -Rf $TARGET/libexec 
	rm -Rf $TARGET/var 
	cp -Rfp $BACKUPDIR/bck-shinken.$1/* $TARGET/
	cecho " > Restauration done" green
}

function supdate(){
	trap 'trap_handler ${LINENO} $? update' ERR

	curpath=$(pwd)
	if [ "$src" == "$TARGET" ]
	then
		cecho "You should use the source tree for update not the target folder !!!!!" red
		exit 2
	fi

	cadre "Updating shinken" green
	
	skill
	backup
	remove
	get_from_git
	cp -Rf $src $TARGET
	relocate
	ln -s $TARGET/bin/default/shinken /etc/default/shinken
	cp $TARGET/bin/init.d/shinken* /etc/init.d/
	mkdir -p $TARGET/var/archives
	fix
	restore $DATE
}

function create_user(){
	trap 'trap_handler ${LINENO} $? create_user' ERR
	cadre "Creating user" green
	if [ ! -z "$(cat /etc/passwd | grep $SKUSER)" ] 
	then
		cecho " > User $SKUSER allready exist" yellow 
	else
	    	useradd -s /bin/bash $SKUSER -m -d /home/$SKUSER 
	fi
    	usermod -G $SKGROUP $SKUSER 
}

function check_exist(){
	trap 'trap_handler ${LINENO} $? check_exist' ERR
	cadre "Checking for existing installation" green
	if [ -d "$TARGET" ]
	then
		cecho " > Target folder allready exist" red
		exit 2
	fi
	if [ -e "/etc/init.d/shinken" ]
	then
		cecho " > Init scripts allready exist" red
		exit 2
	fi
	if [ -L "/etc/default/shinken" ]
	then
		cecho " > shinken default allready exist" red
		exit 2
	fi

}

function installpkg(){
	type=$1
	package=$2

	if [ "$type" == "python" ]
	then
		easy_install $package > /dev/null 2>&1
		return $?
	fi

	case $CODE in 
		REDHAT)
			yum install -yq $package > /dev/null 2>&1
			if [ $? -ne 0 ]
			then
				return 2
			fi
			;;
		DEBIAN)
			apt-get install -y $package > /dev/null 2>&1
			if [ $? -ne 0 ]
			then
				return 2
			fi
			;;
	esac	
	return 0
}


function prerequisites(){
	cadre "Checking prerequisite" green
	# common prereq
	bins="wget sed awk grep python bash"

	for b in $bins
	do
		rb=$(which $b > /dev/null 2>&1)
		if [ $? -eq 0 ]
		then
			cecho " > Checking for $b : OK" green 
		else
			cecho " > Checking for $b : NOT FOUND" red
			exit 2 
		fi	
	done

	# distro prereq
	case $CODE in
		REDHAT)
			case $VERS in
				5)
					PACKAGES=$YUMPKGS
					QUERY="rpm -q "
					cd $TMP
					$QUERY $EPELNAME > /dev/null 2>&1
					if [ $? -ne 0 ]
					then
						cecho " > Installing $EPELPKG" yellow
						wget $WGETPROXY $EPEL  > /dev/null 2>&1 
						if [ $? -ne 0 ]
						then
							cecho " > Error while trying to download EPEL repositories" red 
							exit 2
						fi
						rpm -Uvh ./$EPELPKG > /dev/null 2>&1
					else
						cecho " > $EPELPKG allready installed" green 
					fi
					;;
				6)
					PACKAGES=$YUMPKGS
					QUERY="rpm -q "
					;;
				*)
					cecho " > Unsupported RedHat/CentOs version" red
					exit 2
					;;
			esac
			;;

		DEBIAN)
			PACKAGES=$APTPKGS
			QUERY="dpkg -l "
			;;
	esac
	for p in $PACKAGES
	do
		$QUERY $p > /dev/null 2>&1
		if [ $? -ne 0 ]
		then
			cecho " > Installing $p " yellow
			installpkg pkg $p 
			if [ $? -ne 0 ]
			then 
				cecho " > Error while trying to install $p" red 
				exit 2 	
			fi
		else
			cecho " > Package $p allready installed " green 
		fi
	done
	# python prereq
	if [ "$CODE" = "REDHAT" ]
	then
		case $VERS in
			5)
				# install setup tools for python 26
				export PY="python26"
				export PYEI="easy_install-2.6"
				if [ ! -d "setuptools-$SETUPTOOLSVERS" ]
				then
					cecho " > Downloading setuptoos for python 2.6" green
					wget $WGETPROXY $RHELSETUPTOOLS > /dev/null 2>&1
					tar zxvf setuptools-$SETUPTOOLSVERS.tar.gz > /dev/null 2>&1
				fi
				cecho " > installing setuptoos for python 2.6" green
				cd setuptools-$SETUPTOOLSVERS > /dev/null 2>&1
				python26 setup.py install > /dev/null 2>&1
				PYLIBS=$PYLIBSRHEL
				;;
			6)
				export PY="python"
				export PYEI="easy_install"
				PYLIBS=$PYLIBSRHEL6
				;;
		esac
		for p in $PYLIBS
		do
			module=$(echo $p | awk -F: '{print $1'})
			import=$(echo $p | awk -F: '{print $2'})

			$PY $myscripts/tools/checkmodule.py -m $import > /dev/null 2>&1
			if [ $? -eq 2 ]
			then
				cecho " > Module $module ($import) not found. Installing..." yellow
				$PYEI $module > /dev/null 2>&1
			else
				cecho " > Module $module found." green 
			fi

			
		done	
	fi
	
}

function compresslogs(){
	trap 'trap_handler ${LINENO} $? compresslogs' ERR
	cadre "Compress rotated logs" green
	if [ ! -d $TARGET/var/archives ]
	then
		cecho " > Archives directory not found" yellow
		exit 0
	fi
	cd $TARGET/var/archives
	for l in $(ls -1 ./*.log)
	do
		file=$(basename $l)
		if [ -e $file ]
		then
			cecho " > Processing $file" green
			tar czf $file.tar.gz $file
			rm -f $file
		fi
	done
}

function shelp(){
	cat $myscripts/README
}

function cleanconf(){
	if [ -z "$myscripts" ]
	then
		cecho " > Files/Folders list not found" yellow
		exit 2
	else
		for f in $(cat $myscripts/config.files)
		do
			cecho " > removing $TARGET/etc/$f" green
			rm -Rf $TARGET/etc/$f
		done
	fi
}

function fixsudoers(){
	cecho " > Fix /etc/sudoers file for shinken integration" green
	cp /etc/sudoers /etc/sudoers.$(date +%Y%m%d%H%M%S)
	cat $myscripts/sudoers.centreon | sed -e 's#TARGET#'$TARGET'#g' >> /etc/sudoers
}

function fixcentreondb(){
	cecho " > Fix centreon database path for shinken integration" green

	# get existing db access
	host=$(cat /etc/centreon/conf.pm | grep "mysql_host" | awk '{print $3}' | sed -e "s/\"//g" -e "s/;//g")
	user=$(cat /etc/centreon/conf.pm | grep "mysql_user" | awk '{print $3}' | sed -e "s/\"//g" -e "s/;//g")
	pass=$(cat /etc/centreon/conf.pm | grep "mysql_passwd" | awk '{print $3}' | sed -e "s/\"//g" -e "s/;//g")
	db=$(cat /etc/centreon/conf.pm | grep "mysql_database_oreon" | awk '{print $3}' | sed -e "s/\"//g" -e "s/;//g")

	cp $myscripts/centreon.sql /tmp/centreon.sql
	sed -i 's#TARGET#'$TARGET'#g' /tmp/centreon.sql
	sed -i 's#CENTREON#'$db'#g' /tmp/centreon.sql

	if [ -z "$pass" ]
	then
		mysql -h $host -u $user $db < /tmp/centreon.sql
	else
		mysql -h $host -u $user -p$pass $db < /tmp/centreon.sql
	fi
}

function fixforfan(){
	if [ ! -z "cat /etc/issue | grep FAN" ]
	then
		chown -R apache:nagios $TARGET/etc
		chmod -R g+rw $TARGET/etc/*
	fi
}

function pythonver(){
	versions="2.4 2.5 2.6 2.7"
        LASTFOUND=""
        # is there any python here ?
        for v in $versions
        do
                which python$v > /dev/null 2>&1
                if [ $? -eq 0 ]
                then
                        LASTFOUND="python$v"
                fi
        done
        if [ -z "$LASTFOUND" ]
        then
                # finaly try to find a default python
                which python > /dev/null 2>&1
                if [ $? -ne 0 ]
                then
                        echo "No python interpreter found !"
                        exit 2
                else
                        echo "python found"
                        LASTFOUND=$(which python)
                fi
        fi
        PY=$LASTFOUND
	echo $PY
}

function enablendodb(){
	cecho " > FIX shinken ndo configuration" green
	# get existing db access
	host=$(cat /etc/centreon/conf.pm | grep "mysql_host" | awk '{print $3}' | sed -e "s/\"//g" -e "s/;//g")
	user=$(cat /etc/centreon/conf.pm | grep "mysql_user" | awk '{print $3}' | sed -e "s/\"//g" -e "s/;//g")
	pass=$(cat /etc/centreon/conf.pm | grep "mysql_passwd" | awk '{print $3}' | sed -e "s/\"//g" -e "s/;//g")
	db="centreon_status"
	# add ndo module to broker
	# first get existing broker modules
	export PYTHONPATH=$TARGET
	export PY="$(pythonver)"
	result=$($PY $myscripts/tools/skonf.py -a macros -f $myscripts/tools/macros/ces_enable_ndo.macro -d $host,$db,$user,$pass)
    if [ $? -ne 0 ]
    then
        cecho $result red
        exit 2
    fi
}

function enableretention(){

	cecho " > Enable retention for broker scheduler and arbiter" green

	export PYTHONPATH=$TARGET
	export PY="$(pythonver)"
	result=$($PY $myscripts/tools/skonf.py -a macros -f $myscripts/tools/macros/ces_enable_retention.macro)	
    if [ $? -ne 0 ]
    then
        cecho $result red
        exit 2
    fi
}

function enableperfdata(){

	cecho " > Enable perfdata " green

	export PYTHONPATH=$TARGET
	export PY="$(pythonver)"
	cecho " > Getting existing broker modules list" green
	modules=$($PY $myscripts/tools/skonf.py -a getdirective -f $TARGET/etc/shinken-specific.cfg -o broker -d modules)	
	if [ -z "$modules" ]
	then	
		modules="Service-Perfdata, Host-Perfdata"
	else
		modules=$modules", Service-Perfdata, Host-Perfdata"
	fi
	result=$($PY $myscripts/tools/skonf.py -q -a setparam -f $TARGET/etc/shinken-specific.cfg -o broker -d modules -v "$modules")
	cecho " > $result" green
}

function setdaemonsaddresses(){
	export PYTHONPATH=$TARGET
	export PY="$(pythonver)"
    localip=$(ifconfig $IF | grep "^ *inet adr:" | awk -F : '{print $2}' | awk '{print $1}')
	result=$($PY $myscripts/tools/skonf.py -q -a setparam -f $TARGET/etc/shinken-specific.cfg -o arbiter -d address -v "$localip")
    cecho " > $result" green    
	result=$($PY $myscripts/tools/skonf.py -q -a setparam -f $TARGET/etc/shinken-specific.cfg -o scheduler -d address -v "$localip")
    cecho " > $result" green    
	result=$($PY $myscripts/tools/skonf.py -q -a setparam -f $TARGET/etc/shinken-specific.cfg -o reactionner -d address -v "$localip")
    cecho " > $result" green    
	result=$($PY $myscripts/tools/skonf.py -q -a setparam -f $TARGET/etc/shinken-specific.cfg -o receiver -d address -v "$localip")
    cecho " > $result" green    
	result=$($PY $myscripts/tools/skonf.py -q -a setparam -f $TARGET/etc/shinken-specific.cfg -o poller -d address -v "$localip" -r "poller_name=poller-1")
    cecho " > $result" green    
}

function enableCESCentralDaemons(){
    setdaemons "arbiter reactionner receiver scheduler broker poller"  
}

function enableCESPollerDaemons(){
    setdaemons "poller"  
}

function disablenagios(){
	chkconfig nagios off
	chkconfig ndo2db off
	/etc/init.d/nagios stop > /dev/null 2>&1
	/etc/init.d/ndo2db stop > /dev/null 2>&1
}

function setdaemons(){
    daemons="$(echo $1)"
    avail="AVAIL_MODULES=\"$daemons\""
    cecho " > Enabling the followings daemons : $daemons" green
    sed -i "s/^AVAIL_MODULES=.*$/$avail/g" /etc/init.d/shinken
}

function fixHtpasswdPath(){
	export PYTHONPATH=$TARGET
	export PY="$(pythonver)"
    # fix the htpasswd.users file path for WEBUI authentication
    result=$($PY $myscripts/tools/skonf.py -f $TARGET/etc/shinken-specific.cfg -a setparam -o module -r "module_name=Apache_passwd" -d "passwd" -v "$TARGET/etc/htpasswd.users")
    cecho " > $result" green    
}

function usage(){
echo "Usage : shinken -k | -i | -w | -d | -u | -b | -r | -l | -c | -h | -a | -z [poller|centreon] | -e daemons | -p plugins [plugname]
	-k	Kill shinken
	-i	Install shinken
	-w	Remove demo configuration 
	-d 	Remove shinken
	-u	Update an existing shinken installation
	-v	purge livestatus sqlite db and shrink sqlite db
	-b	Backup shinken configuration plugins and data
	-r 	Restore shinken configuration plugins and data
	-l	List shinken backups
	-c	Compress rotated logs
    -e  which daemons to keep enabled at boot time
	-z 	This is a really special usecase that allow to install shinken on Centreon Enterprise Server in place of nagios
	-p  Install plugins or addons (args should be one of the following : check_esx3|nagios-plugins|check_oracle_health|capture_plugin|pnp4nagios|multisite)
	-h	Show help"
}

# addons installation
# mk multisite

function install_multisite(){
	if [ "$CODE" == "REDHAT" ]
	then
		cecho " > Unsuported" red
		exit 2
	fi
	cadre "Install check_mk addon" green
	cecho " > configure response file" green
	cp check_mk_setup.conf.in $HOME/.check_mk_setup.conf
	sed -i "s#__PNPPREFIX__#$PNPPREFIX#g" $HOME/.check_mk_setup.conf
	sed -i "s#__MKPREFIX__#$MKPREFIX#g" $HOME/.check_mk_setup.conf
	sed -i "s#__SKPREFIX__#$TARGET#g" $HOME/.check_mk_setup.conf
	sed -i "s#__SKUSER__#$SKUSER#g" $HOME/.check_mk_setup.conf
	sed -i "s#__SKGROUP__#$SKGROUP#g" $HOME/.check_mk_setup.conf
	sed -i "s#__HTTPUSER__#www-data#g" $HOME/.check_mk_setup.conf
	sed -i "s#__HTTPGROUP__#www-data#g" $HOME/.check_mk_setup.conf
	sed -i "s#__HTTPD__#/etc/apache2#g" $HOME/.check_mk_setup.conf
	sed -i "s#__HTTPD__#/etc/apache2#g" $HOME/.check_mk_setup.conf
	cd /tmp
	cecho " > Installing prerequisites" green
	for p in $MKAPTPKG
	do
		cecho " -> Installing $p" green
		apt-get --force-yes -y install $p > /dev/null 2>&1
	done

	filename=$(echo $MKURI | awk -F"/" '{print $NF}')
	folder=$(echo $filename | sed -e "s/\.tar\.gz//g")
	if [ ! -f "$filename" ]
	then 
		cecho " > Getting check_mk archive" green
		wget $MKURI > /dev/null 2>&1
	fi
	
	cecho " > Extracting archive" green
	if [ -d "$folder" ]
	then 
		rm -Rf $folder
	fi 
	tar zxvf $filename > /dev/null 2>&1
	cd $folder
	cecho " > install multisite" green
	./setup.sh --yes > /dev/null 2>&1
	cecho " > default configuration for multisite" green
	echo 'sites = {' >> $MKPREFIX/etc/multisite.mk
	echo '   "default": {' >> $MKPREFIX/etc/multisite.mk
	echo '	"alias":          "default",' >> $MKPREFIX/etc/multisite.mk
	echo '	"socket":         "tcp:127.0.0.1:50000",' >> $MKPREFIX/etc/multisite.mk
	echo '	"url_prefix":     "/",' >> $MKPREFIX/etc/multisite.mk
	echo '   },' >> $MKPREFIX/etc/multisite.mk
	echo ' }' >> $MKPREFIX/etc/multisite.mk
	rm -Rf $TARGET/etc/check_mk.d/*
	cecho " > Fix www-data group" green
	usermod -a -G $SKGROUP www-data 
	chown -R $SKUSER:$SKGROUP $TARGET/etc/check_mk.d
	chmod -R g+rwx $TARGET/etc/check_mk.d
	chown -R $SKUSER:$SKGROUP $MKPREFIX/etc/conf.d
	chmod -R g+rwx $MKPREFIX/etc/conf.d
	service apache2 restart > /dev/null 2>&1
	cecho " > Enable sudoers commands for check_mk" green
	echo "# Needed for WATO - the Check_MK Web Administration Tool" >> /etc/sudoers
	echo "Defaults:www-data !requiretty" >> /etc/sudoers
	echo "www-data ALL = (root) NOPASSWD: $MKTARGET/check_mk --automation *" >> /etc/sudoers
	/etc/init.d/sudo restart
}

# pnp4nagios
function install_pnp4nagios(){
	if [ "$CODE" == "REDHAT" ]
	then
		cecho " > Unsuported" red
		exit 2
	fi
	cadre "Install pnp4nagios addon" green
	cd /tmp
	cecho " > Installing prerequisites" green
	for p in $PNPAPTPKG
	do
		cecho " -> Installing $p" green
		apt-get install -y $p > /dev/null 2>&1
	done

	filename=$(echo $PNPURI | awk -F"/" '{print $NF}')
	folder=$(echo $filename | sed -e "s/\.tar\.gz//g")
	if [ ! -f "$filename" ]
	then 
		cecho " > Getting pnp4nagios archive" green
		wget $PNPURI > /dev/null 2>&1
	fi
	
	cecho " > Extracting archive" green
	if [ -d "$folder" ]
	then 
		rm -Rf $folder
	fi 
	tar zxvf $filename > /dev/null 2>&1
	cd $folder
	cecho " > Enable mod rewrite for apache" green 
	a2enmod rewrite > /dev/null 2>&1
	/etc/init.d/apache2 restart > /dev/null 2>&1
	cecho " > Configuring source tree" green
	./configure --prefix=$PNPPREFIX --with-nagios-user=$SKUSER --with-nagios-group=$SKGROUP > /dev/null 2>&1	
	cecho " > Building ...." green
	make all > /dev/null 2>&1
	cecho " > Installing" green
	make fullinstall > /dev/null 2>&1
	rm -f $PNPPREFIX/share/install.php
        cecho " > fix htpasswd.users path" green
        sed -i "s#/usr/local/nagios/etc/htpasswd.users#$TARGET/etc/htpasswd.users#g" /etc/apache2/conf.d/pnp4nagios.conf 
	/etc/init.d/apache2 restart > /dev/null 2>&1
	cecho " > Enable npcdmod" green

	ip=$(ifconfig | grep "inet adr" | grep -v 127.0.0.1 | awk '{print $2}' | awk -F : '{print $2}' | head -n 1)
	do_skmacro enable_npcd.macro $PNPPREFIX/etc/npcd.cfg,$ip 
}


function do_skmacro(){
	macro=$1
	args=$2
	export PYTHONPATH="$TARGET"
	export SHINKEN="$PYTHONPATH"
	export SKTOOLS="$PYTHONPATH/contrib/alternative-installation/shinken-install/tools"
	$SKTOOLS/skonf.py -a macros -f $SKTOOLS/macros/$macro -d $args > /dev/null 2>&1
}



# plugins installation part

# capture_plugin
function install_capture_plugin(){
	cadre "Install capture_plugin" green
	cd /tmp
	cecho " > Getting capture_plugin" green
	wget http://www.waggy.at/nagios/capture_plugin.txt > /dev/null 2>&1
	cecho " > Installing capture_plugin" green
	mv capture_plugin.txt $TARGET/libexec/capture_plugin
	chmod +x $TARGET/libexec/capture_plugin	
	chown $SKUSER:$SKGROUP $TARGET/libexec/capture_plugin
}

# check_esx3

function install_check_esx3(){

	cadre "Install check_esx3 plugin from op5" green

	if [ "$CODE" == "REDHAT" ]
	then
		cecho " > Unsuported" red
	else
		cecho " > installing prerequisites" green 
		sudo apt-get -y install $VSPHERESDKAPTPKGS > /dev/null 2>&1
	fi
	cd /tmp

	if [ ! -f "/tmp/VMware-vSphere-SDK-for-Perl-$VSPHERESDKVER.$ARCH.tar.gz" ]
	then
		wget $VSPHERESDK > /dev/null 2>&1	
		if [ $? -ne 0 ]
		then
			cecho " > Error while downloading vsphere sdk for perl" red
			exit 2
		fi
	fi

	cecho " > Extracting vsphere sdk for perl" green
	tar zxvf VMware-vSphere-SDK-for-Perl-$VSPHERESDKVER.$ARCH.tar.gz  > /dev/null 2>&1
	cd vmware-vsphere-cli-distrib 
	cecho " > Building vsphere sdk for perl" green
	perl Makefile.PL > /dev/null 2>&1
	make > /dev/null 2>&1
	cecho " > Installing vsphere sdk for perl" green
	make install > /dev/null 2>&1

	cd /tmp
	cecho " > Getting check_esx3 plugin from op5" green
	wget $CHECK_ESX3_SCRIPT -O check_esx3.pl > /dev/null 2>&1
	mv check_esx3.pl $TARGET/libexec/check_esx3.pl
	chmod +x $TARGET/libexec/check_esx3.pl	
	chown $SKUSER:$SKGROUP $TARGET/libexec/check_esx3.pl
		
}

# nagios-plugins

function install_nagios-plugins(){
	cadre "Install nagios plugins" green

	if [ "$CODE" == "REDHAT" ]
	then
		cecho " > Unsuported" red
	else
		cecho " > installing prerequisites" green 
		sudo apt-get -y install $NAGPLUGAPTPKG > /dev/null 2>&1
	fi
	cd /tmp
	if [ ! -f "nagios-plugins-$NAGPLUGVERS.tar.gz" ]
	then
		cecho " > getting nagios-plugins archive" green
		wget $NAGPLUGBASEURI > /dev/null 2>&1
	fi
	cecho " > Extract archive content " green
	rm -Rf nagios-plugins-$NAGPLUGVERS
	tar zxvf nagios-plugins-$NAGPLUGVERS.tar.gz > /dev/null 2>&1
	cd nagios-plugins-$NAGPLUGVERS
	cecho " > Configure source tree" green
	./configure --with-nagios-user=$SKUSER --with-nagios-group=$SKGROUP --enable-libtap --enable-extra-opts --prefix=$TARGET > /dev/null 2>&1
	cecho " > Building ...." green
	make > /dev/null 2>&1
	cecho " > Installing" green
	make install > /dev/null 2>&1
	
}

# check_oracle_health

function install_check_oracle_health(){
	cadre "Install nagios plugins" green

	cadre "WARNING YOU SHOULD INSTALL ORACLE INSTANT CLIENT FIRST !!!!" yellow
	cecho " > Download the oracle instant client there (basic AND sdk AND sqlplus) : " yellow
	cecho " > 64 bits : http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html" yellow
	cecho " > 32 bits : http://www.oracle.com/technetwork/topics/linuxsoft-082809.html" yellow
	cecho " > Set the ORACLE_HOME environment variable (better to set it in the bashrc)" yellow
	cecho " > Set LD_LIBRARY_PATH to ORACLE_HOME (or better create a config file in /etc/ld.so.conf) then run ldconfig" yellow
	cecho " > press ENTER to continue or CTRL+C to abort" yellow
	read taste

	if [ -z "$ORACLE_HOME" ]
	then
		cecho " > you must set the ORACLE_HOME environment variable !" red
		exit 2
	fi

	if [ "$CODE" == "REDHAT" ]
	then
		cecho " > Unsuported" red
	else
		cecho " > installing prerequisites" green 
		sudo apt-get -y install $CHECKORACLEHEALTHAPTPKG > /dev/null 2>&1
		cecho " > installing cpan prerequisites" green
		cd /tmp
		for m in $CHECKORACLEHEALTHCPAN
		do
			filename=$(echo $m | awk -F"/" '{print $NF}')
			if [ ! -f "$filename" ]
			then
				wget $m > /dev/null 2>&1
				if [ $? -ne 0 ]
				then
					cecho " > Error while downloading $m" red
					exit 2
				fi
			fi	
			tar zxvf $filename  > /dev/null 2>&1
			cd $(echo $filename | sed -e "s/\.tar\.gz//g")
			perl Makefile.PL > /dev/null 2>&1
			make > /dev/null 2>&1
			if [ $? -ne 0 ]
			then
				cecho " > There was an error building module" red
				exit 2
			fi
			make install  > /dev/null 2>&1
		done
		cd /tmp
		cecho " > Downloading check_oracle_health" green
		wget $CHECKORACLEHEALTH > /dev/null 2>&1
		if [ $? -ne 0 ]
		then
			cecho " > Error while downloading $filename" red
			exit 2
		fi
		cecho " > Extracting archive " green
		filename=$(echo $CHECKORACLEHEALTH | awk -F"/" '{print $NF}')
		tar zxvf $filename > /dev/null 2>&1
		cd $(echo $filename | sed -e "s/\.tar\.gz//g")
		./configure --prefix=$TARGET --with-nagios-user=$SKUSER --with-nagios-group=$SKGROUP --with-mymodules-dir=$TARGET/libexec --with-mymodules-dyn-dir=$TARGET/libexec --with-statefiles-dir=$TARGET/var/tmp > /dev/null 2>&1
		cecho " > Building plugin" green
		make > /dev/null 2>&1
		if [ $? -ne 0 ] 
		then
			cecho " > Error while building check_oracle_health module" red
			exit 2
		fi
		make check > /dev/null 2>&1	
		if [ $? -ne 0 ]
		then
			cecho " > Error while building check_oracle_health module" red
			exit 2
		fi
		cecho " > Installing plugin" green
		make install > /dev/null 2>&1
	fi
}

# Check if we launch the script with root privileges (aka sudo)
if [ "$UID" != "0" ]
then
        cecho "You should start the script with sudo!" red
        exit 1
fi

if [ ! -z "$PROXY" ]
then
	export http_proxy=$PROXY
	export https_proxy=$PROXY
	export WGETPROXY=" -Y on "
fi

while getopts "kidubcr:lz:hsvp:we:" opt; do
	case $opt in
		p)
			if [ "$OPTARG" == "check_esx3" ]
			then
				install_check_esx3
				exit 0
			elif [ "$OPTARG" == "nagios-plugins" ]
			then
				install_nagios-plugins
				exit 0
			elif [ "$OPTARG" == "check_oracle_health" ]
			then
				install_check_oracle_health
				exit 0
			elif [ "$OPTARG" == "capture_plugin" ]
			then
				install_capture_plugin
				exit 0
			elif [ "$OPTARG" == "pnp4nagios" ]
			then
				install_pnp4nagios
				exit 0
			elif [ "$OPTARG" == "multisite" ]
			then
				install_multisite
				exit 0
			else
				cecho " > Unknown plugin $OPTARG" red
			fi
			;;
        j)
            addpoller "$OPTARG"
            exit 0
            ;;
        e)
            setdaemons "$OPTARG"
            exit 0
            ;;
		w)
			cleanconf	
			exit 0
			;;
		z)
            mode=$OPTARG
			cleanconf
			disablenagios
			fixsudoers
			if [ "$mode" = "centreon" ]
            then
                fixcentreondb
				fixforfan
                enablendodb
                enableretention
                enableperfdata
                setdaemonsaddresses
                enableCESCentralDaemons
                #fixHtpasswdPath
                #addCESPollers
            else
                enableCESPollerDaemons
            fi
			exit 0
			;;
		s)
			rheldvd	
			exit 0
			;;
		v)
			purgeSQLITE	
			exit 0
			;;
		z)
			check_distro
			exit 0
			;;
        k)
            skill
            exit 0
            ;;
        i)
            FROMSRC=1
            sinstall 
            fixHtpasswdPath
            exit 0
            ;;
        d)
            remove 
            exit 0
            ;;
        u)
            supdate 
            exit 0
            ;;
        b)
            backup 
            exit 0
            ;;
        r)
            restore $OPTARG 
            exit 0
            ;;
        l)
            backuplist 
            exit 0
            ;;
		c)
			compresslogs
			exit 0
			;;
		h)
			shelp	
			exit 0
			;;
    esac
done
usage
exit 0

