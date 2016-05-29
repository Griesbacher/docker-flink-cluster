#!/bin/bash
MASTER_IP=`ping master -c 1 | awk 'NR==2 {print $4}' | sed 's/:$//'`
sed -i "s/jobmanager.rpc.address: localhost/jobmanager.rpc.address: $MASTER_IP/" /usr/local/flink/conf/flink-conf.yaml
/etc/init.d/ssh start
MY_IP=`ip route get 8.8.8.8 | ip route get 8.8.8.8 | awk 'NR==1 {print $NF}'`
export MASTER_IP=$MASTER_IP
export MY_IP=$MY_IP
if [ `hostname` == "master" ]; then
	echo "I'm master"
	if [ -n "$PUBLIC_IP" ]; then
		sed -i "s/#advertised.host.name.*/advertised.host.name = $PUBLIC_IP/" /usr/local/kafka/config/server.properties
		echo "delete.topic.enable=true" >> /usr/local/kafka/config/server.properties
		echo "using public ip: $PUBLIC_IP"
	fi
	/usr/local/kafka/bin/zookeeper-server-start.sh /usr/local/kafka/config/zookeeper.properties &> /tmp/zookeeper.log &
	/usr/local/kafka/bin/kafka-server-start.sh /usr/local/kafka/config/server.properties &> /tmp/kafka.log &
else
	echo "Me: $MY_IP"
	echo "Master: $MASTER_IP"
	ssh master "echo $MY_IP >> /usr/local/flink/conf/slaves" &> /dev/null
fi
/bin/bash