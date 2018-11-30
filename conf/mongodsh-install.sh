#!/bin/bash

# 1 创建configSrv(27016) 2 创建分片(27018) 3 创建mongos(27017)
# https://docs.mongodb.com/manual/tutorial/deploy-shard-cluster/
# 需要configSrv的IP地址
# Usage mongodrs-install.sh install/remove [#name] [--config -p 123456 -h 10.211.55.100 10.211.55.101 --mongos -p 12346 ] 

Install_Mongodsh()
{
	\cp /etc/init.d.mongodsh.conf /etc/init.d/mongodsh

	sed -i "s#{{CONFIG_CONFIGFILE}}#${Config_ConfFile}#g" /etc/init.d/mongodsh
	sed -i "s#{{CONFIG_DATADIR}}#${Config_DataDir}#g" /etc/init.d/mongodsh
	sed -i "s#{{CONFIG_PIDFILE}}#${Config_PidFile}#g" /etc/init.d/mongodsh
	sed -i "s#{{CONFIG_PORT}}#${Config_Port}#g" /etc/init.d/mongodsh

	sed -i "s#{{SHARD_CONFIGFILE}}#${Shard_ConfFile}#g" /etc/init.d/mongodsh
	#sed -i "s#{{SHARD_DATADIR}}#${Shard_DataDir}#g" /etc/init.d/mongodsh
	sed -i "s#{{SHARD_PIDFILE}}#${Shard_PidFile}#g" /etc/init.d/mongodsh
	sed -i "s#{{SHARD_PORT}}#${Mongos_Port}#g" /etc/init.d/mongodsh

	sed -i "s/{{REPLICASETNAME}}/${Shard_Name}/g" /etc/init.d/mongodsh

	chmod +x /etc/init.d/mongodsh
}

Install_Mongos()
{
	Get_Arg "$SH_Args" "--mongos"
	Mongos_Result=$Result_List
	Get_Arg "$Mongos_Result" "-p"
	Mongos_Port=$Result_List
	Config_Host_And_Ports=""
	for host in ${Config_Hosts} ; do
		Config_Host_And_Ports="${Config_Host_And_Ports} ${host}:${Config_Port}"
	done

    \cp /etc/mongos.conf /etc/mongos-${Mongos_Port}.conf
	sed -i "s#/var/log/mongodb/mongod.log#/var/log/mongodb/mongos-${Mongos_Port}.log#g" /etc/mongos-${Mongos_Port}.conf
	#sed -i "s#/var/lib/mongo#/var/lib/mongo-mongos-${Mongos_Port}#g" /etc/mongos-${Mongos_Port}.conf
	sed -i "s#/var/run/mongodb/mongod.pid#/var/run/mongodb/mongos-${Mongos_Port}.pid#g" /etc/mongos-${Mongos_Port}.conf
	sed -i "s/port: 27017/port: ${Mongos_Port}/g" /etc/mongos-${Mongos_Port}.conf
	cat >> /etc/mongos-${Mongos_Port}.conf<<EOF
sharding:
  configDB: ${Shard_Name}-config/${Config_Host_And_Ports:1}
EOF
	
	Shard_ConfFile="/etc/mongos-${Mongos_Port}.conf"
	#Shard_DataDir="/var/lib/mongo-mongos-${Mongos_Port}"
	Shard_PidFile="/var/run/mongodb/mongos-${Mongos_Port}.pid"

}

Install_ConfigSrv()
{
	Get_Arg "$SH_Args" "--config"
	Config_Result=$Result_List
	Get_Arg "$Config_Result" "-p"
	Config_Port=$Result_List
	Get_Arg "$Config_Result" "-h"
	Config_Hosts=$Result_List

	if [[ -z $Config_Port || -z $Config_Hosts ]]; then
        echo "Please input [ --config -p Port -h IP1 IP2  ]"
        exit 1
    fi

    \cp /etc/mongod.conf /etc/mongod-config-${Config_Port}.conf

	sed -i "s#/var/log/mongodb/mongod.log#/var/log/mongodb/mongod-config-${Config_Port}.log#g" /etc/mongod-config-${Config_Port}.conf
	sed -i "s#/var/lib/mongo#/var/lib/mongo-config-${Config_Port}#g" /etc/mongod-config-${Config_Port}.conf
	sed -i "s#/var/run/mongodb/mongod.pid#/var/run/mongodb/mongod-config-${Config_Port}.pid#g" /etc/mongod-config-${Config_Port}.conf
	sed -i "s/port: 27017/port: ${Config_Port}/g" /etc/mongod-config-${Config_Port}.conf
	cat >> /etc/mongod-config-${Config_Port}.conf<<EOF
replication:
  replSetName: ${Shard_Name}-config
sharding:
  clusterRole: configsvr
EOF
	
	Config_ConfFile="/etc/mongod-config-${Config_Port}.conf"
	Config_DataDir="/var/lib/mongo-config-${Config_Port}"
	Config_PidFile="/var/run/mongodb/mongod-config-${Config_Port}.pid"
}

Get_Arg()
{
	local Param_List=$1
	local Start_Name=$2
	local End_Name="-"
	local Result_List_temp=""
	local Arg_Start="0"
	
	[[ echo "${Start_Name}" | grep -q "^--" ]] && End_Name="--"
	for arg in ${Param_List} ; do
		if [ "${Arg_Start}" = "1" ]; then
			if echo "${arg}" | grep -q "^${End_Name}"; then
				Arg_Start="0"
			else
				Result_List_temp="${Result_List_temp} ${arg}"
			fi
		fi
		[[ "${arg}" = "${Start_Name}" ]] && Arg_Start="1"
	done
	Result_List=${Result_List_temp:1}
}

SH_Args=$@
Cur_Dir=$(pwd)

case "$1" in
    install)
		Shard_Name=$2
        echo "Install ${Shard_Name}... "
        Install_ConfigSrv
        Install_Mongos
        Install_Mongodsh
        ;;
    *)
        echo "Usage: $0 {install}"
        exit 1
        ;;

esac

