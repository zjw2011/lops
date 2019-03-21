#!/bin/bash

Redis_Info=('Redis 4.0.12')

Init_Redis()
{
	Software_Name='Redis'
}

Redis_Selection()
{
    if [ -z ${SelectRedis} ]; then
        SelectRedis="1"
        Echo_Yellow "You have 1 options for your Redis install."
        echo "1: Install ${Redis_Info[0]}(Default)"
        read -p "Enter your choice (1): " SelectRedis
    fi

    case "${SelectRedis}" in
    1)
        echo "You will install ${Redis_Info[0]}"
        Redis_Stable_Ver='redis-4.0.12'
        ;;
    *)
        echo "No input,You will install ${Redis_Info[0]}"
        Redis_Stable_Ver='redis-4.0.12'
        SelectRedis="1"
    esac

    echo "==========================="
    Echo_Yellow "Please setup port of Redis."
    read -p "Please enter:(6379) " Redis_Port
    if [ "${Redis_Port}" = "" ]; then
    	Redis_Port="6379"
    fi
}

Redis_Stack()
{
	Init_Redis
	Software_Version="${Redis_Stable_Ver}"
	Init_Install
    Install_Redis
    Add_Redis_Iptables_Rules
    Check_Redis_Files
    if [ "${isRedis}" = "ok" ]; then
    	Print_Sucess_Info
    fi
}

Install_Redis()
{
	cd ${cur_dir}/src
	Tar_Cd ${Redis_Stable_Ver}.tar.gz ${Redis_Stable_Ver}

	if [ "${Is_64bit}" = "y" ] ; then
        make PREFIX=${App_Home}/redis install
    else
        make CFLAGS="-march=i686" PREFIX=${App_Home}/redis install
    fi
    cd ${cur_dir}
    mkdir -p ${App_Home}/redis/etc/
    \cp conf/redis.conf  ${App_Home}/redis/etc/
    sed -i 's/daemonize no/daemonize yes/g' ${App_Home}/redis/etc/redis.conf
    sed -i "s/^port 6379/port ${Redis_Port}/g" ${App_Home}/redis/etc/redis.conf
    sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/g' ${App_Home}/redis/etc/redis.conf
    sed -i 's#^pidfile /var/run/redis_6379.pid#pidfile /var/run/redis.pid#g' ${App_Home}/redis/etc/redis.conf
    rm -rf ${cur_dir}/src/${Redis_Stable_Ver}

    \cp ${cur_dir}/init.d/init.d.redis /etc/init.d/redis
    sed -i "s#{{App_Home}}#${App_Home}#g" /etc/init.d/redis
    sed -i "s#{{Redis_Port}}#${Redis_Port}#g" /etc/init.d/redis
    chmod +x /etc/init.d/redis
    echo "Add to auto startup..."
    StartUp redis
    /etc/init.d/redis start
}

Add_Redis_Iptables_Rules()
{
	if [ -s /usr/sbin/firewalld ]; then
    	firewall-cmd --permanent --zone=public --add-port=${Redis_Port}/tcp
    	firewall-cmd --reload
	elif [ -s /sbin/iptables ]; then
        /sbin/iptables -A INPUT -p tcp --dport ${Redis_Port} -j ACCEPT
        if [ "$PM" = "yum" ]; then
            service iptables save
        elif [ "$PM" = "apt" ]; then
            iptables-save > /etc/iptables.rules
        fi
    fi
}

Check_Redis_Files()
{
	isRedis=""
    echo "============================== Check install =============================="
    echo "Checking ..."
    if [[ -s ${App_Home}/redis/etc/redis.conf && -s ${App_Home}/redis/bin/redis-server && -s /etc/init.d/redis ]]; then
        Echo_Green "Redis: OK"
        isRedis="ok"
    else
        Echo_Red "Error: Redis install failed."
    fi
}

Get_Redis_Dele_Files()
{
	if [ -z "${Redis_Dele_Files}" ]; then 
		Redis_Dele_Files="\
${App_Home}/redis \
/etc/init.d/redis"
	fi
}

Uninstall_Redis()
{
    Init_Redis
    echo "Stoping Redis..."
    /etc/init.d/redis stop
    Remove_StartUp redis
    
    echo "Deleting Redis iptables rules..."
    Dele_Redis_Iptables_Rules

    # 删除文件
    echo "Deleting Redis files..."
    Get_Redis_Dele_Files
    for ItFile in ${Redis_Dele_Files} ; do 
        rm -rf ${ItFile}
    done
    Dele_Install_Software
}

Dele_Redis_Iptables_Rules()
{
	if [ -s /etc/init.d/redis ]; then
		Redis_Port=`grep -Ei "^REDISPORT=.*" /etc/init.d/redis | awk -F'=' '{print $2}'`
	    if [ ! -z "${Redis_Port}" ]; then
		    if [ -s /usr/sbin/firewalld ]; then
		    	firewall-cmd --permanent --zone=public --remove-port=${Redis_Port}/tcp
		    	firewall-cmd --reload
		    	systemctl restart firewalld
			elif [ -s /sbin/iptables ]; then
		        /sbin/iptables -D INPUT -p tcp --dport ${Redis_Port} -j DROP
		        if [ "$PM" = "yum" ]; then
		            service iptables save
		        elif [ "$PM" = "apt" ]; then
		            iptables-save > /etc/iptables.rules
		        fi
		    fi
		fi
	fi
}


