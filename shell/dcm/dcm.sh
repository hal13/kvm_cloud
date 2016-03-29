#!/bin/bash

CURRENT_DIR=`dirname "${0}"`

. ${CURRENT_DIR}/dcm_auto_ssh.sh
. ${CURRENT_DIR}/dcm_function.sh


#定数定義
host1="192.168.118.149" #（仮）

USER="root"
PASS="cloud"


#引数のチェック
if [ $# -gt 3 ]; then
  echo "argument err"
  exit 1
fi

COMMAND=$1

if [ ${COMMAND} = "create" ]; then
  VCPUS=$2
  RAM=$3
else
  vm_code=$2
fi


#メイン処理
if [ ${COMMAND} = "create" ]; then
  ret=""
  #for ((i=1; i<3; i++));do
    #eval copy_file '$host'$i ${USER} ${PASS}
    max_ram=`get_max_memory ${CURRENT_DIR} ${host1}`
    res_ram=`get_memory ${CURRENT_DIR} ${host1}`
    emp_ram=`expr ${max_ram}-${res_ram}`
    
    max_disk=`get_max_disk ${CURRENT_DIR} ${host1}`
    res_disk=`get_disk ${CURRENT_DIR} ${host1}`
    emp_disk=`expr ${max_disk}-${res_disk}`
    DISK=8
    
    if [ ${emp_ram} -le 0 ] || [ ${RAM} -ge ${emp_ram} ]; then
      echo "ERROR:RAM OVER"
      exit 1
    fi
    
    if [ ${emp_disk} -le 0 ] || [ ${DISK} -ge ${emp_disk} ]; then
      echo "ERROR:DISK OVER"
      exit 1
    fi

    ret=`create_vm ${VCPUS} ${RAM}` >/dev/null 2>&1
    #ret=`eval auto_ssh '$host'$i ${USER} ${PASS} create_vm ${VCPUS} ${RAM}`
    if [ $? -eq 0 ]; then
      echo $ret
      #break
    #elif [ $i -le 2 ]; then
      #:
    else
      err $?
    fi
  #done
elif [ ${COMMAND} = "undefine" ]; then

  if [ ! ${vm_code} ]; then
    echo "argument err"
    exit 1
  fi
  ret=""
  #for ((i=1; i<3; i++));do
    destroy_vm ${vm_code} >/dev/null 2>&1
    ret=`delete_vm ${vm_code}` >/dev/null 2>&1
    #ret=`eval auto_ssh '$host'$i ${USER} ${PASS} delete_vm ${vm_code}`
    if [ $? -eq 0 ]; then
      echo $ret
      #break
    #elif [$i -le 2 ]; then
      #:
    else
      err $?
    fi
  #done
elif [ ${COMMAND} = "start" ]; then

  if [ ! ${vm_code} ]; then
    echo "argument err"
    exit 1
  fi
  ret=""
  #for ((i=1; i<3; i++));do
    ret=`start_vm ${vm_code}` >/dev/null 2>&1
    #ret=`eval auto_ssh '$host'$i ${USER} ${PASS} start_vm ${vm_code}`
    if [ $? -eq 0 ]; then
      echo $ret
      #break
    #elif [$i -le 2 ]; then
      #:
    else
      err $?
    fi
  #done
elif [ ${COMMAND} = "destroy" ]; then

  if [ ! ${vm_code} ]; then
    echo "argument err"
    exit 1
  fi
  ret=""
  #for ((i=1; i<3; i++));do
    ret=`destroy_vm ${vm_code}` >/dev/null 2>&1
    #ret=`eval auto_ssh '$host'$i ${USER} ${PASS} destroy_vm ${vm_code}`
    if [ $? -eq 0 ]; then
      echo $ret
      #break
    #elif [$i -le 2 ]; then
      #:
    else
      err $?
    fi
  #done
else
  echo "COMMAND ERROR"
  exit 1
fi
