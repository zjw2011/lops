#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

cur_dir=$(pwd)
Stack=$1

. lnmj.conf
. include/version.sh
. include/safe.sh
. include/main.sh
. include/nginx.sh
. include/mongodb.sh

shopt -s extglob

Get_Dist_Name

clear
echo "+------------------------------------------------------------------------+"
echo "|          LNMJ V${LNMP_Ver} for ${DISTRO} Linux Server, Written by jiawei          |"
echo "+------------------------------------------------------------------------+"
echo "|        A tool to auto-compile & install Nginx+MySQL+PHP on Linux       |"
echo "+------------------------------------------------------------------------+"
echo "|           For more information please visit https://lnmj.org           |"
echo "+------------------------------------------------------------------------+"

Sleep_Sec()
{
    seconds=$1
    while [ "${seconds}" -ge "0" ];do
      echo -ne "\r     \r"
      echo -n ${seconds}
      seconds=$(($seconds - 1))
      sleep 1
    done
    echo -ne "\r"
}


action=""
echo "Enter 1 to uninstall nginx"
echo "Enter 2 to uninstall mongodb"
read -p "(Please input 1, 2): " action

case "$action" in
1|nginx)
    echo "You will uninstall Nginx"
    Get_Nginx_Dele_Files
    Echo_Red "The following directory or files will be remove!"
    for ItFile in ${Nginx_Dele_Files}
    do 
        Echo_Yellow "${ItFile}"
    done
    Sleep_Sec 3
    Press_Start
    Uninstall_Nginx
    ;;
2|mongodb)
    echo "You will uninstall Mongodb"
    Get_Mongodb_Dele_Files
    Echo_Red "The following directory or files will be remove!"
    for ItFile in ${Mongodb_Dele_Files}
    do 
        Echo_Yellow "${ItFile}"
    done
    Sleep_Sec 3
    Press_Start
    Uninstall_Mongodb
    ;;
esac
