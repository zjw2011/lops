#!/bin/bash

MemoryAllocator_Selection()
{
#which Memory Allocator do you want to install?
    if [ -z ${SelectMalloc} ]; then
        echo "==========================="

        SelectMalloc="1"
        Echo_Yellow "You have 3 options for your Memory Allocator install."
        echo "1: Don't install Memory Allocator. (Default)"
        echo "2: Install Jemalloc"
        echo "3: Install TCMalloc"
        read -p "Enter your choice (1, 2 or 3): " SelectMalloc
    fi

    case "${SelectMalloc}" in
    1)
        echo "You will install not install Memory Allocator."
        ;;
    2)
        echo "You will install JeMalloc"
        ;;
    3)
        echo "You will Install TCMalloc"
        ;;
    *)
        echo "No input,You will not install Memory Allocator."
        SelectMalloc="1"
    esac

    if [ "${SelectMalloc}" =  "1" ]; then
        MySQL51MAOpt=''
        MySQLMAOpt=''
        NginxMAOpt=''
    elif [ "${SelectMalloc}" =  "2" ]; then
        MySQL51MAOpt='--with-mysqld-ldflags=-ljemalloc'
        MySQLMAOpt='[mysqld_safe]
malloc-lib=/usr/lib/libjemalloc.so'
        NginxMAOpt="--with-ld-opt='-ljemalloc'"
    elif [ "${SelectMalloc}" =  "3" ]; then
        MySQL51MAOpt='--with-mysqld-ldflags=-ltcmalloc'
        MySQLMAOpt='[mysqld_safe]
malloc-lib=/usr/lib/libtcmalloc.so'
        NginxMAOpt='--with-google_perftools_module'
    fi
}

Kill_PM()
{
    if ps aux | grep "yum" | grep -qv "grep"; then
        if [ -s /usr/bin/killall ]; then
            killall yum
        else
            kill `pidof yum`
        fi
    elif ps aux | grep "apt-get" | grep -qv "grep"; then
        if [ -s /usr/bin/killall ]; then
            killall apt-get
        else
            kill `pidof apt-get`
        fi
    fi
}

Press_Install()
{
    if [ -z ${LNMP_Auto} ]; then
        echo ""
        Echo_Green "Press any key to install...or Press Ctrl+c to cancel"
        OLDCONFIG=`stty -g`
        stty -icanon -echo min 1 time 0
        dd count=1 2>/dev/null
        stty ${OLDCONFIG}
    fi
    Echo_Yellow "${Safe_Remove_Files}"
    Kill_PM
}

Press_Start()
{
    echo ""
    Echo_Green "Press any key to start...or Press Ctrl+c to cancel"
    OLDCONFIG=`stty -g`
    stty -icanon -echo min 1 time 0
    dd count=1 2>/dev/null
    stty ${OLDCONFIG}
}

Install_LSB()
{
    echo "[+] Installing lsb..."
    if [ "$PM" = "yum" ]; then
        yum -y install redhat-lsb
    elif [ "$PM" = "apt" ]; then
        apt-get update
        apt-get --no-install-recommends install -y lsb-release
    fi
}

Get_Dist_Version()
{
    if [ -s /usr/bin/python3 ]; then
        eval ${DISTRO}_Version=`/usr/bin/python3 -c 'import platform; print(platform.linux_distribution()[1])'`
    elif [ -s /usr/bin/python2 ]; then
        eval ${DISTRO}_Version=`/usr/bin/python2 -c 'import platform; print platform.linux_distribution()[1]'`
    fi
    if [ $? -ne 0 ]; then
        Install_LSB
        eval ${DISTRO}_Version=`lsb_release -rs`
    fi
}

