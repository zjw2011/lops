#!/bin/bash

Init_Python3()
{
    Software_Name='Python3'
}

Python3_Selection()
{
    if [ -z ${SelectPython3} ]; then
        SelectPython3="1"
        Echo_Yellow "You have 1 options for your Python3 install."
        echo "1: Install ${Python3_Ver}(Default)"
        read -p "Enter your choice (1): " SelectPython3
    fi

    case "${Python3_Ver}" in
    1)
        echo "You will install ${Python3_Ver}"
        Python3_Ver="$Python3_Ver"
        ;;
    *)
        echo "No input,You will install ${Python3_Ver}"
        Python3_Ver='8'
        SelectPython3="1"
    esac
}

Python3_Stack()
{
	Init_Python3
	Check_Python3
	if [ "${Python3_Installed}" = "0" ]; then
		Press_Install
		Get_Dist_Version
    	Print_Sys_Info

		cd ${cur_dir}/src
		Install_Python3
		Clean_Python3_Install
		Check_Python3_Files
		if [ "${isPython3}" = "ok" ]; then
            Print_Sucess_Info
        fi
	fi
}

Check_Python3()
{
	Python3_Installed="0"
	Check_Install_Software
	if [ "${Software_Installed}" = "1" ]; then
		Python3_Installed="1"
	fi
}

Install_Python3()
{
    #清理原来的旧的文件
    PYTHON3_HOME=${App_Home}/python3
    rm -rf ${PYTHON3_HOME}

    Echo_Blue "[+] Installing ${Python3_Ver} in ${PYTHON3_HOME}... "

    Tar_Cd ${Python3_Ver}.tgz ${Python3_Ver}

    ./configure prefix=${PYTHON3_HOME}
    Make_Install
    ln -s ${PYTHON3_HOME}/bin/python3 /usr/bin/python3
}

Check_Python3_Files()
{
	isPython3=""
    echo "============================== Check install =============================="
    echo "Checking ..."
    if [[ -s ${App_Home}/python3/bin/python3 && -s /usr/bin/python3 ]]; then
        Echo_Green "Python3: OK"
        isNginx="ok"
    else
        Echo_Red "Error: Python3 install failed."
    fi
}

Clean_Python3_Install()
{
	cd ${cur_dir}/src
    rm -rf ${cur_dir}/src/${Python3_Ver}
    cd ${cur_dir}
}

Get_Python3_Dele_Files()
{
    if [ -z "${Python3_Dele_Files}" ]; then 
        Python3_Dele_Files="\
/usr/bin/python3 \
${App_Home}/python3"
    fi
}

Dele_Python3_Files()
{
    echo "Deleting Python3 files..."
    Get_Python3_Dele_Files
    for ItFile in ${Python3_Dele_Files} ; do 
        rm -rf ${ItFile}
    done
}

Uninstall_Python3()
{
	Init_Python3
	Check_Python3
	if [ "${Python3_Installed}" = "1" ]; then
        Dele_Python3_Files
		Dele_Install_Software
	fi
}
