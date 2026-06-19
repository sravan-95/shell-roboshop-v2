#!/bin/bash

app_name=catalogue
source ./common.sh
check_root

app_setup
nodejs_setup

systemd_setup


cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "mongorepo added"

dnf install mongodb-mongosh -y &>>$LOGS_FILE
validate $? "installed mongodb client"

INDEX=$(mongosh --host mongodb.daws90.fun --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -lt 0 ]; then
    mongosh --host mongodb.daws90.fun </app/db/master-data.js &>>$LOGS_FILE
    validate $? "Load Products"
else    
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

print_total_time