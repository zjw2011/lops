#!/bin/bash

Mongodb_Info=('Mongo 4.0.x' 'Mongo 3.6.x' 'Mongo 2.x')

Mongodb_Selection()
{
    if [ -z ${SelectMongodb} ]; then
        SelectMongodb="1"
        Echo_Yellow "You have 3 options for your Mongodb install."
        echo "1: Install ${Mongodb_Info[0]}(Default)"
        echo "2: Install ${Mongodb_Info[1]}"
        echo "3: Install ${Mongodb_Info[2]}"
        read -p "Enter your choice (1, 2, 3): " SelectMongodb
    fi

    case "${SelectMongodb}" in
    1)
        echo "You will install ${Mongodb_Info[0]}"
        Mongodb_ver='4.0'
        ;;
    2)
        echo "You will install ${Mongodb_Info[1]}"
        Mongodb_ver='3.6'
        ;;
    3)
        echo "You will Install ${Mongodb_Info[2]}"
        Mongodb_ver='2'
        ;;
    *)
        echo "No input,You will install ${Mongodb_Info[0]}"
        Mongodb_ver='4.0'
        SelectMongodb="1"
    esac
}

Mongodb_Stack()
{
	Check_Install_Software "Mongodb"
	if [ "${Software_Installed}" = '1' ]; then
		Echo_Red "Error: Mongodb installed."
		exit 1
	fi
	Init_Install
    cd ${cur_dir}/src
    Install_Mongodb

    # https://docs.mongodb.com/manual/tutorial/transparent-huge-pages/index.html
    StartUp disable-transparent-hugepages
    /etc/init.d/disable-transparent-hugepages start

    systemctl enable mongod
    systemctl start mongod
    Add_Mongodb_Iptables_Rules
    Log_Install_Software 'Mongodb'
    Check_Mongodb_Files
    if [ "${isMongodb}" = "ok" ]; then
    	Print_Sucess_Info
    fi
}

Install_Mongodb()
{
	cd ${cur_dir}/yum.repos.d
	if [ "${Mongodb_ver}" = '4.0' ]; then
		\cp mongodb-org-4.0.repo /etc/yum.repos.d/
	elif [ "${Mongodb_ver}" = '3.6' ]; then
		\cp mongodb-org-3.6.repo /etc/yum.repos.d/
	elif [ "${Mongodb_ver}" = '2' ]; then
		if [ "${Is_64bit}" = 'y' ]; then
			\cp mongodb-x86_64.repo /etc/yum.repos.d/mongodb.repo
		else
			\cp mongodb-i686.repo /etc/yum.repos.d/mongodb.repo
		fi
	fi
	cd ${cur_dir}
	yum install -y mongodb-org

	\cp conf/mongod.conf /etc/mongod.conf
    \cp conf/mongos.conf /etc/mongos.conf
    \cp init.d/init.d.mongodrs /etc/init.d.mongodrs.conf
    \cp init.d/init.d.mongodsh /etc/init.d.mongodsh.conf
	# sed -i "s/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g" /etc/mongod.conf

	\cp init.d/init.d.disable-transparent-hugepages /etc/init.d/disable-transparent-hugepages
    chmod +x /etc/init.d/disable-transparent-hugepages
    \cp conf/mongodrs-install.sh /usr/bin/mongodrs-install.sh
    chmod +x /usr/bin/mongodrs-install.sh

    \cp conf/mongodsh-install.sh /usr/bin/mongodsh-install.sh
    chmod +x /usr/bin/mongodsh-install.sh
}

Add_Mongodb_Iptables_Rules()
{
    #add iptables firewall rules
    if [ -s /usr/sbin/firewalld ]; then
        # firewall-cmd --permanent --zone=public --add-interface=lo
    	firewall-cmd --permanent --zone=public --add-port=27017/tcp
    	firewall-cmd --reload
    	systemctl restart firewalld
    elif [ -s /sbin/iptables ]; then
        /sbin/iptables -I INPUT -p tcp --dport 27017 -j ACCEPT
        if [ "$PM" = "yum" ]; then
            service iptables save
            if [ -s /usr/sbin/firewalld ]; then
                systemctl stop firewalld
                systemctl disable firewalld
            fi
        elif [ "$PM" = "apt" ]; then
            iptables-save > /etc/iptables.rules
            cat >/etc/network/if-post-down.d/iptables<<EOF
#!/bin/bash
iptables-save > /etc/iptables.rules
EOF
            chmod +x /etc/network/if-post-down.d/iptables
            cat >/etc/network/if-pre-up.d/iptables<<EOF
#!/bin/bash
iptables-restore < /etc/iptables.rules
EOF
            chmod +x /etc/network/if-pre-up.d/iptables
        fi
    fi
}

Check_Mongodb_Files()
{
	isMongodb=""
    echo "============================== Check install =============================="
    echo "Checking ..."
    if [[ -d /var/lib/mongo && -d /var/log/mongodb && -s /etc/mongod.conf ]]; then
        Echo_Green "Mongodb: OK"
        isMongodb="ok"
    else
        Echo_Red "Error: Mongodb install failed."
    fi
}

Uninstall_Mongodb()
{
	echo "Stoping Mongod..."
	systemctl disable mongod
    systemctl stop mongod
    Remove_StartUp disable-transparent-hugepages
    yum erase -y $(rpm -qa | grep mongodb-org)
    
    echo "Deleting Mongodb iptables rules..."
    Dele_Mongodb_Iptables_Rules

    # 删除文件
    echo "Deleting Mongodb files..."
    Get_Mongodb_Dele_Files
    for ItFile in ${Mongodb_Dele_Files}
    do 
        rm -rf ${ItFile}
    done
    Dele_Install_Software 'Mongodb'
}

Get_Mongodb_Dele_Files()
{
	if [ -z "${Mongodb_Dele_Files}" ]; then 
		Mongodb_Dele_Files="\
/var/log/mongodb \
/var/lib/mongo \
/etc/mongod.conf \
/etc/init.d/disable-transparent-hugepages"
	fi
}

Dele_Mongodb_Iptables_Rules()
{
	if [ -s /usr/sbin/firewalld ]; then
        firewall-cmd --permanent --zone=public --remove-port=27017/tcp
        firewall-cmd --reload
    elif [ -s /sbin/iptables ]; then
        /sbin/iptables -D INPUT -p tcp --dport 27017 -j ACCEPT
    fi
}

