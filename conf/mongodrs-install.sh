#!/bin/bash

# 实现复制集
# Usage mongodrs-install.sh install/remove [#name] [--p p1 p2 p3]



RS_Install()
{
	Port="0"
	ConfFiles=""
	DataDirs=""
	PidFiles=""
	PortList=""
	for arg in ${Rs_Args} ; do
		if [ "${Port}" = "1" ]; then
			if echo "${arg}" | grep -q "^--"; then
				Port="0"
			else
				\cp /etc/mongod.conf /etc/mongod-$arg.conf
				sed -i "s#/var/log/mongodb/mongod.log#/var/log/mongodb/mongod-$arg.log#g" /etc/mongod-$arg.conf
				sed -i "s#/var/lib/mongo#/var/lib/mongo-$arg#g" /etc/mongod-$arg.conf
				sed -i "s#/var/run/mongodb/mongod.pid#/var/run/mongodb/mongod-$arg.pid#g" /etc/mongod-$arg.conf
				sed -i "s/port: 27017/port: $arg/g" /etc/mongod-$arg.conf
				if [ "${RS_Shard}" = 'y' ]; then
					cat >> /etc/mongod-$arg.conf<<EOF
replication:
  replSetName: ${Replica_Set_Name}
sharding:
  clusterRole: shardsvr
EOF
				else
					cat >> /etc/mongod-$arg.conf<<EOF
replication:
  replSetName: ${Replica_Set_Name}
EOF
				fi
				if [ -z "${ConfFiles}" ]; then
					ConfFiles="/etc/mongod-$arg.conf"
				else
					ConfFiles="${ConfFiles} /etc/mongod-$arg.conf"
				fi
				if [ -z "${DataDirs}" ]; then
					DataDirs="/var/lib/mongo-$arg"
				else
					DataDirs="${DataDirs} /var/lib/mongo-$arg"
				fi
				if [ -z "${PidFiles}" ]; then
					PidFiles="/var/run/mongodb/mongod-$arg.pid"
				else
					PidFiles="${PidFiles} /var/run/mongodb/mongod-$arg.pid"
				fi
				if [ -z "${PortList}" ]; then
					PortList="${arg}"
				else
					PortList="${PortList} ${arg}"
				fi
			fi
		fi
		if [ "${arg}" = "--p" ]; then
			Port="1"
		fi
	done

	\cp /etc/init.d.mongodrs.conf /etc/init.d/mongodrs
    
	sed -i "s#{{CONFIGFILE}}#${ConfFiles}#g" /etc/init.d/mongodrs
	sed -i "s#{{DATADIRS}}#${DataDirs}#g" /etc/init.d/mongodrs
	sed -i "s#{{PIDFILE}}#${PidFiles}#g" /etc/init.d/mongodrs
	sed -i "s#{{PORTS}}#${PortList}#g" /etc/init.d/mongodrs
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



