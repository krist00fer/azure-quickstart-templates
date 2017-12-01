#!/bin/bash

CLUSTER_NAME=$1
SEEDS=$2
disk=sdc

fdisk -l /dev/sdc || break
fdisk /dev/sdc << EOF
n
p
1


w
EOF

mkfs -t xfs /dev/sdc1
mkdir /cassandra
mkdir /cassandra/data
mount /dev/sdc1 /cassandra/data
echo "/dev/sdc1 $mountPoint xfs defaults,nofail 0 2" >> /etc/fstab
chmod go+w /cassandra/data

echo "Update Packages"
apt-get update
apt-get -y upgrade

echo "Install JDK..."
apt-get -y install default-jdk

echo "Installed Java Version:"
java -version

echo "Add Cassandra 310 package..."
echo "deb http://www.apache.org/dist/cassandra/debian 310x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list

echo "Add Repo Keys..."
curl https://www.apache.org/dist/cassandra/KEYS | apt-key add -
apt-key adv --keyserver pool.sks-keyservers.net --recv-key A278B781FE4B2BDA

echo "Updating packgages..."
apt-get update

echo "Install cassandra..."
apt-get -y install cassandra

sed -i -e "s/cluster_name: 'Test Cluster'/cluster_name: '$CLUSTER_NAME'/g" /etc/cassandra/cassandra.yaml

sed -i -e "s/- seeds: \"127.0.0.1\"/- seeds: \"$SEEDS\"/g" /etc/cassandra/cassandra.yaml

sed -i -e "s/listen_address: localhost/#listen_address: localhost/g" /etc/cassandra/cassandra.yaml
sed -i -e "s/# listen_interface: eth0/listen_interface: eth0/g" /etc/cassandra/cassandra.yaml

sed -i -e "s#    - /var/lib/cassandra/data#    - /cassandra/data#g" /etc/cassandra/cassandra.yaml

mkdir /mnt/cassandra/commitlog
sed -i -e "s#commitlog_directory: /var/lib/cassandra/commitlog#commitlog_directory: /mnt/cassandra/commitlog#g" /etc/cassandra/cassandra.yaml

echo "Enable Cassandra"
systemctl enable cassandra.service

echo "Start Cassandra..."
systemctl start cassandra.service

echo "!!!DONE!!!"