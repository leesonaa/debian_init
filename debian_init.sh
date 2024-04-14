#!/bin/bash

ipaddr=$(ip a | grep /24 | awk '{print $2}' | awk -F "/" '{print $1}')
appdata_path=""
compose_path=""
cd /tmp
mainmenu() {

	echo -e " \033[33;1;5m<欢迎使用 debian12一键初始化建议脚本>\033[0m"
	echo " ----------------------------"
	echo "        \   ^__^                       "
	echo "         \  (oo)\_______               "
	echo "            (__)\ leeson)\/            "
	echo "                ||----w |              "
	echo "                ||     ||              "
	echo -e " 1 \033[36m更换国内中科大源\033[0m"
	echo -e " 2 \033[36m安装实用工具\033[0m"
	webmin_installed=$(check_webmin_installed)
	echo -e " 3 \033[32m安装webmin — $webmin_installed\033[0m"
	docker_installed=$(check_docker_installed)
	echo -e " 4 \033[32m安装docker环境 — $docker_installed\033[0m"
	echo -e " 5 \033[34m一键安装上面所有内容\033[0m"
	dockge_installed=$(check_dockge_installed)
	echo -e " 6 \033[34m安装dockge容器管理 — $dockge_installed\033[0m"
	echo -----------------------------------------------
	echo -e " 0 \033[31m退出脚本\033[0m"
	read -p "请输入对应数字 > " num
	if [ -z "$num" ]; then
		echo -e "\033[31m请输入正确的数字！\033[0m"
	elif [ "$num" = 0 ]; then
		echo "退出脚本"
		exit 0
	elif [ "$num" = 1 ]; then
		echo "正在更换国内中科大源..."
		change_repo
		mainmenu
	elif [ "$num" = 2 ]; then
		echo "正在安装实用工具..."
		install_tool
		mainmenu
	elif [ "$num" = 3 ]; then
		install_webmin
		mainmenu
	elif [ "$num" = 4 ]; then
		install_docker
		mainmenu
	elif [ "$num" = 5 ]; then
		echo "正在安装上面所有内容..."
		onekey
		mainmenu
	elif [ "$num" = 6 ]; then
		echo "正在安装dockge管理面板..."
		install_dockge
		mainmenu
	else
		echo -e "\033[31m请输入正确的数字！\033[0m"
		mainmenu
	fi
	
}

check_dockge_installed() {
    if docker ps -a --format '{{.Names}}' | grep -q '^dockge$'; then
        echo -e "\033[32m[已安装]\033[0m"
    else
        echo -e "\033[31m[未安装]\033[0m"
    fi
}

check_docker_installed() {
    if command -v docker >/dev/null 2>&1; then
        echo -e "\033[32m[已安装]\033[0m"
    else
        echo -e "\033[31m[未安装]\033[0m"
    fi
}

check_webmin_installed() {
    if command -v webmin >/dev/null 2>&1; then
        echo -e "\033[32m[已安装]\033[0m"
    else
        echo -e "\033[31m[未安装]\033[0m"
    fi
}

change_repo() {
	mv /etc/apt/sources.list /etc/apt/sources.list.bak
	cat <<EOF >/etc/apt/sources.list
deb https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
	echo -e " \033[32m 中科大源替换完成\033[0m"
}

install_tool() {
	apt update && apt install nala -y
	nala update && nala install -y curl duf btop
	echo -e " \033[32m您的系统挂载点信息如下\033[0m"
	duf
}

install_webmin() {
	apt update && apt install nala -y
	wget https://mirror.ghproxy.com/https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
	sh setup-repos.sh <<<"y"
	nala install -y --install-recommends webmin
	echo -e " \033[32mwebmin安装成功，请用\033[0m\033[33;1;5mhttps://$ipaddr:10000\033[0m\033[32m访问后台\033[0m"
	echo -e " \033[32m账户密码为服务器ssh的账户密码\033[0m"
}

install_docker() {
	apt update && apt install nala -y
	if command -v curl >/dev/null 2>&1; then
		echo "正在准备安装docker环境..."
	else
		echo "正在安装curl && docker && docker-compose"
		nala update && nala install -y curl
	fi
	curl -fsSL https://get.docker.com | sh
	nala install -y docker-compose
}

onekey() {
	change_repo
	install_tool
	install_docker
	install_webmin
}

check_path_exist() {
	local path="$1"

	if [ -e "$path" ]; then
		return 0 # 路径存在返回 0 true
	else
		return 1 # 路径不存在返回 1 false
	fi
}

install_dockge() {
	if command -v docker >/dev/null 2>&1; then
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

mainmenu
