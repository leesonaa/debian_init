#!/bin/bash

ipaddr=$(ip a | grep /24 | awk '{print $2}' | awk -F "/" '{print $1}')

mainmenu(){

echo -e " \033[32m<欢迎使用 debian12一键初始化建议脚本>\033[0m"
echo " ----------------------------"
echo "        \   ^__^                       "
echo "         \  (oo)\_______               "
echo "            (__)\ leeson)\/         "
echo "                ||----w |              "
echo "                ||     ||              "
echo -e " 1 \033[36m更换国内中科大源\033[0m"
echo -e " 2 \033[36m安装实用工具\033[0m"
echo -e " 3 \033[32m安装webmin\033[0m"
echo -e " 4 \033[32m安装docker环境\033[0m"
echo -e " 5 \033[34m一键安装上面所有内容\033[0m"
echo -----------------------------------------------
echo -e " 0 \033[31m退出脚本\033[0m"
read -p "请输入对应数字 > " num
if [ -z "$num" ];then
  echo -e "\033[31m请输入正确的数字！\033[0m"
elif [ "$num" = 0 ]; then
  echo "退出脚本"
  exit 0;		
elif [ "$num" = 1 ]; then
	echo "正在更换国内中科大源..."
	change_repo
elif [ "$num" = 2 ]; then
	echo "正在安装实用工具..."
	install_tool
elif [ "$num" = 3 ]; then
	install_webmin
elif [ "$num" = 4 ]; then
	install_docker
elif [ "$num" = 5 ]; then
	echo "正在安装上面所有内容..."
	onekey
else
	echo -e "\033[31m请输入正确的数字！\033[0m"
fi
mainmenu
}

change_repo(){
	rm /etc/apt/sources.list
cat << EOF > /etc/apt/sources.list
deb https://mirrors.ustc.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
	echo -e " \033[32m 中科大源替换完成\033[0m"
}

install_tool(){
	apt update && apt install nala -y
	nala update && nala install -y curl duf btop
	echo -e " \033[32m您的系统挂载点信息如下\033[0m"
	duf
}

install_webmin(){
	apt update && apt install nala -y
	wget https://mirror.ghproxy.com/https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
	sh setup-repos.sh <<< "y"
	nala install -y --install-recommends webmin
	echo -e " \033[32mwebmin安装成功，请用https://$ipaddr:10000 访问后台\033[0m"
	echo -e " \033[32m账户密码为服务器ssh的账户密码\033[0m"
}

install_docker(){
	apt update && apt install nala -y
	if command -v curl >/dev/null 2>&1 ; then
		echo "正在准备安装docker环境..."
	else
		echo "正在安装curl && docker && docker-compose"
		nala update && nala install -y curl	
	fi
	curl -fsSL https://get.docker.com | sh
	nala install -y docker-compose
}

onekey(){
	change_repo
	install_tool
	install_webmin
	install_docker
}

mainmenu
