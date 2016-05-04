#master: docker run --rm -it -p 8081:8081 -p 2181:2181 -p 9092:9092 -e PUBLIC_IP=`docker-machine ip` --name master -h master griesbacher/flink-cluster
#worker: docker run --rm -it --link master:master -h worker1 --name worker1 griesbacher/flink-cluster
#@master: start-cluster.sh

FROM debian:8

MAINTAINER Philip Griesbacher, Philip.Griesbacher@student.hs-rm.de

RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list && echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
RUN apt-get update
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install oracle-java8-installer oracle-java8-set-default curl netcat openssh-server
ENV JAVA_HOME="/usr/lib/jvm/java-8-oracle/"

RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
COPY ./ssh /root/.ssh/
RUN chmod 700 /root/.ssh && chmod 600 /root/.ssh/*

RUN curl -s http://ftp.fau.de/apache/flink/flink-1.0.1/flink-1.0.1-bin-hadoop27-scala_2.10.tgz | tar -xz -C /usr/local/ && mv /usr/local/flink-* /usr/local/flink && find /usr/local/flink/ -name '*.bat' -delete
ENV PATH=$PATH:/usr/local/flink/bin
RUN sed -i 's#$slave#$slave -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no#' /usr/local/flink/bin/start-cluster.sh && sed -i 's#$master#$master -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no#' /usr/local/flink/bin/start-cluster.sh
RUN sed -i 's#$slave#$slave -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no#' /usr/local/flink/bin/stop-cluster.sh && sed -i 's#$master#$master -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no#' /usr/local/flink/bin/stop-cluster.sh

RUN curl -s http://ftp.fau.de/apache/kafka/0.9.0.0/kafka_2.11-0.9.0.0.tgz | tar -xz -C /usr/local/ && mv /usr/local/kafka* /usr/local/kafka && find /usr/local/kafka/ -name '*.bat' -delete
ENV PATH=$PATH:/usr/local/kafka/bin

COPY ./entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r//' /entrypoint.sh #Just for Windowssystems...

EXPOSE 22 2181 6123 8081 9092

ENTRYPOINT ["/entrypoint.sh"]