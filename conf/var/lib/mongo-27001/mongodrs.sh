#!/bin/bash

# 实现复制集

RS_Install()
{
	Port="0"
	ConfFiles=""
	DataDirs=""
	PidFiles=""
	for arg in ${Rs_Args}
	do
		if [ "${Port}" = "1" ]; then
			\cp /etc/mongod.conf /etc/mongod-$arg.conf
			sed -i "s#/var/log/mongodb/mongod.log#/var/log/mongodb/mongod-$arg.log#g" /etc/mongod-$arg.conf
			sed -i "s#/var/lib/mongo#/var/lib/mongo-$arg#g" /etc/mongod-$arg.conf
			sed -i "s#/var/run/mongodb/mongod.pid#/var/run/mongodb/mongod-$arg.pid#g" /etc/mongod-$arg.conf
			sed -i "s/port: 27017/port: $arg/g" /etc/mongod-$arg.conf
			cat >> /etc/mongod-$arg.conf<<EOF
replication:
  replSetName: ${Replica_Set_Name}
EOF
			ConfFiles="${ConfFiles} /etc/mongod-$arg.conf"
			DataDirs="${DataDirs} /var/lib/mongo-$arg"
			PidFiles="${PidFiles} /var/run/mongodb/mongod-$arg.pid"
		fi
		if [ "${arg}" = "-p" ]; then
			Port="1"
		fi
	done

	\cp init.d/init.d.mongodrs /etc/init.d/mongodrs

	sed -i "s#{{CONFIGFILE}}#${ConfFiles}#g" /etc/init.d/mongodrs
	sed -i "s#{{DATADIRS}}#${DataDirs}#g" /etc/init.d/mongodrs
	sed -i "s#{{PIDFILE}}#${PidFiles}#g" /etc/init.d/mongodrs
}

RS_Remove()
{
	rm -rf /var/log/mongodb/mongod-*.log
	rm -rf /var/lib/mongo-*
	rm -rf /var/run/mongodb/mongod-*.pid
	rm -rf /etc/mongod-*.conf
}

Rs_Args=$@

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

        RS_Remove
        ;;

    *)
        echo "Usage: $0 {install|remove}"
        exit 1
        ;;

esac



