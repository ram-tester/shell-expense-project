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

mkdir -p $LOGS_FOLDER

echo "script starts executing at: $TIMESTAMP" &>>$LOG_FILE_NAME
CHECK_ROOT

dnf install nginx -y &>>LOG_FILE_NAME
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>LOG_FILE_NAME
VALIDATE $? "Enabling nginx"

systemctl start nginx &>>LOG_FILE_NAME
VALIDATE $? "start nginx"

rm -rf /usr/share/nginx/html/*  &>>LOG_FILE_NAME
VALIDATE $? "Removing old existed data"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip  &>>LOG_FILE_NAME
VALIDATE $? "downloading latest code"

cd /usr/share/nginx/html  &>>LOG_FILE_NAME
VALIDATE $? "moving html dir"

unzip /tmp/frontend.zip  &>>LOG_FILE_NAME
VALIDATE $? "unzip to tmp folder"

cp /home/ec2-user/shell-expense-project/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "copy the config"

systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restart nginx server"
