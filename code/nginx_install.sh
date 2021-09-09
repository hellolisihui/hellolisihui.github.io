#!/usr/bin/env bash

# Nginx_Install 变量
NGINX_VERSION=${NGINX_VERSION:-1.18.0}

SOFT_DIR=/usr/local/src
INSTALL_PATH=/usr/local/nginx
NGINX_USER=nginx

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

rely wget gcc gcc-c++ make cmake pcre pcre-devel zlib zlib-devel openssl openssl-devel

# 下载 Nginx 源码
if wget -N -P $SOFT_DIR http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz;then
    action "wget nginx-${NGINX_VERSION}.tar.gz" /bin/true
else
    action "wget nginx-${NGINX_VERSION}.tar.gz" /bin/false
    exit 1
fi

if tar zxf $SOFT_DIR/nginx-${NGINX_VERSION}.tar.gz -C $SOFT_DIR;then
    action "tar zxf nginx-${NGINX_VERSION}.tar.gz" /bin/true
else
    action "tar zxf nginx-${NGINX_VERSION}.tar.gz" /bin/false
    exit 1
fi

if id $NGINX_USER >& /dev/null;then
    id $NGINX_USER
else
    useradd -s /sbin/nologin -M $NGINX_USER
fi

# 编译安装 Nginx
cd $SOFT_DIR/nginx-$NGINX_VERSION || exit
if ./configure --prefix=$INSTALL_PATH \
--user=$NGINX_USER --group=$NGINX_USER \
--conf-path=$INSTALL_PATH/conf/nginx.conf \
--pid-path=$INSTALL_PATH/logs/nginx.pid \
--http-log-path=$INSTALL_PATH/logs/access.log \
--error-log-path=$INSTALL_PATH/logs/error.log \
--http-client-body-temp-path=/var/tmp/client \
--http-fastcgi-temp-path=/var/tmp/fastcgi \
--http-proxy-temp-path=/var/tmp/proxy \
--http-scgi-temp-path=/var/tmp/scgi \
--http-uwsgi-temp-path=/var/tmp/uwsgi \
--with-http_ssl_module \
--with-http_gzip_static_module;then
    action "Configure Nginx-${NGINX_VERSION}" /bin/true
else
    action "Configure Nginx-${NGINX_VERSION}" /bin/false
    exit 1
fi

if make;then
    action "Make Nginx-${NGINX_VERSION}" /bin/true
else
    action "Make Nginx-${NGINX_VERSION}" /bin/false
    exit 1
fi

if make install;then
    action "Install Nginx-${NGINX_VERSION}" /bin/true
else
    action "Make Install Nginx-${NGINX_VERSION}" /bin/false
    exit 1
fi

# 优化执行路径
ln -s $INSTALL_PATH/sbin/nginx /usr/local/sbin/

# 添加系统服务
cat <<EOF > /usr/lib/systemd/system/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=$INSTALL_PATH/logs/nginx.pid
ExecStartPre=$INSTALL_PATH/sbin/nginx -t -c $INSTALL_PATH/conf/nginx.conf
ExecStart=$INSTALL_PATH/sbin/nginx -c $INSTALL_PATH/conf/nginx.conf
ExecReload=$INSTALL_PATH/sbin/nginx -s reload
ExecStop=$INSTALL_PATH/sbin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

chmod +x /usr/lib/systemd/system/nginx.service
systemctl daemon-reload
