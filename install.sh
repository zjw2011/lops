#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmj"
    exit 1
fi

cur_dir=$(pwd)
Stack=$1

. lops.conf
. include/version.sh
. include/safe.sh
. include/main.sh
. include/init.sh
. include/nginx.sh
. include/mongodb.sh
. include/end.sh

Get_Dist_Name

if [ "${DISTRO}" = "unknow" ]; then
    Echo_Red "Unable to get Linux distribution name, or do NOT support the current distribution."
    exit 1
fi

Check_LOpsConf
Check_Remove_Files

clear
echo "+------------------------------------------------------------------------+"
echo "|          LOps V${LOps_Ver} for ${DISTRO} Linux Server, Written by zjw          |"
echo "+------------------------------------------------------------------------+"
echo "|        A tool to auto-compile & install software on Linux       |"
echo "+------------------------------------------------------------------------+"
echo "|           For more information please visit https://github.com/zjw2011/lops           |"
echo "+------------------------------------------------------------------------+"

Init_Install()
{
	Press_Install
    Get_Dist_Version
    Print_Sys_Info
    Check_Hosts
    Check_Mirror
    if [ "${DISTRO}" = "RHEL" ]; then
        RHEL_Modify_Source
    fi
    if [ "${DISTRO}" = "CentOS" ]; then
        CentOS_Modify_Source
    fi
    if [ "${DISTRO}" = "Ubuntu" ]; then
        Ubuntu_Modify_Source
    fi
    Set_Timezone
    if [ "$PM" = "yum" ]; then
        CentOS_InstallNTP
        CentOS_Dependent
    elif [ "$PM" = "apt" ]; then
        Deb_InstallNTP
        Xen_Hwcap_Setting
        Deb_Dependent
    fi
    Disable_Selinux
    Check_Download
    Install_Icu4c
    if [ "${SelectMalloc}" = "2" ]; then
    	Install_Jemalloc
    elif [ "${SelectMalloc}" = "3" ]; then
    	Install_TCMalloc
    fi
    if [ "$PM" = "yum" ]; then
        CentOS_Lib_Opt
    elif [ "$PM" = "apt" ]; then
        Deb_Lib_Opt
    fi
    Install_Python_Pip
}

case "${Stack}" in
    nginx)
		MemoryAllocator_Selection
        Nginx_Stack 2>&1 | tee /root/nginx-install.log
        ;;
    db)
        Database_Stack
        ;;
    mongodb)
        Mongodb_Selection
        Mongodb_Stack 2>&1 | tee /root/mongodb-install.log
        ;;
    jdk)
		JDK_Stack
        ;;
    openresty)
		Openresty_Stack
        ;;
    *)
        Echo_Red "Usage: $0 {nginx|db|jdk|openresty|mongodb}"
        ;;
esac

exit
