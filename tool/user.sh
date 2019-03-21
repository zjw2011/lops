#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install user"
    exit 1
fi

Def_User_Add()
{
	Def_Create_User_Group
	useradd ${User_Shell_Home_Option} ${User_ID_Option} ${User_Home_Option} ${User_Main_Group_Option} ${User_Second_Group_Option} ${User_Name}
	Def_Create_User_Password
}

Def_User_Dele()
{
	if grep -Eqi "^${User_Name}" /etc/passwd; then
		userdel ${User_Name}
		Def_Dele_User_Group
	else
		echo "${User_Name} Not Existed!!"
		exit 1
	fi
}

Def_Create_User_Password()
{
	echo ${User_Name}:${User_Password} | chpasswd
}

Def_Create_User_Group()
{
	if [ ! -z "${User_Main_Group}" ]; then
		if grep -Eqi "^${User_Main_Group}" /etc/group; then
			echo "${User_Main_Group} has Existed"
		else
			groupadd ${User_Main_Group}
		fi
	fi
	if [ ! -z "${User_Second_Group}" ]; then
		sub_groups=(`echo ${User_Second_Group} | tr ',' ' '`)
		for i in ${sub_groups[@]} ; do
			if grep -Eqi "^${i}" /etc/group; then
				echo "${i} has Existed"
			else
		   		groupadd ${i}
			fi
		done
	fi
	
}

Def_Dele_User_Group()
{
	if [ ! -z "${User_Groups}" ]; then
		sub_groups=(`echo ${User_Groups} | tr ',' ' '`)
		for i in ${sub_groups[@]} ; do
			if grep -Eqi "^${i}" /etc/group; then
		   		groupdel ${i}
			fi
		done
	fi
}

Def_Check_User()
{
	if grep -Eqi "^${User_Name}" /etc/passwd; then
		echo "${User_Name} has Existed!!"
		exit 1
	fi
}

Def_Input_Add_User_Info()
{
	User_No_Login='n'
	read -p "Input User Name: " User_Name
	if [ -z "${User_Name}" ]; then
		echo 'Please Input User Name!'
		exit 1
	fi
	read -p "Input User Password: " User_Password
	if [ -z "${User_Password}" ]; then
		echo 'Please Input User Password!'
		exit 1
	fi
	read -p "Input User Home:/home/${User_Name} " User_Home
	read -p "Input User login shell:/bin/sh " User_Shell_Home
	read -p "Input User Main Group:${User_Name} " User_Main_Group
	read -p "Input User Second Group(,): " User_Second_Group
	read -p "Enter nologin(y|n):n " User_No_Login
	
	if [ ! -z "${User_Home}" ]; then
		User_Home_Option="-d ${User_Home}"
	fi
	if [ ! -z "${User_Shell_Home}" ]; then
		User_Shell_Home_Option="-s ${User_Shell_Home}"
	fi
	if [ ! -z "${User_Main_Group}" ]; then
		User_Main_Group_Option="-g ${User_Main_Group}"
	fi
	if [ ! -z "${User_Second_Group}" ]; then
		User_Second_Group_Option="-G ${User_Second_Group}"
	fi
	if [ "${User_No_Login}" = 'y' ]; then
		User_Shell_Home_Option="-s /sbin/nologin"
	fi
}

Def_Input_Del_User_Info()
{
	read -p "Input User Name: " User_Name
	if [ -z "${User_Name}" ]; then
		echo 'Please Input User Name'
		exit 1
	fi
	read -p "Input User Group(,): " User_Groups
}

Def_Add_Sudoers()
{
	chmod 640 /etc/sudoers
	if grep -Eqi "^${User_Name} " /etc/sudoers; then
       echo "${User_Name} is suders!!";
    else
        echo "${User_Name}    ALL=(ALL)       ALL" >> /etc/sudoers
    fi
    chmod 440 /etc/sudoers
}

Def_Dele_Sudoers()
{
	chmod 640 /etc/sudoers
	if grep -Eqi "^${User_Name} " /etc/sudoers; then
       sed -i "s/^${User_Name} .*//g" /etc/sudoers
    fi
    chmod 440 /etc/sudoers
}

action=""
echo "Enter 1 to add user"
echo "Enter 2 to delete user"
echo "Enter 3 to test add user"
echo "Enter 4 to add root user"
echo "Enter 5 to delete root user"
read -p "(Please input 1, 2, 3, 4, 5): " action

case "$action" in
1|add)
    echo "You will add User"
    Def_Input_Add_User_Info
    Def_Check_User
    Def_User_Add
    ;;
2|del)
    echo "You will delete User"
    Def_Input_Del_User_Info
    Def_User_Dele
    ;;
3|test)
	echo "You will add User"
    Def_Input_Add_User_Info
	echo "useradd ${User_Shell_Home_Option} ${User_Home_Option} ${User_Main_Group_Option} ${User_Second_Group_Option} ${User_Name}"
	echo "echo ${User_Name}:${User_Password} | chpasswd"
	;;
4|addroot)
    echo "You will add root User"
    Def_Input_Add_User_Info
    Def_Check_User
    Def_User_Add
    Def_Add_Sudoers
    ;;
5|delroot)
    echo "You will delete User"
    Def_Input_Del_User_Info
    Def_User_Dele
    Def_Dele_Sudoers
    ;;
esac

