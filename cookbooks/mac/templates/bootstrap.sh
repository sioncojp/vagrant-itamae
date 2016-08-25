#!/bin/bash
declare -r LOGFILE="/tmp/setup_vagrant.log"
declare -r DATE=$(date +"%Y/%m/%d %H:%M:%S")

function output_log() {
  echo "${DATE}  $@" >> ${LOGFILE}
}

### ログインプロンプト変更
cat << EOF >>/etc/profile
if [ ${EUID:-${UID}} != 0 ]; then
  export PS1="[\u@\H \W]\$ "
else
  export PS1="\e[1;31m\][\u@\H \W]# \[\e[0m\]"
fi
EOF
