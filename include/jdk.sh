#!/bin/bash

JDK_Selection()
{
    if [ -z ${SelectJDK} ]; then
        SelectJDK="1"
        Echo_Yellow "You have 1 options for your JDK install."
        echo "1: Install ${JDK8_Ver}(Default)"
        read -p "Enter your choice (1): " SelectJDK
    fi

    case "${SelectJDK}" in
    1)
        echo "You will install ${JDK8_Ver}"
        JDK_Ver="$JDK8_Ver"
        JAVA_Version='8'
        ;;
    *)
        echo "No input,You will install ${JDK8_Ver}"
        JAVA_Version='8'
        JDK_Ver="$JDK8_Ver"
        SelectJDK="1"
    esac
}

Get_TarName() {
	local JAVA_Sequence=`echo ${JDK_Ver} | awk -F'_' '{print $2}'`
	JDK_Tar_Name="jdk-${JAVA_Version}u${JAVA_Sequence}-linux"
}

Install_JDK_Policy() {
	mkdir -p ${JAVA_HOME}/lib/security
	cd ${cur_dir}/src
	if [ "${JAVA_Version}" = "8" ]; then
	    \cp -rf UnlimitedJCEPolicyJDK8/local_policy.jar ${JAVA_HOME}/lib/security/
	    \cp -rf UnlimitedJCEPolicyJDK8/local_policy.jar ${JAVA_HOME}/jre/lib/security/

	    \cp -rf UnlimitedJCEPolicyJDK8/US_export_policy.jar ${JAVA_HOME}/lib/security/
	    \cp -rf UnlimitedJCEPolicyJDK8/US_export_policy.jar ${JAVA_HOME}/jre/lib/security/
	fi
}

JDK_Stack()
{
	Software_Name='JDK'
	Check_JDK
	if [ "${JDK_Installed}" = "0" ]; then
		Press_Install
		Get_Dist_Version
    	Print_Sys_Info

		cd ${cur_dir}/src
		Get_TarName
		Install_JDK
		Log_Install_Software
		Check_JDK_Files
		cd ${cur_dir}
	fi
}

Check_JDK()
{
	JDK_Installed="0"
	Check_Install_Software
	if [ "${Software_Installed}" = "1" ]; then
		JDK_Installed="1"
	fi
}

Check_JDK_Files()
{
    isJDK=""
    echo "============================== Check install =============================="
    echo "Checking ..."
    if [[ -s /etc/profile.d/java.sh && -f ${JAVA_HOME}/bin/java ]]; then
        Echo_Green "JDK: OK"
        isJDK="ok"
    else
        Echo_Red "Error: JDK install failed."
    fi
}

Install_JDK()
{
    Echo_Blue "[+] Installing ${JDK_Ver} in ${App_Home}/java... "

    if [ "${Is_64bit}" = "y" ]; then
        Tar_Cd ${JDK_Tar_Name}-x64.tar.gz ${JDK_Ver}
    else
    	Tar_Cd ${JDK_Tar_Name}-i586.tar.gz ${JDK_Ver}
    fi

    cd ${cur_dir}/src
    JAVA_HOME=${App_Home}/java
    RM_Safe ${JAVA_HOME}
    mkdir -p ${JAVA_HOME}
    \cp -rf ${JDK_Ver}/* ${JAVA_HOME}

    if [ "${Enable_JDK_Policy}" = 'y' ]; then
    	echo "Installing Policy for JDK..."
    	Install_JDK_Policy
	fi

    RM_Safe /etc/profile.d/java.sh
	cat >/etc/profile.d/java.sh<<EOF
export JAVA_HOME=${JAVA_HOME}
export CLASSPATH=.:\$JAVA_HOME/jre/lib/rt.jar:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
export PATH=\$PATH:\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin
EOF
	source /etc/profile
}

Uninstall_JDK()
{
	Software_Name='JDK'
	Check_JDK
	if [ "${JDK_Installed}" = "1" ]; then
		RM_Safe /etc/profile.d/java.sh
		RM_Safe ${App_Home}/java
		source /etc/profile
		Dele_Install_Software
	fi
}

