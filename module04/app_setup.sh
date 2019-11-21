#!/bin/bash

add_user() {
	useradd -m admin
	echo "admin:$6$nP2c6R0hYk4sjdfK$yQPXG879nBLCQfl7.FJCvBTsPabX0lRfL/2EQ270jh.7PQ0uxuf.57WmYOps4GIuHyCsLTJpHCrdQNnIFvxAP/" | chpasswd
	usermod -aG wheel admin
}

add_user

sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers

mkdir /home/admin/.ssh/

touch /home/admin/.ssh/authorized_keys

curl http://192.168.250.200/acit_admin_id_rsa.pub >> /home/admin/.ssh/authorized_keys

chown -R admin:admin /home/admin/.ssh

install_packages () {
	yum install epel-release vim git tcpdump curl net-tools bzip2 -y
	yum update -y
}
install_packages

setup_firewall () {
	firewall-offline-cmd --zone=public --add-service=http
	firewall-offline-cmd --zone=public --add-service=ssh
	firewall-offline-cmd --zone=public --add-service=https
	firewall-offline-cmd --runtime-to-permanent
}
setup_firewall

setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

create_todo_app_user() {
	useradd -m -r todo-app && passwd -l todo-app
	yum -y install nodejs npm
	yum -y install mongodb-server
	systemctl enable mongod && systemctl start mongod
}
create_todo_app_user

sudo -u todo-app -- mkdir /home/todo-app/app

sudo -u todo-app -- git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app
npm --prefix /home/todo-app/app install

sed -r -i 's/CHANGEME/acit4640/g' /home/todo-app/app/config/database.js

chmod a+rx /home/todo-app

yum -y install jq
yum -y install nginx

curl http://192.168.250.200/support/nginx.conf > /etc/nginx/nginx.conf
#yes | cp -rf nginx.conf /etc/nginx/nginx.conf
yes | cp -rf /tmp/todoapp.service /lib/systemd/system/todoapp.service

systemctl enable nginx
systemctl daemon-reload
systemctl enable todoapp
systemctl start todoapp