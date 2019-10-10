#!/bin/bash

NET_NAME="net_4640"
VM_NAME="VM_ACIT4640"
PXE_NAME="PXE_4640"

clean_all () {
	vbmg natnetwork remove --netname "$NET_NAME"
	vbmg unregistervm "$VM_NAME" --delete
}

vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

create_network () {
	vbmg natnetwork add --netname "$NET_NAME" \
		--network 192.168.250.0/24 \
		--dhcp off \
		--enable \
		--port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
		--port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
		--port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" \
		--port-forward-4 "ssh2:tcp:[]:50222:[192.168.250.200]:22"
}

create_vm () {
	vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
	vbmg modifyvm "$VM_NAME" --memory 2048 --nic1 natnetwork \
		--cableconnected1 on \
		--nat-network1 "$NET_NAME" \
        --boot1 disk --boot2 net --boot3 none --boot4 none \
		--audio none

	SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
	VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
	VM_DIR=$(dirname "$VBOX_FILE")
	
	vbmg createmedium disk --filename "$VM_DIR"/"$VM_NAME".vdi \
		--format VDI \
		--size 10000

	vbmg storagectl "$VM_NAME" --name "Controller1" --add sata \
		--bootable on

	vbmg storageattach "$VM_NAME" --storagectl "Controller1" \
		--port 0 --device 0 \
		--type hdd \
		--medium "$VM_DIR"/"$VM_NAME".vdi

	vbmg storageattach "$VM_NAME" --storagectl "Controller1" \
		--type dvddrive --medium emptydrive \
		--port 1 --device 0
}

clean_all
create_network
create_vm


setup_pxe () {
    vbmg modifyvm "$PXE_NAME" --nat-network1 "$NET_NAME"
    vbmg startvm "$PXE_NAME"

    chmod 600 acit_admin_id_rsa

    while /bin/true; do
        ssh -i acit_admin_id_rsa -p 50222 -o ConnectTimeout=2 -o StrictHostKeyChecking=no -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "PXE server is not up, sleeping..."
                sleep 2
        else
                break
        fi
    done
}

pxe_files () {
    ssh -i acit_admin_id_rsa -p 50222 admin@localhost sudo chown admin /var/www/lighttpd
    scp -i acit_admin_id_rsa -P 50222 ks.cfg admin@localhost:/var/www/lighttpd
    scp -r -i ~/.ssh/acit_admin_id_rsa -P 50222 support admin@localhost:/var/www/lighttpd
    scp -r -i ~/.ssh/acit_admin_id_rsa -P 50222 app_setup.sh admin@localhost:/var/www/lighttpd/support
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 admin@localhost sudo chown -R lighttpd:wheel /var/www/lighttpd
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 admin@localhost sudo chown -R admin:admin /var/www/lighttpd/support
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 admin@localhost sudo chmod 755 /var/www/lighttpd/support/nginx.conf
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 admin@localhost sudo chmod 755 /var/www/lighttpd/support/todoapp.service
    ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 admin@localhost sudo chmod 755 /var/www/lighttpd/support/app_setup.sh
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 admin@localhost sudo chmod 755 /var/www/lighttpd/ks.cfg
}

start_vm () {
    vbmg startvm "$VM_NAME"
}

setup_pxe
pxe_files
start_vm