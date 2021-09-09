#!/usr/bin/env bash

# httpd_Install 变量
HTTPD_VERSION=2.4.46

SOFT_DIR=/usr/local/src
INSTALL_PATH=/usr/local/httpd

# 安装依赖环境
. /etc/init.d/functions

rely(){
  for i in "$@";do
    if yum -y install "$i";then
        action "Install $i" /bin/true
    else
        action "Install $i" /bin/false
        exit 1
    fi
  done
}

rely apr apr-devel apr-util apr-util-devel \
cyrus-sasl-devel expat-devel libdb-devel \
openldap-devel pcre pcre-devel gcc wget

if wget -N -P $SOFT_DIR http://archive.apache.org/dist/httpd/httpd-${HTTPD_VERSION}.tar.gz;then
    action "wget httpd-${HTTPD_VERSION}.tar.gz" /bin/true
else
    action "wget httpd-${HTTPD_VERSION}.tar.gz" /bin/false
    exit 1
fi

if tar zxf $SOFT_DIR/httpd-${HTTPD_VERSION}.tar.gz -C $SOFT_DIR;then
    action "tar zxf httpd-${HTTPD_VERSION}.tar.gz" /bin/true
else
    action "tar zxf httpd-${HTTPD_VERSION}.tar.gz" /bin/false
    exit 1
fi

# 编译安装 httpd
cd $SOFT_DIR/httpd-${HTTPD_VERSION} || exit
if ./configure \
--prefix=${INSTALL_PATH} \
--enable-so \
--enable-rewrite \
--enable-charset-lite \
--enable-cgi;then
    action "Configure httpd-${HTTPD_VERSION}" /bin/true
else
    action "Configure httpd-${HTTPD_VERSION}" /bin/false
    exit 1
fi

if make;then
    action "Make httpd-${HTTPD_VERSION}" /bin/true
else
    action "Make httpd-${HTTPD_VERSION}" /bin/false
    exit 1
fi

if make install;then
    action "Install httpd-${HTTPD_VERSION}" /bin/true
else
    action "Make Install httpd-${HTTPD_VERSION}" /bin/false
    exit 1
fi

# 优化执行路径
ln -s /usr/local/httpd/bin/* /usr/local/bin

# 添加系统服务
cat <<EOF > /usr/lib/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
After=network.target

[Service]
Type=forking
PIDFile=${INSTALL_PATH}/logs/httpd.pid
ExecStart=${INSTALL_PATH}/bin/apachectl $OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=graphical.target
EOF

chmod +x /usr/lib/systemd/system/httpd.service
systemctl daemon-reload
