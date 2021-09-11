#!/usr/bin/env bash

# CentOS 7.6 Install MySQL 5.7.32.
MySQL_VERSION=${MySQL_VERSION:-"5.7.32"}
MySQL_DIR=${MySQL_DIR:-"/usr/local/mysql"}
MySQL_OS=${MySQL_OS:-"linux-glibc2.12-x86_64"}
MySQL_USER=${MySQL_USER:-"mysql"}
MySQL_GROUP=${MySQL_GROUP:-"mysql"}
# export MySQL_FILE=mysql-5.7.32-linux-glibc2.12-x86_64.tar.gz
MySQL_FILE=${MySQL_FILE:-"mysql-${MySQL_VERSION}-${MySQL_OS}.tar.gz"}

# Create user and group.
create_user() {
    if grep -q ${MySQL_GROUP} /etc/group;then
        echo "${yellow}[INFO]${reset}: ${MySQL_GROUP} group already exists."
    else
        groupadd ${MySQL_GROUP}
        echo "${green}[INFO]${reset}: ${MySQL_GROUP} group has been created."
    fi
    if id -u ${MySQL_USER} >& /dev/null;then
        echo "${yellow}[INFO]${reset}: ${MySQL_USER} user already exists."
    else
        useradd -r -g ${MySQL_GROUP} -s /bin/false ${MySQL_USER}
        echo "${green}[INFO]${reset}: ${MySQL_USER} user has been created."
    fi
}

# Copy files to the specified directory.
copy_file() {
    # wget https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.32-linux-glibc2.12-x86_64.tar.gz
    echo "${green}[INFO]${reset}: Extracting files to destination folder..."
    mkdir ${MySQL_DIR}
    tar zxf ${MySQL_FILE} -C ${MySQL_DIR} --strip-components 1
    mkdir ${MySQL_DIR}/mysql-files
    chown ${MySQL_USER}:${MySQL_GROUP} ${MySQL_DIR}/mysql-files
    chmod 750 ${MySQL_DIR}/mysql-files
}

# Configuration MySQL.
configuration_mysql() {
    echo "" > /etc/my.cnf
    echo "[mysqld]" >> /etc/my.cnf
    echo "basedir=${MySQL_DIR}" >> /etc/my.cnf
    echo "datadir=${MySQL_DIR}/data" >> /etc/my.cnf
    echo "socket=/tmp/mysql.sock" >> /etc/my.cnf
    echo "log-error=${MySQL_DIR}/data/mysql.err" >> /etc/my.cnf
    echo "pid-file=${MySQL_DIR}/data/mysqld.pid" >> /etc/my.cnf
}

# Initialize MySQL.
init_mysql() {
    echo "${green}[INFO]${reset}: Initializing Database..."
    ${MySQL_DIR}/bin/mysqld --initialize --user=${MySQL_USER}
    grep 'password' ${MySQL_DIR}/data/mysql.err
    cp ${MySQL_DIR}/support-files/mysql.server /etc/init.d/mysqld
    systemctl daemon-reload
    echo "${green}[INFO]${reset}: Enter \"systemctl start mysqld\" command to run MySQL Service."
    echo 'export PATH=$PATH:'"${MySQL_DIR}/bin" >> /etc/profile
    echo "${green}[INFO]${reset}: Enter \"source /etc/profile\" reload environment variables."
}

main() {
    red=$(tput setaf 1)
    green=$(tput setaf 2)
    yellow=$(tput setaf 3)
    reset=$(tput sgr0)
    if [ ! -f "${MySQL_FILE}" ];then
        echo "${red}[ERROR]${reset}: ${MySQL_FILE} file not found."
        echo "Please make sure ${MySQL_FILE} is in the current directory or Use the \"export MySQL_FILE=path/file_name\" command to specify the file location."
        exit 1
    fi
    create_user
    copy_file
    configuration_mysql
    init_mysql
}
main