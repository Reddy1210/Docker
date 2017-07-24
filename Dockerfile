FROM ubuntu:16.04
# Insatlling Java8
MAINTAINER prasad prasad@gmail.com
RUN apt-get update
RUN apt-get -y install default-jre
RUN apt-get -y install default-jdk
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update
#RUN rm /var/cache/apt/archives/lock
#RUN apt-get autoremove && apt-get autoclean
#RUN apt-get install -y oracle-java8-installer
RUN apt-get install -y openjdk-8-jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Installing Maven
ENV M2_HOME /usr/share/maven
RUN apt-get update
RUN apt-get -y install maven

# Installing Mangodb
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
RUN echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list
RUN apt-get update
RUN apt-get install -y mongodb-org
#properly launching MongoDB as a service
WORKDIR /etc/systemd/system/
RUN touch mongodb.service
WORKDIR /etc/systemd/system/
RUN echo "[Unit] \
    Description=High-performance, schema-free document-oriented database \
    After=network.target" > /mongodb.service && \
    echo "[Service] \
    User=mongodb \
    ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf" >> /mongodb.service && \
    echo "[Install] \
    WantedBy=multi-user.target" >> /mongodb.service
VOLUME /etc/systemd/system/
EXPOSE 27017 27018 27019 28017

# Installing Cassandra
RUN echo "deb http://www.apache.org/dist/cassandra/debian 22x main" | tee -a /etc/apt/sources.list.d/cassandra.sources.list
RUN echo "deb-src http://www.apache.org/dist/cassandra/debian 22x main" | tee -a /etc/apt/sources.list.d/cassandra.sources.list
RUN gpg --keyserver pgp.mit.edu --recv-keys F758CE318D77295D && gpg --export --armor F758CE318D77295D | apt-key add -
RUN gpg --keyserver pgp.mit.edu --recv-keys 2B5C1B00 && gpg --export --armor 2B5C1B00 | apt-key add -
RUN gpg --keyserver pgp.mit.edu --recv-keys 0353B12C && gpg --export --armor 0353B12C | apt-key add -
RUN apt-get update
RUN apt-get -y install cassandra --allow-unauthenticated
EXPOSE 7000 7001 7199 9042 9160

# Installing REDIS
RUN apt-get update
RUN apt-get install -y wget
RUN apt-get install -y build-essential tcl8.5
#ADD http://download.redis.io/releases/redis-stable.tar.gz /tmp/
#WORKDIR /tmp
#RUN tar xzvf redis-stable.tar.gz
#COPY /tmp/redis-stable.tar.gz /redis-stable
#WORKDIR redis-stable
#RUN cd redis-stable && make && make install
RUN apt-get install -y redis-server
EXPOSE 6379

# Installing MYSQL
RUN apt-get update
RUN { \
        echo debconf debconf/frontend select Noninteractive; \
        echo mysql-community-server mysql-community-server/data-dir \
            select ''; \
        echo mysql-community-server mysql-community-server/root-pass \
            password ''; \
        echo mysql-community-server mysql-community-server/re-root-pass \
            password ''; \
        echo mysql-community-server mysql-community-server/remove-test-db \
            select true; \
    } | debconf-set-selections \
    && apt-get install -y mysql-server apache2 python python-django \
        python-celery rabbitmq-server git && rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
# ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld
&& chmod 777 /var/run/mysqld

# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/mysql.conf.d/mysqld.cnf \
&& echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf
VOLUME /var/lib/mysql
#Configuring MYSQL
#RUN mysql_secure_installation -y --force=yes
EXPOSE 3306 33060