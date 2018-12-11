#!/bin/bash

Nginx_Stack()
{
    Software_Name='Nginx'
	Check_Install_Software
	if [ "${Software_Installed}" = "1" ]; then
		Echo_Red "Error: Nginx installed."
		exit 1
	fi

    Init_Install
    cd ${cur_dir}/src
    # Download_Files ${Download_Mirror}/web/pcre/${Pcre_Ver}.tar.bz2 ${Pcre_Ver}.tar.bz2
    Install_Pcre
    if [ `grep -L '/usr/local/lib'    '/etc/ld.so.conf'` ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
    fi
    ldconfig
    # Download_Files ${Download_Mirror}/web/nginx/${Nginx_Ver}.tar.gz ${Nginx_Ver}.tar.gz
    Install_Nginx
    StartUp nginx
    /etc/init.d/nginx start
    Add_Nginx_Iptables_Rules
    \cp ${cur_dir}/conf/index.html ${Default_Website_Dir}/index.html
    Check_Nginx_Files
    Clean_Nginx_Install
    Log_Install_Software
}

Nginx_Dependent()
{
    if [ "$PM" = "yum" ]; then
        # rpm -e httpd httpd-tools --nodeps
        # yum -y remove httpd*
        for packages in make gcc gcc-c++ gcc-g77 wget crontabs zlib zlib-devel openssl openssl-devel perl patch;
        do yum -y install $packages; done
    elif [ "$PM" = "apt" ]; then
        # apt-get update -y
        # dpkg -P apache2 apache2-doc apache2-mpm-prefork apache2-utils apache2.2-common
        # for removepackages in apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker;
        do apt-get purge -y $removepackages; done
        for packages in debian-keyring debian-archive-keyring build-essential gcc g++ make autoconf automake wget cron openssl libssl-dev zlib1g zlib1g-dev ;
        do apt-get --no-install-recommends install -y $packages; done
    fi
}

Print_Nginx_Info()
{
    echo "You will install ${Stack} stack."
    echo "${Nginx_Ver}"
    if [ "${SelectMalloc}" = "2" ]; then
        echo "${Jemalloc_Ver}"
    elif [ "${SelectMalloc}" = "3" ]; then
        echo "${TCMalloc_Ver}"
    fi
    echo "Print lops.conf infomation..."
    # echo "Download Mirror: ${Download_Mirror}"
    echo "Nginx Additional Modules: ${Nginx_Modules_Options}"
    if [ "${Enable_Nginx_Lua}" = "y" ]; then
        echo "enable Nginx Lua."
    fi
    echo "Default Website Directory: ${Default_Website_Dir}"
}

Install_Nginx_Openssl()
{
    if [ "${Enable_Nginx_Openssl}" = 'y' ]; then
        # Download_Files ${Download_Mirror}/lib/openssl/${Openssl_Ver}.tar.gz ${Openssl_Ver}.tar.gz
        [[ -d "${Openssl_Ver}" ]] && rm -rf ${Openssl_Ver}
        tar zxf ${Openssl_Ver}.tar.gz
        Nginx_With_Openssl="--with-openssl=${cur_dir}/src/${Openssl_Ver}"
    fi
}

Install_Nginx_Lua()
{
    if [ "${Enable_Nginx_Lua}" = 'y' ]; then
        echo "Installing Lua for Nginx..."
        cd ${cur_dir}/src
        # Download_Files ${Download_Mirror}/lib/lua/${Luajit_Ver}.tar.gz ${Luajit_Ver}.tar.gz
        # Download_Files ${Download_Mirror}/lib/lua/${LuaNginxModule}.tar.gz ${LuaNginxModule}.tar.gz
        # Download_Files ${Download_Mirror}/lib/lua/${NgxDevelKit}.tar.gz ${NgxDevelKit}.tar.gz

        Echo_Blue "[+] Installing ${Luajit_Ver}... "
        tar zxf ${LuaNginxModule}.tar.gz
        tar zxf ${NgxDevelKit}.tar.gz
        if [[ ! -s ${App_Home}/luajit/bin/luajit || ! -s ${App_Home}/luajit/include/luajit-2.0/luajit.h || ! -s /usr/local/luajit/lib/libluajit-5.1.so ]]; then
            Tar_Cd ${Luajit_Ver}.tar.gz ${Luajit_Ver}
            make
            make install PREFIX=${App_Home}/luajit
            cd ${cur_dir}/src
            rm -rf ${cur_dir}/src/${Luajit_Ver}
        fi

        cat > /etc/ld.so.conf.d/luajit.conf<<EOF
/usr/local/luajit/lib
EOF
        if [ "${Is_64bit}" = "y" ]; then
            ln -sf ${App_Home}/luajit/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2
        else
            ln -sf ${App_Home}/luajit/lib/libluajit-5.1.so.2 /usr/lib/libluajit-5.1.so.2
        fi
        ldconfig

        cat >/etc/profile.d/luajit.sh<<EOF
export LUAJIT_LIB=/usr/local/luajit/lib
export LUAJIT_INC=/usr/local/luajit/include/luajit-2.0
EOF

        source /etc/profile.d/luajit.sh

        Nginx_Module_Lua="--with-ld-opt=-Wl,-rpath,/usr/local/luajit/lib --add-module=${cur_dir}/src/${LuaNginxModule} --add-module=${cur_dir}/src/${NgxDevelKit}"
    fi
}

Install_Nginx()
{
    Echo_Blue "[+] Installing ${Nginx_Ver}... "
    groupadd www
    useradd -s /sbin/nologin -g www www

    cd ${cur_dir}/src
    Install_Nginx_Openssl
    Install_Nginx_Lua
    Tar_Cd ${Nginx_Ver}.tar.gz ${Nginx_Ver}
    if [[ "${DISTRO}" = "Fedora" && "${Fedora_Version}" = "28" ]]; then
        patch -p1 < ${cur_dir}/src/patch/nginx-libxcrypt.patch
    fi
    if gcc -dumpversion|grep -q "^[8]"; then
        patch -p1 < ${cur_dir}/src/patch/nginx-gcc8.patch
    fi
    if echo ${Nginx_Ver} | grep -Eqi 'nginx-[0-1].[5-8].[0-9]' || echo ${Nginx_Ver} | grep -Eqi 'nginx-1.9.[1-4]$'; then
        ./configure --user=www --group=www --prefix=${App_Home}/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_spdy_module --with-http_gzip_static_module --with-ipv6 --with-http_sub_module ${Nginx_With_Openssl} ${Nginx_Module_Lua} ${NginxMAOpt} ${Nginx_Modules_Options}
    else
        ./configure --user=www --group=www --prefix=${App_Home}/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-http_sub_module --with-stream --with-stream_ssl_module ${Nginx_With_Openssl} ${Nginx_Module_Lua} ${NginxMAOpt} ${Nginx_Modules_Options}
    fi
    Make_Install
    cd ../

    ln -sf ${App_Home}/nginx/sbin/nginx /usr/bin/nginx

    rm -f ${App_Home}/nginx/conf/nginx.conf
    cd ${cur_dir}
    # if [ "${Stack}" = "lnmpa" ]; then
    #     \cp conf/nginx_a.conf ${App_Home}/nginx/conf/nginx.conf
    #     \cp conf/proxy.conf ${App_Home}/nginx/conf/proxy.conf
    #     \cp conf/proxy-pass-php.conf ${App_Home}/nginx/conf/proxy-pass-php.conf
    # else
    #     \cp conf/nginx.conf ${App_Home}/nginx/conf/nginx.conf
    # fi
    \cp conf/nginx.conf ${App_Home}/nginx/conf/nginx.conf

    # \cp -ra conf/rewrite ${App_Home}/nginx/conf/
    # \cp conf/pathinfo.conf ${App_Home}/nginx/conf/pathinfo.conf
    # \cp conf/enable-php.conf ${App_Home}/nginx/conf/enable-php.conf
    # \cp conf/enable-php-pathinfo.conf ${App_Home}/nginx/conf/enable-php-pathinfo.conf
    # \cp conf/enable-ssl-example.conf ${App_Home}/nginx/conf/enable-ssl-example.conf
    # \cp conf/magento2-example.conf ${App_Home}/nginx/conf/magento2-example.conf
    if [ "${Enable_Nginx_Lua}" = 'y' ]; then
        sed -i "/location \/nginx_status/i\        location /lua\n        {\n            default_type text/html;\n            content_by_lua 'ngx.say\(\"hello world\"\)';\n        }\n" ${App_Home}/nginx/conf/nginx.conf
    fi

    mkdir -p ${Default_Website_Dir}
    chmod +w ${Default_Website_Dir}
    mkdir -p /home/wwwlogs
    chmod 777 /home/wwwlogs

    chown -R www:www ${Default_Website_Dir}

    mkdir ${App_Home}/nginx/conf/vhost

    if [ "${Default_Website_Dir}" != "/home/wwwroot/default" ]; then
        sed -i "s#/home/wwwroot/default#${Default_Website_Dir}#g" ${App_Home}/nginx/conf/nginx.conf
    fi

    \cp init.d/init.d.nginx /etc/init.d/nginx
    sed -i "s#{{App_Home}}#${App_Home}#g" /etc/init.d/nginx
    chmod +x /etc/init.d/nginx

    if [ "${SelectMalloc}" = "3" ]; then
        mkdir /tmp/tcmalloc
        chown -R www:www /tmp/tcmalloc
        sed -i '/nginx.pid/a\
google_perftools_profiles /tmp/tcmalloc;' ${App_Home}/nginx/conf/nginx.conf
    fi
}

Check_Nginx_Files()
{
    isNginx=""
    echo "============================== Check install =============================="
    echo "Checking ..."
    if [[ -s ${App_Home}/nginx/conf/nginx.conf && -s ${App_Home}/nginx/sbin/nginx && -s /etc/init.d/nginx ]]; then
        Echo_Green "Nginx: OK"
        isNginx="ok"
    else
        Echo_Red "Error: Nginx install failed."
    fi
}

Add_Nginx_Iptables_Rules()
{
    #add iptables firewall rules
    if [ -s /usr/sbin/firewalld ]; then
        # firewall-cmd --permanent --zone=public --add-interface=lo
    	firewall-cmd --permanent --zone=public --add-port=80/tcp
    	firewall-cmd --permanent --zone=public --add-port=443/tcp
    	firewall-cmd --reload
    	systemctl restart firewalld
    elif [ -s /sbin/iptables ]; then
        /sbin/iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        /sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT
        /sbin/iptables -I INPUT -p tcp --dport 443 -j ACCEPT
        if [ "$PM" = "yum" ]; then
            service iptables save
            if [ -s /usr/sbin/firewalld ]; then
                systemctl stop firewalld
                systemctl disable firewalld
            fi
        elif [ "$PM" = "apt" ]; then
            iptables-save > /etc/iptables.rules
            cat >/etc/network/if-post-down.d/iptables<<EOF
#!/bin/bash
iptables-save > /etc/iptables.rules
EOF
            chmod +x /etc/network/if-post-down.d/iptables
            cat >/etc/network/if-pre-up.d/iptables<<EOF
#!/bin/bash
iptables-restore < /etc/iptables.rules
EOF
            chmod +x /etc/network/if-pre-up.d/iptables
        fi
    fi
}

Clean_Nginx_Install()
{
	cd ${cur_dir}/src
    rm -rf ${cur_dir}/src/${Nginx_Ver}
    if [ "${Enable_Nginx_Openssl}" = 'y' ]; then
        [[ -d "${cur_dir}/src/${Openssl_Ver}" ]] && rm -rf ${cur_dir}/src/${Openssl_Ver}
    fi
    if [ "${Enable_Nginx_Lua}" = 'y' ]; then
    	rm -rf ${cur_dir}/src/${LuaNginxModule}
    	rm -rf ${cur_dir}/src/${NgxDevelKit}
	fi
    cd ${cur_dir}
}

Uninstall_Nginx()
{
    echo "Stoping Nginx..."
    /etc/init.d/nginx stop
    Remove_StartUp nginx
    
    echo "Deleting Nginx iptables rules..."
    Dele_Nginx_Iptables_Rules

    # 删除文件
    echo "Deleting Nginx files..."
    Get_Nginx_Dele_Files
    for ItFile in ${Nginx_Dele_Files}
    do 
        RM_Safe ${ItFile}
    done
    Dele_Install_Software 'Nginx'
}

Dele_Nginx_Iptables_Rules()
{
    if [ -s /usr/sbin/firewalld ]; then
        firewall-cmd --permanent --zone=public --remove-port=80/tcp
        firewall-cmd --permanent --zone=public --remove-port=443/tcp
        firewall-cmd --reload
    elif [ -s /sbin/iptables ]; then
        /sbin/iptables -D INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        /sbin/iptables -D INPUT -p tcp --dport 80 -j ACCEPT
        /sbin/iptables -D INPUT -p tcp --dport 443 -j ACCEPT
    fi
}

Get_Nginx_Dele_Files()
{
	if [ -z ${Nginx_Dele_Files} ]; then 
		Nginx_Dele_Files="\
${App_Home}/nginx \
/etc/init.d/nginx \
/usr/bin/nginx"

		if [ "${Enable_Nginx_Lua}" = 'y' ]; then
			Nginx_Dele_Files="${Nginx_Dele_Files} /etc/ld.so.conf.d/luajit.conf /etc/profile.d/luajit.sh"
		    if [ "${Is_64bit}" = "y" ]; then
		        Nginx_Dele_Files="${Nginx_Dele_Files} /lib64/libluajit-5.1.so.2"
		    else
		    	Nginx_Dele_Files="${Nginx_Dele_Files} /usr/lib/libluajit-5.1.so.2"
		    fi
		fi
	fi
}

