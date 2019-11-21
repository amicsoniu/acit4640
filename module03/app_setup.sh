#!/bin/bash

echo adding user...

add_user() {
	useradd admin
	echo "admin:$6$nP2c6R0hYk4sjdfK$yQPXG879nBLCQfl7.FJCvBTsPabX0lRfL/2EQ270jh.7PQ0uxuf.57WmYOps4GIuHyCsLTJpHCrdQNnIFvxAP/" | chpasswd
	usermod -aG wheel admin
}

add_user

sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers

echo creating ssh directory and copying files...

mkdir /home/admin/.ssh/

touch /home/admin/.ssh/authorized_keys

cat files/acit_admin_id_rsa.pub >> /home/admin/.ssh/authorized_keys

chown -R admin:admin /home/admin/.ssh

echo installing updates...

yum install epel-release vim git tcpdump curl net-tools bzip2 -y
yum update -y

echo configuring firewall...

firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=ssh
firewall-cmd --zone=public --add-service=https

firewall-cmd --runtime-to-permanent

echo disabling SELinux security layer...

setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

echo setting up MongoDB...

useradd -m -r todo-app && passwd -l todo-app

yum -y install nodejs npm
yum -y install mongodb-server

systemctl enable mongod && systemctl start mongod

echo bringing todo-app...

sudo -u todo-app -- mkdir /home/todo-app/app

sudo -u todo-app -- git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app
npm --prefix /home/todo-app/app install

sed -r -i 's/CHANGEME/acit4640/g' /home/todo-app/app/config/database.js

echo setting up nginx...

yum -y install jq
yum -y install nginx

yes | cp -rf files/nginx.conf /etc/nginx/nginx.conf
yes | cp -rf files/todoapp.service /lib/systemd/system/todoapp.service

echo enabling apps...

systemctl enable nginx
systemctl daemon-reload
systemctl enable todoapp
systemctl start todoapp