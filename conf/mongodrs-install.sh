#!/bin/bash

# 实现复制集
# Usage mongodrs-install.sh install/remove [#name] [--p p1 p2 p3]

RS_Init_Config()
{
	local port=$1
	\cp /etc/mongod.conf /etc/mongod-$arg.conf
	sed -i "s#/var/log/mongodb/mongod.log#/var/log/mongodb/mongod-$port.log#g" /etc/mongod-$port.conf
	sed -i "s#/var/lib/mongo#/var/lib/mongo-$port#g" /etc/mongod-$port.conf
	sed -i "s#/var/run/mongodb/mongod.pid#/var/run/mongodb/mongod-$arg.pid#g" /etc/mongod-$port.conf
	sed -i "s/port: 27017/port: $port/g" /etc/mongod-$port.conf
	if [ "${RS_Shard}" = 'y' ]; then
		cat >> /etc/mongod-$port.conf<<EOF
replication:
replSetName: ${Replica_Set_Name}
sharding:
clusterRole: shardsvr
EOF
	else
		cat >> /etc/mongod-$port.conf<<EOF
replication:
replSetName: ${Replica_Set_Name}
EOF
	fi
	
	ConfFiles="${ConfFiles} /etc/mongod-$port.conf"
	DataDirs="${DataDirs} /var/lib/mongo-$port"
	PidFiles="${PidFiles} /var/run/mongodb/mongod-$port.pid"
	PortList="${PortList} ${port}"
}

RS_Install()
{
	Port_Found="0"
	ConfFiles=""
	DataDirs=""
	PidFiles=""
	PortList=""
	for arg in ${Rs_Args} ; do
		if [ "${Port_Found}" = "1" ]; then
			if echo "${arg}" | grep -q "^--"; then
				Port_Found="0"
			else
				RS_Init_Config $arg
			fi
		fi
		if [ "${arg}" = "--p" ]; then
			Port_Found="1"
		fi
	done

	\cp /etc/init.d.mongodrs.conf /etc/init.d/mongodrs
    
	sed -i "s#{{CONFIGFILE}}#${ConfFiles:1}#g" /etc/init.d/mongodrs
	sed -i "s#{{DATADIRS}}#${DataDirs:1}#g" /etc/init.d/mongodrs
	sed -i "s#{{PIDFILE}}#${PidFiles:1}#g" /etc/init.d/mongodrs
	sed -i "s#{{PORTS}}#${PortList:1}#g" /etc/init.d/mongodrs
	sed -i "s/{{REPLICASETNAME}}/${Replica_Set_Name}/g" /etc/init.d/mongodrs

	chmod +x /etc/init.d/mongodrs
}

RS_Remove()
{
	rm -rf /var/log/mongodb/mongod-*.log
	# rm -rf /var/lib/mongo-*
	rm -rf /var/run/mongodb/mongod-*.pid
	rm -rf /etc/mongod-*.conf
}

Rs_Args=$@
Cur_Dir=$(pwd)
RS_Shard="n"

case "$1" in
    install)
		Replica_Set_Name=$2
        echo "Install ${Replica_Set_Name}... "
        RS_Install
        /etc/init.d/mongodrs start
        ;;
    remove)
        echo -n "Stoping $NAME... "
        /etc/init.d/mongodrs stop
        sleep 1
        RS_Remove
        ;;
    shinstall)
		RS_Shard="y"
		Replica_Set_Name=$2
        echo "Install ${Replica_Set_Name}... "
        RS_Install
        ;;
    *)
        echo "Usage: $0 {install|remove}"
        exit 1
        ;;

esac



