#!/bin/bash
# Copyright © 2024 leeson All rights reserved.

ipaddr=$(ip a | grep /24 | awk '{print $2}' | awk -F "/" '{print $1}')
appdata_path=""
compose_path=""
movie_data=""


function mainmenu() {

	echo -e " \033[33;1;5m<欢迎使用 debian12一键初始化建议脚本>\033[0m"
	echo " --------------------------------------"
	echo "        \   ^__^                       "
	echo "         \  (oo)\_______               "
	echo "            (__)\ leeson)\/            "
	echo "                ||----w |              "
	echo "                ||     ||              "
	echo " --------------------------------------"
	repo_changed=$(check_repo_changed)
	echo -e " 1 \033[36m更换国内中科大源 — $repo_changed\033[0m"
	echo -e " 2 \033[36m安装实用工具\033[0m"
	webmin_installed=$(check_webmin_installed)
	echo -e " 3 \033[32m安装webmin — $webmin_installed\033[0m"
	docker_installed=$(check_docker_installed)
	echo -e " 4 \033[32m安装docker环境 — $docker_installed\033[0m"
	dockge_installed=$(check_dockge_installed)
	echo -e " 5 \033[34m安装dockge并导入all_in配置 — $dockge_installed\033[0m"
	echo -e " 6 \033[34m一键安装以上所有内容\033[0m"
	echo -e " 7 \033[33m设置静态IP地址\033[0m"
	echo -e " 8 \033[33m备份docker应用数据\033[0m"
	echo -e " 9 \033[31m转移docker存储路径(系统盘容量不足可以尝试)\033[0m"
	isdisabled=$(isdisable_ramlog)
	echo -e " a \033[31m关掉armbian的ramlog — $isdisabled\033[0m"
	echo -----------------------------------------------
	echo -e " 0 \033[31m退出脚本\033[0m"
	read -p "请输入对应数字 > " num
	if [ -z "$num" ]; then
		echo -e "\033[31m请输入正确的数字！\033[0m"
	elif [ "$num" = 0 ]; then
		echo "退出脚本"
		exit 0
	elif [ "$num" = 1 ]; then
		change_repo
		
	elif [ "$num" = 2 ]; then
		install_tool
		
	elif [ "$num" = 3 ]; then
		install_webmin
		
	elif [ "$num" = 4 ]; then
		install_docker
		
	elif [ "$num" = 5 ]; then
		install_dockge
		
	elif [ "$num" = 6 ]; then
		onekey
		
	elif [ "$num" = 7 ]; then
		set_static_addree

	elif [ "$num" = 8 ]; then
		backup_data
	
	elif [ "$num" = 9 ]; then
	    move_docker_root	
	elif [ "$num" = a ]; then
	    disable_ramlog	
	else
		echo -e "\033[31m请输入正确的数字！\033[0m"
		
	fi
	mainmenu
	
}

function disable_ramlog() {
    if [[ -f /etc/default/armbian-ramlog ]] && [[ "$(isdisable_ramlog)" == "[未禁用]" ]]; then
        sed -i 's/ENABLED=true/ENABLED=false/' /etc/default/armbian-ramlog
        echo "禁用完成,是否重启设备?(y/n)"
        read -r yn
        if [ "$yn" == "y" ]; then
            reboot
        else
            echo "请稍后自行重启!"
        fi
    else
        echo "文件不存在或者你已经替换过了！"
    fi
}

function isdisable_ramlog() {
	if [ -f /etc/default/armbian-ramlog ];then
		ramlog=$(grep "ENABLED=" /etc/default/armbian-ramlog | awk -F'=' '{print $2}')
    	if [[ $ramlog == "false" ]]; then
        	echo "[已禁用]"
    	elif [[ $ramlog == "true" ]]; then
        	echo "[未禁用]"
    	fi
    else
        echo "[你不是armbian系统]"
    fi
}

function check_os_type(){
	if head -1 /etc/os-release | grep -c Armbian;then
		# head 返回0 不是armbian 函数返回0
		return 1
	else
		return 0
	fi
}

function check_dockge_installed() {
    if [ "$(check_docker_installed)" == "[已安装]" ] && docker ps -a --format '{{.Names}}' | grep -q '^dockge$'; then
        echo -e "[已安装]"
    else
        echo -e "[未安装]"
    fi
}

function check_docker_installed() {
    if command -v docker >/dev/null 2>&1; then
        echo -e "[已安装]"
    else
        echo -e "[未安装]"
    fi
}

