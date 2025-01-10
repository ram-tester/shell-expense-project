#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME=$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log

CHECK_ROOT()
{
if [ $USERID -ne 0 ]
then
  echo -e "$R this package installation required root user access $N"
  exit 1
fi
}

VALIDATE(){
  if [ $1 -ne 0 ]
  then
    echo -e "$2  ... $R failed $N"
    exit 1
  else
    echo -e "$2 ... $G success $N"
  fi
}

echo "script execution started at :$TIMESTAMP"  &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y  &>>$LOG_FILE_NAME
VALIDATE $? "disabling existing nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "enabling latest nodejs"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing node js"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
  echo "expense user not exists"
  useradd expense &>>$LOG_FILE_NAME
  VALIDATE $? "user added"
else
  echo -e "user.. $Y already exists $N "
fi


mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "app dir created"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip  &>>$LOG_FILE_NAME
VALIDATE $? "Downloading backend"

cd /app
rm -rf /app/*

unzip  /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzip backend contents"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/shell-expense-project/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "insatlling mysql"

mysql -h mysql.altodevops.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "setting up schema and transactions"

systemctl daemon-reload  &>>$LOG_FILE_NAME
VALIDATE $? "daemon reload the service"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "enabling backend service"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "restart backend service"
