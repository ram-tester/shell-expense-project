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
mkdir -p $LOGS_FOLDER
CHECK_ROOT

dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE  $?  "mysql server installation"

systemctl enable mysqld &>>$LOG_FILE_NAME
VALIDATE  $? "Enable mysql server"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "start mysql server"

mysql -h mysql.altodevops.online -u root -pExpenseApp@1 -e 'show databases;'  &>>$LOG_FILE_NAME

if [ $? -ne 0 ]
then
  echo "root user password not setup " &>>$LOG_FILE_NAME
  mysql_secure_installation --set-root-pass ExpenseApp@1
  VALIDATE  $? "Setting root password"
else
  echo -e "mysql root password already setup $Y Skipping $N"
fi