function check_webmin_installed() {
    if command -v webmin >/dev/null 2>&1; then
        echo -e "[已安装]"
    else
        echo -e "[未安装]"
    fi
}

function check_repo_changed(){
	if [ -f /etc/apt/sources.list.d/debian.sources ]; then
	    echo "[已更换]"   
	else
	    echo "[未更换]"
	fi	
}


function check_daemon(){
	if [ -f /etc/docker/daemon.json ]; then
		return 0
	else
		return 1
	fi
}

function change_repo() {
	if [ "$(check_repo_changed)" == "[已更换]" ]; then
		echo "你已经换过了..."
	elif check_os_type;then
 		echo "正在替换debian源地址..."
		mv /etc/apt/sources.list /etc/apt/sources.list.bak
		cat <<EOF >/etc/apt/sources.list.d/debian.sources
Types: deb
URIs: https://mirrors.ustc.edu.cn/debian
Suites: bookworm bookworm-updates bookworm-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://mirrors.ustc.edu.cn/debian-security
Suites: bookworm-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
	echo -e " \033[32m 中科大源替换完成,正在更新系统...\033[0m"	
 	else
		echo "正在更换armbian源地址..."
		mv /etc/apt/sources.list.d/armbian.list /etc/apt/sources.list.d/armbian.list.bak
		cat <<EOF> /etc/apt/sources.list.d/armbian.list
deb [signed-by=/usr/share/keyrings/armbian.gpg] https://mirrors.ustc.edu.cn/armbian/ bookworm main bookworm-utils bookworm-desktop
EOF
		mv /etc/apt/sources.list /etc/apt/sources.list.bak
		cat <<EOF >/etc/apt/sources.list.d/debian.sources
Types: deb
URIs: https://mirrors.ustc.edu.cn/debian
Suites: bookworm bookworm-updates bookworm-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://mirrors.ustc.edu.cn/debian-security
Suites: bookworm-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
	echo -e " \033[32m 中科大源替换完成,正在更新系统...\033[0m"
	fi
apt update && apt install nala -y
}

function install_tool() {

	if [ "$(check_repo_changed)" == "[已更换]" ]; then
		echo "正在安装实用工具..."
		nala update && nala upgrade -y && nala install -y curl duf btop 
		echo -e " \033[32m您的系统挂载点信息如下\033[0m"
		duf
	else
	  echo "请先替换源..."
	fi
}

function install_webmin() {
	if [ "$(check_webmin_installed)" == "[已安装]" ]; then
		echo "你已经安装过了..."
	elif [ "$(check_repo_changed)" == "[已更换]" ]; then
		wget -q -O /tmp/setup-repos.sh https://mirror.ghproxy.com/https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
		sh /tmp/setup-repos.sh <<<"y"
		nala install -y --install-recommends webmin
		echo -e " \033[32mwebmin安装成功，请用\033[0m\033[33;1;5mhttps://$ipaddr:10000\033[0m\033[32m访问后台\033[0m"
		echo -e " \033[32m账户密码为服务器ssh的账户密码\033[0m"
	else
		echo "请先替换源..."
		
	fi
}

function install_docker() {
	if [ "$(check_docker_installed)" == "[已安装]" ]; then
		echo "你已经安装过了..."
	elif [ "$(check_repo_changed)" == "[已更换]" ]; then
		echo "正在准备安装docker服务"	
		nala update && nala install -y docker.io docker-compose
		echo "docker服务安装已经完成"
	else
		echo "请先替换源..."
	fi

}

function onekey() {
	echo "准备更改repo,安装工具,安装docker服务,安装dockge容器..."
	change_repo
	install_tool
	install_docker
	install_webmin
    install_dockge

}

function check_path_exist() {
	local path="$1"
	if [ -e "$path" ]; then
		return 0 # 路径存在返回 0 true
	else
		return 1 # 路径不存在返回 1 false
	fi
}

