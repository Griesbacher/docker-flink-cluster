#!/bin/bash
MASTER_IP=`ping master -c 1 | awk 'NR==2 {print $4}' | sed 's/:$//'`
sed -i "s/jobmanager.rpc.address: localhost/jobmanager.rpc.address: $MASTER_IP/" /usr/local/flink/conf/flink-conf.yaml
/etc/init.d/ssh start
if [ `hostname` == "master" ]; then
	echo "I'm master"
	/usr/local/kafka/bin/zookeeper-server-start.sh /usr/local/kafka/config/zookeeper.properties &> /tmp/zookeeper.log &
	/usr/local/kafka/bin/kafka-server-start.sh /usr/local/kafka/config/server.properties &> /tmp/kafka.log &
else
	MY_IP=`ip route get 8.8.8.8 | ip route get 8.8.8.8 | awk 'NR==1 {print $NF}'`
	echo "Me: $MY_IP"
	echo "Master: $MASTER_IP"
	ssh master "echo $MY_IP >> /usr/local/flink/conf/slaves" &> /dev/null
fi
/bin/bash