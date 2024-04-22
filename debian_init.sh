#!/bin/bash
# Copyright © 2024 leeson All rights reserved.

ipaddr=$(ip a | grep /24 | awk '{print $2}' | awk -F "/" '{print $1}')
appdata_path=""
compose_path=""


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
	echo -e " 5 \033[34m一键安装上面所有内容\033[0m"
	dockge_installed=$(check_dockge_installed)
	echo -e " 6 \033[34m安装dockge容器管理 — $dockge_installed\033[0m"
	echo -e " 7 \033[33m设置静态IP地址\033[0m"
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
		
		onekey
		
	elif [ "$num" = 6 ]; then
		
		install_dockge
	elif [ "$num" = 7 ]; then
		
		set_static_addree
		
	else
		echo -e "\033[31m请输入正确的数字！\033[0m"
		
	fi
	mainmenu
	
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
	if grep -q "ustc" /etc/apt/sources.list; then
	    echo "[已更换]"   
	else
	    echo "[未更换]"
	fi	
}


function change_repo() {
	if [ "$(check_repo_changed)" == "[已更换]" ]; then
		echo "你已经换过了..."
	else
	echo "正在更换源地址..."
	mv /etc/apt/sources.list /etc/apt/sources.list.bak
	cat <<EOF >/etc/apt/sources.list
deb https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
	echo -e " \033[32m 中科大源替换完成,正在更新系统...\033[0m"
	apt update && apt upgrade -y && apt install nala
	fi
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
		wget https://mirror.ghproxy.com/https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
		sh setup-repos.sh <<<"y"
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
			read -p "请输入容器配置存放路径（以/开始的绝对路径）: " path_app
			if ! check_path_exist "$path_app"; then
				echo "你输入的路径不正确,请重新输入！"
			else
				echo "你输入的绝对路径是: $path_app"
				appdata_path=$path_app
				break
			fi
		done
		while true; do
			read -p "请输入compose持久化存放路径: " path_compose
			if ! check_path_exist "$path_compose"; then
				echo "你输入的路径不正确,请重新输入！"
			else
				echo "你输入的绝对路径是: $path_compose"
				compose_path=$path_compose
				break
			fi
		done
		docker run -d --name dockge --restart unless-stopped -p 5001:5001 -v /var/run/docker.sock:/var/run/docker.sock -v "$appdata_path":/app/data -v "$compose_path":/opt/stacks -e DOCKGE_STACKS_DIR=/opt/stacks louislam/dockge	
	    if [[ $? == 0 ]]; then
			echo -e " \033[32mdockge安装成功，请用\033[0m\033[33;1;5mhttp://$ipaddr:5001\033[0m\033[32m访问后台\033[0m"
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
	sudo systemctl restart NetworkManager
	echo "静态ip已经设置完成，请退出脚本并reboot"
}

mainmenu