function install_dockge() {
	if [ "$(check_dockge_installed)" == "[已安装]" ]; then
		echo "dockge服务已经运行了..."
	elif [ "$(check_docker_installed)" == "[已安装]" ]; then
		echo "正在安装dockge管理面板..."
		while true; do
			read -p "请输入容器配置存放路径（以/开始的绝对路径 如：/disk1/appdata ）: " appdata_path
			if ! check_path_exist "$appdata_path"; then
				echo "你输入的路径不存在,请创建后再试！"
			else
				echo "你输入的绝对路径是: $appdata_path"
				break
			fi
		done
		while true; do
			read -p "请输入compose持久化存放路径(以/开始的绝对路径 如：/disk1/compose): " compose_path
			if ! check_path_exist "$compose_path"; then
				echo "你输入的路径不存在,请创建后再试！"
			else
				echo "你输入的绝对路径是: $compose_path"
				break
			fi
		done
		while true; do
			read -p "请输入媒体库的最上层存放路径(以/开始的绝对路径 如：/disk2/movie_data): " movie_data
			if ! check_path_exist "$movie_data"; then
				echo "你输入的路径不存在,请创建后再试！"
			else
				echo "你输入的绝对路径是: $movie_data"
				break
			fi
		done
		docker run -d --name dockge --restart always -p 5001:5001 -v /var/run/docker.sock:/var/run/docker.sock -v "$appdata_path"/dockge:/app/data -v "$compose_path":/opt/stacks -e DOCKGE_STACKS_DIR=/opt/stacks louislam/dockge	
	    if [[ $? == 0 ]]; then
			echo -e " \033[32mdockge安装成功，正在导入all_in配置文件......\033[0m"
			mkdir -p "$compose_path"/aio
			wget -q -O "$compose_path"/aio/docker-compose.yml https://mirror.ghproxy.com/https://raw.githubusercontent.com/leesonaa/debian_init/main/docker-compose.yml
			cat << EOF > "$compose_path"/aio/.env
DATA_PATH=$appdata_path
MOVIE_DATA=$movie_data
EOF
			echo -e " \033[32m请用\033[0m\033[33;1;5mhttp://$ipaddr:5001\033[0m\033[32m访问后台\033[0m"
			echo "================================================================="
	    else
			echo "请检查dockge是否运行成功"
			docker ps -a | grep dockge
		fi
	else
		echo "请先执行安装docker服务"
	fi
}


function set_static_addree(){

	# 获取接口
	 interface=$(ip route | grep default | awk '{print $5}')
	 mv /etc/network/interfaces /etc/network/interfaces.bak
	 read -p "请输入你要设置的静态ip地址 如(192.168.1.10) :" ip_address
	 read -p "请输入你的网关地址 如(192.168.1.1) :" ip_gateway
	 cat << EOF > /etc/network/interfaces

auto lo
iface lo inet loopback

auto $interface
iface $interface inet static
address $ip_address
netmask 255.255.255.0
gateway $ip_gateway

EOF
	read -p "静态ip已经设置完成!请问是否需要重启设备生效? (y/n):" chose
	if [ "$chose" == "y" ]; then
		echo "重启后请用新的ip登录!!!"
		reboot
	else
		echo "下次重启后会自动生效,请记住设定的IP!!!"
	fi
}


function backup_data(){
	while true; do
		read -p "请输入 <存放容器配置or存放compose文件> 的路径（以/开始的绝对路径 如：/disk1/appdata ）: " appdata_path
		if ! check_path_exist "$appdata_path"; then
			echo "你输入的路径不存在,你确定是放在这里?"
		else
			echo "你输入的容器配置路径是: $appdata_path"
			break
		fi
	done
	echo "请稍等,正在打包数据..."
	tar -zcf ~/appdata.tar.gz $appdata_path/.. 
	echo "打包已经完成,请退出脚本并执行 cd 回车 ls 即可看到压缩文件."
}


function move_docker_root(){
	echo -e "\033[31m此为转移docker的默认路径,接下来会停止docker容器和服务!\033[0m"
 	read -p "确定需要这么做?请输入(y/n): " answer 
	if [ "$answer" == "y" ]; then
		docker stop $(docker ps -aq)
		systemctl stop docker.service docker.socket
		if [[ $? == 0 ]]; then
			read -p "请输入你要转移的目录路径（如 /disk1/docker_root ): " move_path
			if ! check_path_exist "$move_path"; then
				echo "你输入的路径不存在,请先创建文件夹!"
			else
				echo "你输入的路径是: '$move_path',正在转移..."
				cp -r /var/lib/docker/* $move_path/
				if [ "$check_daemon" == 0 ]; then
					sed -i '/{/a "data-root": "'$move_path'",' /etc/docker/daemon.json
				else
					echo -e '{\n\t"data-root": "'$move_path'"\n}' > /etc/docker/daemon.json
					
				fi
				systemctl restart docker
				if [ $? == 0 ]; then
					rm -rf /var/lib/docker
     					docker restart dockge
					echo "已完成转移!"
				else
					echo "转移失败!"
				fi
			fi
		else
		  echo "服务停止失败,请重启后再试"	
		fi
	else 
	  echo "操作已取消!"	
	fi

}

mainmenu
