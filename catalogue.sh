#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD

USERID=$(id -u)
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
 R="\e[31m"
 G="\e[32m"
 Y="\e[33m"
 N="\e[0m"

 if [ $USERID -ne 0 ]; then
    echo -e "$timestamp $R please run the script with root access $N" | tee -a $LOGS_FILE
    exit 1 
 fi

 validate() {
     if [ $1 -ne 0 ]; then
        echo -e "$timestamp $2... $R failure $N" | tee -a $LOGS_FILE
        exit 1
     else 
        echo -e "$timestamp $2...$G success $N" | tee -a $LOGS_FILE
    fi
 }

 dnf module disable nodejs -y &>>$LOGS_FILE
 dnf module enable nodejs:20 -y &>>$LOGS_FILE
 dnf install nodejs -y &>>$LOGS_FILE
 validate $? "Installing NodeJS:20"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
 validate $? "creating roboshop system user"
else
echo -e "system user roboshop already created...$Y skipping $N"
fi
 rm -rf /app
 validate $? "removing existing code"

 rm -rf /tmp/catalogue.zip
 validate $? "removed catalogue zip"

 mkdir -p /app &>>$LOGS_FILE
 validate $? "creating app directory"

 curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd /app 
unzip /tmp/catalogue.zip
validate $? "downloaded and extracted catalogue code"

npm install &>>$LOGS_FILE
validate $? "installing nodejs dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
validate $? "created systemctl service"

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

systemctl enable catalogue &>>$LOGS_FILE
systemctl restart catalogue &>>$LOGS_FILE
validate $? "Restarting catalogue"
