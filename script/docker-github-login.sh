#!/bin/bash

set -x
working_root="$1"
working_user_name="$2"

mkdir -p ${working_root}/workspace/projects; mkdir -p ${working_root}/workspace/tools
sudo mkdir -p /etc/keyin
sudo chmod 600 .ssh/vm_rsa
ssh-keygen -F github.com || ssh-keyscan github.com >> ${working_root}/.ssh/known_hosts
ssh-agent bash -c "ssh-add ${working_root}/.ssh/vm_rsa; cd ${working_root}/workspace/projects; git clone git@github.com:winsonsun/keyin.git"
#"ssh-agent bash -c 'ssh-add ~/.ssh/vm_rsa; git push origin master'
cd ${working_root}/workspace/projects/keyin; git checkout master; sudo ${working_root}/workspace/projects/keyin/common/init-vm.sh N US ubuntu; cd ~
sudo rsync -vr ${working_root}/workspace/projects/keyin/conf /etc/keyin/
sudo rsync -vr ${working_root}/workspace/projects/keyin/composeit /etc/keyin/
sudo rsync -vr /etc/keyin/conf/etc-other/limits.conf /etc/security/
sudo rsync -vr /etc/keyin/conf/etc-other/sysctl.conf /etc/sysctl.conf; sudo sysctl -p
sleep 5
sudo usermod -aG docker ${working_user_name}
cat ~/docker_passwd.txt | sudo docker login --username winsonsun --password-stdin ; sudo docker pull winsonsun/sstool:0.2; sudo docker pull winsonsun/kktool:0.2
sudo ${working_root}/workspace/projects/keyin/common/change-local-ip.sh /etc/keyin/conf/network/kcp-server.json
sudo cp ${working_root}/workspace/projects/keyin/common/docker-compose-sk.service /etc/systemd/system/; sudo systemctl daemon-reload
sudo systemctl enable docker-compose-sk.service; sudo systemctl start docker-compose-sk.service

set +x
