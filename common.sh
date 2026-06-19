#!/bin/bash

LOGS_FOLDER="var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"

USERID=$(id -u)
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
 R="\e[31m"
 G="\e[32m"
 Y="\e[33m"
 N="\e[0m"

echo -e "$timestamp script started"

check_root(){
 if [ $USERID -ne 0 ]; then
    echo -e "$timestamp $R please run the script with root access $N" | tee -a $LOGS_FILE
    exit 1 
 fi
}
 validate() {
     if [ $1 -ne 0 ]; then
        echo -e "$timestamp $2... $R failure $N" | tee -a $LOGS_FILE
        exit 1
     else 
        echo -e "$timestamp $2...$G success $N" | tee -a $LOGS_FILE
    fi
 }

 print_total_time(){
    echo -e "$timestamp script executed in $G $SECONDS seconds"
 }

app_setup(){
id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
 validate $? "creating roboshop system user"
else
echo -e "system user roboshop already created...$Y skipping $N"
fi
 rm -rf /app
 validate $? "removing existing code"

 rm -rf /tmp/$app_name.zip
 validate $? "removed $app_name zip"

 mkdir -p /app &>>$LOGS_FILE
 validate $? "creating app directory"

 curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip 
cd /app 
unzip /tmp/$app_name.zip
validate $? "downloaded and extracted $app_name code"
}

nodejs_setup(){
 dnf module disable nodejs -y &>>$LOGS_FILE
 dnf module enable nodejs:20 -y &>>$LOGS_FILE
 dnf install nodejs -y &>>$LOGS_FILE
 validate $? "Installing NodeJS:20"

npm install &>>$LOGS_FILE
validate $? "installing nodejs dependencies"
}

systemd_setup(){
  cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
  validate $? "created systemctl service"

systemctl daemon-reload
systemctl enable $app_name
validate $? "enabled $app_name"
}

app_restart(){
    systemctl restart $app_name &>>$LOGS_FILE
    validate $? "Restarting $app_name"
}