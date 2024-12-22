#!/bin/bash
#
# OpenResty Build
# xujpxm@gmail.com

echo "`date` ### start OpenResty build script..."
# 基础版本信息
src_home=$(pwd)
build_home=$(pwd)/build
prefix=/usr/local/openresty
resty_version="1.25.3.2"
ngx_version="1.25.3"
ngx_proxy_connect="0.0.7"
ngx_proxy_connect_patch="102101"
upstream_check_patch="1.20.1+"
openssl="1.1.1k"
pcre="8.45"

function pre_devtools(){
    echo "`date` ### pre_devtools progress"
    yum -y install \
        perl \
        dos2unix \
        openssl-devel \
        gcc \
        gcc-c++ \
        make \
        gperftools-devel \
        curl \
        gzip \
        unzip \
        tar \
        wget \
        git 
    echo "`date` #### nginx user add"
    /usr/sbin/groupadd nginx
    /usr/sbin/useradd -g nginx nginx -s /sbin/nologin -M
}

function pre_build(){
    echo "`date` ### pre_build progress"
    test -d $build_home && rm -rf $build_home 
    mkdir -pv $prefix
    mkdir -pv $build_home 
    # download and unarchive pcre/penssl
    cd $build_home
    curl -fSL https://www.openssl.org/source/openssl-${openssl}.tar.gz -o openssl-${openssl}.tar.gz
    tar -zxvf openssl-${openssl}.tar.gz
    curl -fSL https://sourceforge.net/projects/pcre/files/pcre/${pcre}/pcre-${pcre}.tar.gz/download -o pcre-${pcre}.tar.gz
    tar -zxvf pcre-${pcre}.tar.gz \
    wget -c https://github.com/chobits/ngx_http_proxy_connect_module/archive/refs/tags/v${ngx_proxy_connect}.tar.gz -O ngx_http_proxy_connect_module-${ngx_proxy_connect}.tar.gz
    tar -zxvf ngx_http_proxy_connect_module-${ngx_proxy_connect}.tar.gz 
    git clone https://github.com/xiaokai-wang/nginx_upstream_check_module.git 
    # openresty下载
    wget -c https://openresty.org/download/openresty-${resty_version}.tar.gz 
    tar -zxvf openresty-${resty_version}.tar.gz 
}

function do_patch(){
    echo "`date` ### do_patch progress"
    cd $build_home
    cd openresty-${resty_version}/bundle/nginx-$ngx_version

    # upstream_check_module patch
    patch -p1 < $build_home/nginx_upstream_check_module/check_${upstream_check_patch}.patch
    patch -p1 < $build_home/ngx_http_proxy_connect_module-${ngx_proxy_connect}/patch/proxy_connect_rewrite_${ngx_proxy_connect_patch}.patch 
}

# 基础编译配置
resty_config_options="\
    --prefix=${prefix} \
    --user=nginx --group=nginx \
    --with-threads \
    --with-debug \
    --with-pcre-jit \
    --with-luajit \
    --with-cc-opt='-DTCP_FASTOPEN=23' \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_ssl_module \
    --with-file-aio \
    --with-http_auth_request_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_addition_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-ipv6 
    "
# 依赖编译配置
resty_config_deps="\
    --with-openssl=$build_home/openssl-${openssl} \
    --with-pcre=$build_home/pcre-${pcre} \
    --add-module=$build_home/nginx_upstream_check_module \
    --add-module=$build_home/ngx_http_proxy_connect_module-${ngx_proxy_connect} 
    "

function config_nginx(){
    echo "$(date) ### config openresty progress with config: $resty_config_options $resty_config_deps"
    cd $build_home/openresty-${resty_version}
    ./configure ${resty_config_options} ${resty_config_deps} 
}

function config_process(){
    pre_devtools
    pre_build
    do_patch
    pre_config_nginx
    config_nginx
}

config_process $@
echo "$(date) ### make && make install..."
make && make install && echo $? && echo "OpenResty build Successful!"