Get_Dist_Name()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Amazon Linux" /etc/issue || grep -Eq "Amazon Linux" /etc/*-release; then
        DISTRO='Amazon'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    elif grep -Eqi "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
        DISTRO='Deepin'
        PM='apt'
    elif grep -Eqi "Mint" /etc/issue || grep -Eq "Mint" /etc/*-release; then
        DISTRO='Mint'
        PM='apt'
    elif grep -Eqi "Kali" /etc/issue || grep -Eq "Kali" /etc/*-release; then
        DISTRO='Kali'
        PM='apt'
    else
        DISTRO='unknow'
    fi
    Get_OS_Bit
}

Get_RHEL_Version()
{
    Get_Dist_Name
    if [ "${DISTRO}" = "RHEL" ]; then
        if grep -Eqi "release 5." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 5"
            RHEL_Ver='5'
        elif grep -Eqi "release 6." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 6"
            RHEL_Ver='6'
        elif grep -Eqi "release 7." /etc/redhat-release; then
            echo "Current Version: RHEL Ver 7"
            RHEL_Ver='7'
        fi
    fi
}

Get_CentOS_Version()
{
    Get_Dist_Name
    if [ "${DISTRO}" = "CentOS" ]; then
        if grep -Eqi "release 5." /etc/redhat-release; then
            echo "Current Version: CentOS Ver 5"
            CentOS_Ver='5'
        elif grep -Eqi "release 6." /etc/redhat-release; then
            echo "Current Version: CentOS Ver 6"
            CentOS_Ver='6'
        elif grep -Eqi "release 7." /etc/redhat-release; then
            echo "Current Version: CentOS Ver 7"
            CentOS_Ver='7'
        fi
    fi
}

Get_OS_Bit()
{
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
    else
        Is_64bit='n'
    fi
}

Get_ARM()
{
    if uname -m | grep -Eqi "arm|aarch64"; then
        Is_ARM='y'
    fi
}

Tar_Cd()
{
    local FileName=$1
    local DirName=$2
    cd ${cur_dir}/src
    [[ -d "${cur_dir}/src/${DirName}" ]] && rm -rf ${cur_dir}/src/${DirName}
    echo "Uncompress ${FileName}..."
    tar zxf ${FileName}
    echo "cd ${DirName}..."
    cd ${DirName}
}

Tarj_Cd()
{
    local FileName=$1
    local DirName=$2
    cd ${cur_dir}/src
    [[ -d "${cur_dir}/src/${DirName}" ]] && rm -rf ${cur_dir}/src/${DirName}
    echo "Uncompress ${FileName}..."
    tar jxf ${FileName}
    echo "cd ${DirName}..."
    cd ${DirName}
}


Check_LOpsConf()
{
    if [ ! -s "${cur_dir}/lops.conf" ]; then
        Echo_Red "lops.conf was not exsit!"
        exit 1
    fi
}

Print_APP_Ver()
{
    echo "You will install ${Stack} stack."
    echo "Default Website Directory: ${Default_Website_Dir}"
}

Print_Sys_Info()
{
    eval echo "${DISTRO} \${${DISTRO}_Version}"
    cat /etc/issue
    cat /etc/*-release
    uname -a
    MemTotal=`free -m | grep Mem | awk '{print  $2}'`
    echo "Memory is: ${MemTotal} MB "
    df -h
}

StartUp()
{
    init_name=$1
    echo "Add ${init_name} service at system startup..."
    if [ "$PM" = "yum" ]; then
        chkconfig --add ${init_name}
        chkconfig ${init_name} on
    elif [ "$PM" = "apt" ]; then
        update-rc.d -f ${init_name} defaults
    fi
}

Remove_StartUp()
{
    init_name=$1
    echo "Removing ${init_name} service at system startup..."
    if [ "$PM" = "yum" ]; then
        chkconfig ${init_name} off
        chkconfig --del ${init_name}
    elif [ "$PM" = "apt" ]; then
        update-rc.d -f ${init_name} remove
    fi
}

Check_Mirror()
{
    if [ ! -s /usr/bin/curl ]; then
        if [ "$PM" = "yum" ]; then
            yum install -y curl
        elif [ "$PM" = "apt" ]; then
            apt-get update
            apt-get install -y curl
        fi
    fi
    country=`curl -sSk --connect-timeout 30 -m 60 https://ip.vpser.net/country`
    echo "Server Location: ${country}"
    if [ "${country}" = "" ]; then
	    country="CN"
	fi
}

Log_Install_Software()
{
    if [[ ! -z "${Software_Name}" && -s /usr/lops.install.log ]] && grep -Eqi "^${Software_Name}=" /usr/lops.install.log; then
       sed -i "s/^${Software_Name}=.*/${Software_Name}=yes/g" /usr/lops.install.log
    else
        cat >>/usr/lops.install.log<<eof
${Software_Name}=yes
eof
    fi
}

Check_Install_Software()
{
	Software_Installed='0'
    if  [[ ! -z "${Software_Name}" &&  -s /usr/lops.install.log ]] && grep -Eqi "^${Software_Name}=yes" /usr/lops.install.log; then
        Software_Installed='1'
    fi
}

Dele_Install_Software()
{
   if [[ ! -z "${Software_Name}" && -s /usr/lops.install.log ]]; then
	  sed -i "s/^${Software_Name}=.*/${Software_Name}=no/g" /usr/lops.install.log
   fi
}

Log_Install_Lib()
{
    if [[ ! -z "${Lib_Name}" && -s /usr/lops.install.log ]] && grep -Eqi "^${Lib_Name}=" /usr/lops.install.log; then
       sed -i "s/^${Lib_Name}=.*/${Lib_Name}=yes/g" /usr/lops.install.log
    else
        cat >>/usr/lops.install.log<<eof
${Lib_Name}=yes
eof
    fi
    Lib_Name=""
}

Check_Install_Lib()
{
    Lib_Installed='0'
    if  [[ ! -z "${Lib_Name}" &&  -s /usr/lops.install.log ]] && grep -Eqi "^${Lib_Name}=yes" /usr/lops.install.log; then
        Lib_Installed='1'
    fi
}

Dele_Install_Lib()
{
   if [[ ! -z "${Lib_Name}" && -s /usr/lops.install.log ]]; then
      sed -i "s/^${Lib_Name}=.*/${Lib_Name}=no/g" /usr/lops.install.log
   fi
   Lib_Name=""
}

Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

