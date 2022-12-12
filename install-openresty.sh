#!/bin/bash

__current_dir=$(
   cd "$(dirname "$0")"
   pwd
)
# args=$@
# __os=`uname -a`

# function log() {
#    message="[install-openresty Log]: $1 "
#    echo -e "${message}" 2>&1 | tee -a ${__current_dir}/install.log
# }



if which nginx >/dev/null; then
   echo "检测到 nginx 已安装请先卸载"
     read -p "是否卸载nginx? [n/y]" __choice </dev/tty
      case "$__choice" in
         y|Y) echo "继续安装...";;
         n|N) echo "退出安装..."&exit;;
         *) echo "退出安装..."&exit;;
      esac
        systemctl stop nginx 2>$1
        rm -rf /usr/sbin/nginx 2>$1
        rm -rf /etc/nginx  2>$1
        rm -rf /etc/init.d/nginx 2>$1

        if which yum >/dev/null; then
        yum remove nginx 2>$1
        else
        apt remove nginx 2>$1
        fi
            if [ $? -ne 0 ]; then
            echo "卸载失败"
            exit
            fi 
         echo "卸载成功"
fi


echo "安装前置依赖"

if which yum >/dev/null; then
yum install libpcre3-dev libssl-dev perl make build-essential curl zlib1g-dev 2>&1
else
apt install libpcre3-dev libssl-dev perl make build-essential curl zlib1g-dev 2>&1
fi



if [ $? -ne 0 ]; then
    echo "安装前置依赖失败"
    exit
fi

echo "下载文件"

wget -P ${__current_dir} https://openresty.org/download/openresty-1.21.4.1.tar.gz 2>&1

if [ ! -f openresty-1.21.4.1.tar.gz ];then
echo "下载https://openresty.org/download/openresty-1.21.4.1.tar.gz，收到下载"
exit
fi
echo "开始解压"

tar -xzvf ${__current_dir}/openresty-1.21.4.1.tar.gz 2>&1

if [ ! -d ${__current_dir}/openresty-1.21.4.1];then
echo "解压失败"
exit
fi

cd ${__current_dir}/openresty-1.21.4.1 2>&1


echo "开始编译安装"

./configure --prefix=/usr/local/openresty --with-http_stub_status_module --with-http_gzip_static_module --with-luajit 2>&1

if [ $? -ne 0 ]; then
    echo "编译失败"
    exit
fi
echo "编译成功" 2>&1

echo "执行安装" 2>&1

echo "make -j4"
make -j4 2>&1

if [ $? -ne 0 ]; then
    echo "make -j4 失败"
    exit
fi

echo "make install"
make install 2>&1
if [ $? -ne 0 ]; then
    echo "make install 失败"
    exit
fi

echo "设置启动脚本"
echo "创建nginx.service"
touch /usr/lib/systemd/system/nginx.service 2>&1

echo "[Unit]
Description=OpenResty
After=network.target

[Service]
Type=forking
PIDFile=/usr/local/openresty/nginx/logs/nginx.pid
ExecStartPre=/usr/local/openresty/nginx/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/local/openresty/nginx/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/local/openresty/nginx/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /usr/local/openresty/nginx/logs/nginx.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
" >> /usr/lib/systemd/system/nginx.service 2>&1

echo "ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx
" 2>&1

echo "重新加载服务的配置文件"

systemctl daemon-reload  2>&1
echo "# 设置自启动"

systemctl enable nginx  2>&1