#!/bin/bash

#関数定義
##エラー処理
function err() {
  if [ $# -eq 1 ] ; then
      echo "ERROR : "${1}
  else
      echo "ERROR : unknown error"
  fi
}

##マシン名生成
function create_name() {
  
  local name_bef="kvm_centos7_"
  local name_aft="`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1 | sort | uniq`"
  
  echo "${name_bef}${name_aft}"
}

##ファイルコピー(Scp)
function copy_file()
{
  #変数定義
  local HOST=$1
  local USER=$2
  local PASS=$3
  local TARGET_FILE=$4
  local TARGET_DIR=$5
  
  expect -c "
  spawn scp ${TARGET_FILE} ${USER}@${HOST}:${TARGET_DIR}
  expect {
  \"Are you sure you want to continue connecting (yes/no)? \" {
  send \"yes\r\"
  expect \"password:\"
  send \"${PASS}\r\"
  } \"password:\" {
  send \"${PASS}\r\"
  }
  }
  interact
  "
  
}

##ファイルの削除(Remove)
function remove_file()
{
  #変数定義
  local HOST=$1
  local USER=$2
  local PASS=$3
  local TARGET_FILE=$4

  auto_ssh ${HOST} ${USER} ${PASS} rm -rf ${TARGET_FILE}
  
  if [ $? -eq 0 ]; then
    return 0
  else
    return 1
  fi
  
}

##仮想マシンの生成・立ち上げ(virt-install)
function create_vm()
{
  #変数定義
  local NAME=`create_name`
  local DISK_SIZE="8"
  local DISK_PATH="/var/kvm/disk/${NAME}/disk.qcow2,format=qcow2,size=${DISK_SIZE}"
  local NETWORK_BRIDGE="virbr0"
  local ARCH="x86_64"
  local OS_TYPE="linux"

  local ORI_FILE="/var/kvm/disk/kvm_centos7"
  local CHK_DIR="/var/kvm/disk/${NAME}"
  local kick_start="/tmp/centos7.ks.cfg"


  if [ ${1} -eq 0 ]; then
    VCPUS="1"
  else
    VCPUS=$1
  fi
  
  if [ ! -e ${CHK_DIR} ]; then
    cp -pr ${ORI_FILE} ${CHK_DIR} >/dev/null 2>&1
  fi
  
  if [ ${2} -eq 0 ]; then
    RAM="1024"
  else
    RAM=$2
  fi

  #auto_ssh ${HOST} ${USER} ${PASS} virt-install \
  virt-install  --name=${NAME} --vcpus=${VCPUS} --ram=${RAM} --disk path=${DISK_PATH} --network bridge=${NETWORK_BRIDGE} --arch=${ARCH} --os-type=${OS_TYPE} --serial=pty --location=/var/kvm/iso/CentOS-7-x86_64-Minimal-1503-01.iso --nographics --initrd-inject=${kick_start} --extra-args='inst.ks=file:${kick_start} console=ttyS0'  >/dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    echo ${NAME}
  else
    return 1
  fi
  
}

##仮想マシンの削除(virsh undefine)
function delete_vm() {
  vm_code=$1
  
  rm -rf /var/kvm/disk/${vm_code} >/dev/null 2>&1
  
  virsh undefine ${vm_code} >/dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    echo "SUCCESS"
  else
    return 1
  fi
}

##仮想マシンのスタート(virsh start)
function start_vm() {
  vm_code=$1

  virsh start ${vm_code} >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "SUCCESS"
  else
    return 1
  fi
}

##仮想マシンの停止(virsh destroy)
function destroy_vm() {
  vm_code=$1

  virsh destroy ${vm_code} >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "SUCCESS"
  else
    return 1
  fi
}

#サーバの最大メモリを取得
function get_max_memory() {
  local management_file="${1}/mng_server.txt"
  local server_addr=$2

  local ret=`cat ${management_file} | grep ${server_addr} | awk -F' ' '{print $2}'`
  
  if [ $? -eq 0 ]; then
    echo ${ret}
  else
    return 1
  fi
  
}

#貸し出し済みのメモリを取得
function get_memory() {
  local management_file="${1}/mng_VM.txt"
  local server_addr=$2
  
  local ret=`cat ${management_file} | grep ${server_addr} | awk '{total = total + $3} END{print total}'`
    
  if [ $? -eq 0 ]; then
    echo ${ret}
  else
    return 1
  fi
  
}

#サーバの最大ディスク容量を取得
function get_max_disk() {
  local management_file="${1}/mng_server.txt"
  local server_addr=$2

  local ret=`cat ${management_file} | grep ${server_addr} | awk -F' ' '{print $3}'`
  
  if [ $? -eq 0 ]; then
    echo ${ret}
  else
    return 1
  fi
  
}

#貸し出し済みのディスクを取得
function get_disk() {
  local management_file="${1}/mng_VM.txt"
  local server_addr=$2
  
  local ret=`cat ${management_file} | grep ${server_addr} | awk '{total = total + $4} END{print total}'`
    
  if [ $? -eq 0 ]; then
    echo ${ret}
  else
    return 1
  fi
  
}

