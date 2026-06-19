#!/bin/bash

source ./common.sh

check_root

   cp mongo.repo /etc/yum.repos.d/mongo.repo
   validate $? "adding mongo repo"

    dnf install mongodb-org -y &>> $LOGS_FILE
    validate $? "installing mongodb"

    systemctl enable --now mongod 
    validate $? "starting and enabling mongodb"

    sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
    validate $? "allowing remote connection to mongodb"

    systemctl restart mongod
    validate $? "restarting mongodb"

print_total_time