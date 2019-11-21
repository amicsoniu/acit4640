#!/bin/bash

setup_firewall () {
	firewall-cmd --zone=public --add-service=http
	firewall-cmd --zone=public --add-service=ssh
	firewall-cmd --zone=public --add-service=https
	firewall-cmd --runtime-to-permanent
}
setup_firewall

setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

useradd -m -r todo-app && passwd -l todo-app
systemctl enable mongod && systemctl start mongod
sudo -u todo-app -- mkdir /home/todo-app/app
cp /home/admin/todoapp.service /lib/systemd/system
cp -f /home/admin/nginx.conf /etc/nginx/nginx.conf
git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app
sudo chown -R todo-app:todo-app /home/todo-app/app
npm install --prefix /home/todo-app/app

sed -r -i 's/CHANGEME/acit4640/g' /home/todo-app/app/config/database.js
sudo systemctl restart mongod

chmod a+rx /home/todo-app

systemctl enable nginx
systemctl start nginx
systemctl daemon-reload
systemctl enable todoapp
systemctl start todoapp

