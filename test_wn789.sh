#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

echo "欢迎使用一键VPS性能检测，继续请按回车！[default:Enter]"
read hostp
echo "开始测试，如果服务器带宽比较低可能会需要较长点时间，请耐心等待！"
#===============================以下是各类要用到的函数========================================
#teddey的besh测试网络下载和IO用到的
get_opsy() {
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

speed_test() {
    speedtest=$(wget -4O /dev/null -T300 $1 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
    ipaddress=$(ping -c1 -n `awk -F'/' '{print $3}' <<< $1` | awk -F'[()]' '{print $2;exit}')
    nodeName=$2
    if   [ "${#nodeName}" -lt "8" ]; then
        echo -e "$2\t\t\t\t$ipaddress\t\t$speedtest" | tee -a $logfilename
    elif [ "${#nodeName}" -lt "13" ]; then
        echo -e "$2\t\t\t$ipaddress\t\t$speedtest" | tee -a $logfilename
    elif [ "${#nodeName}" -lt "24" ]; then
        echo -e "$2\t\t$ipaddress\t\t$speedtest" | tee -a $logfilename
    elif [ "${#nodeName}" -ge "24" ]; then
        echo -e "$2\t$ipaddress\t\t$speedtest" | tee -a $logfilename
    fi
}



speed() {
    speed_test 'http://cachefly.cachefly.net/100mb.test' 'CacheFly CND'
    speed_test 'http://speedtest.tokyo.linode.com/100MB-tokyo.bin' 'Linode, 东京, 日本'
    speed_test 'http://speedtest.singapore.linode.com/100MB-singapore.bin' 'Linode, 新加坡, 新加坡'
    speed_test 'http://speedtest.london.linode.com/100MB-london.bin' 'Linode, 伦敦, 英国'
    speed_test 'http://speedtest.frankfurt.linode.com/100MB-frankfurt.bin' 'Linode, 法兰克福, 德国'
    speed_test 'http://speedtest.fremont.linode.com/100MB-fremont.bin' 'Linode, 弗里蒙特, 美国'
    speed_test 'http://speedtest.dal05.softlayer.com/downloads/test100.zip' 'Softlayer, 达拉斯, 美国'
    speed_test 'http://speedtest.sea01.softlayer.com/downloads/test100.zip' 'Softlayer, 西雅图, 美国'
    speed_test 'http://speedtest.fra02.softlayer.com/downloads/test100.zip' 'Softlayer, 法兰克福, 德国'
    speed_test 'http://speedtest.sng01.softlayer.com/downloads/test100.zip' 'Softlayer, 新加坡, 新加坡'
    speed_test 'http://speedtest.hkg02.softlayer.com/downloads/test100.zip' 'Softlayer, 香港, 中国'
}


io_test() {
    (LANG=en_US dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
#=================teddey用到的函数结束=================================================

#=================以下是我自己写的网络mtr和ping用到的函数==============================

#测试全国ping值
ping_test(){
	echo "===国内PING测试开始===" | tee -a $logfilename
	pingurl="http://www.ipip.net/ping.php?a=send&host=$1&area%5B%5D=china"
	pingstr=$(curl -s "$pingurl")
	#echo $pingstr >> $logfilename
	echo $pingstr > pingstr.log
	pingstrback_all=$(curl -s -d @pingstr.log "http://test.91yun.org/ping.php?ping")
	pingstrback=$(curl -s -d @pingstr.log "http://test.91yun.org/ping.php")
	rm -rf pingstr.log
	echo "===all ping start===" >> $logfilename
	echo -e $pingstrback_all | awk -F '^' '{printf("%-3s\t%-30s\t%-15s\t%-20s\t%-3s\t%-7s\t%-7s\t%-7s\t%-3s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9)}' >> $logfilename	
	echo -e "===all ping end===\n\n" >> $logfilename
	echo "===ping show===" >> $logfilename
	echo -e $pingstrback | awk -F '^' '{printf("%-10s\t%-10s\t%-30s\t%-10s\t%-30s\t%-30s\t%-30s\n",$1,$2,$3,$4,$5,$6,$7)}' | tee -a $logfilename
	echo -e "===ping show end===\n\n" >> $logfilename
	echo "===国内PING测试结束===" | tee -a $logfilename
	
}
#==========================自用函数结束========================================



#安装需要的依赖库
prewget()
{
	[[ -f /etc/redhat-release ]] && os='centos'
	[[ ! -z "`egrep -i debian /etc/issue`" ]] && os='debian'
	[[ ! -z "`egrep -i ubuntu /etc/issue`" ]] && os='ubuntu'
	[[ "$os" == '' ]] && echo 'Error: Your system is not supported to run it!' && exit 1

	if [ "$os" == 'centos' ]; then
		#yum -y install make gcc gcc-c++ gdb mtr wget curl automake autoconf time perl-Time-HiRes python perl virt-what
		yum -y install mtr curl
	else
		apt-get update
		#apt-get -y install curl  mtr perl python virt-what automake autoconf time make gcc gdb
		apt-get -y install curl mtr
	fi
	cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	tram=$( free -m | awk '/Mem/ {print $2}' )
	swap=$( free -m | awk '/Swap/ {print $2}' )
	up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=$1%60} {printf("%ddays, %d:%d:%d\n",a,b,c,d)}' /proc/uptime )
	opsy=$( get_opsy )
	arch=$( uname -m )
	lbit=$( getconf LONG_BIT )
	host=$hostp
	up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=$1%60} {printf("%ddays, %d:%d:%d\n",a,b,c,d)}' /proc/uptime )
	kern=$( uname -r )
	ipv6=$( wget -qO- -t1 -T2 ipv6.icanhazip.com )
	IP=$(curl -s myip.ipip.net | awk -F ' ' '{print $2}' | awk -F '：' '{print $2}')
	IPaddr=$(curl -s myip.ipip.net | awk -F '：' '{print $3}')
	if [ "$IP" == "" ]; then
		IP=$(curl -s ip.cn | awk -F ' ' '{print $2}' | awk -F '：' '{print $2}')
		IPaddr=$(curl -s ip.cn | awk -F '：' '{print $3}')	
	fi
	backtime=`date +%Y%m%d`
	logfilename="testwn789.log"

}

#查看虚拟化技术
virt()
{
	if [ "$os" == 'centos' ]; then
		yum -y install virt-what
	else
		apt-get update
		apt-get -y install virt-what
	fi
	
	#查看虚拟化技术：
	# wget http://gongju.wn789.com/virt-what-1.12.tar.gz
	# tar zxvf virt-what-1.12.tar.gz
	# cd virt-what-1.12/
	# ./configure
	# make && make install
	vm=`virt-what`
	# cd ..
	# rm -rf virt-what*	
}

#系统基本信息
systeminfo()
{

	#覆盖已有文件
	echo "====开始记录测试信息====" > $logfilename

	#把系统信息写入日志文件
	echo "===系统基本信息===" | tee -a $logfilename
	echo "CPU 型号:$cname" | tee -a $logfilename
	echo "CPU 核数:$cores" | tee -a $logfilename
	echo "CPU 频率:$freq" | tee -a $logfilename
	echo "内存大小:$tram" | tee -a $logfilename
	echo "swap分区:$swap" | tee -a $logfilename
	echo "运行时间:$up" | tee -a $logfilename
	echo "运行系统:$opsy" | tee -a $logfilename
	echo "系统位数:$arch ($lbit Bit)" | tee -a $logfilename
	echo "内核版本:$kern" | tee -a $logfilename
	echo "服务器ip:$IP" | tee -a $logfilename
	echo "机房位置:$IPaddr" | tee -a $logfilename
	echo "host:$hostp" | tee -a $logfilename
	echo "开机时间:$up" | tee -a $logfilename
	echo "虚拟技术:$vm" | tee -a $logfilename
	echo "he:$he" | tee -a $logfilename
	echo -e "\n\n" | tee -a $logfilename

}


#带宽测试
bdtest()
{
	if [ "$os" == 'centos' ]; then
		yum -y install python
	else
		apt-get update
		apt-get -y install python
	fi
	echo "===开始测试带宽===" | tee -a $logfilename
	wget --no-check-certificate http://gongju.wn789.com/speedtest_cli.py 1>/dev/null 2>&1
	python speedtest_cli.py --share | tee -a $logfilename
	echo -e "===带宽测试结束==\n\n" | tee -a $logfilename
	rm -rf speedtest_cli.py
}


#下载测试
dltest()
{
	echo "===开始测试下载速度===" | tee -a $logfilename
	next
	if  [ -e '/usr/bin/wget' ]; then
		echo -e "Node Name\t\t\tIPv4 address\t\tDownload Speed" | tee -a $logfilename
		echo "===star ipv4 download===" >> $logfilename
		speed && next
		echo -e "===end ipv4 download===\n\n" >> $logfilename
	else
		echo "Error: wget command not found. You must be install wget command at first."
		exit 1
	fi
}


#IO测试
iotest()
{
	echo "===开始测试IO性能===" | tee -a $logfilename
	io1=$( io_test )
	io2=$( io_test )
	io3=$( io_test )
	ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
	[ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
	ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
	[ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
	ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
	[ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
	ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
	ioavg=$( awk 'BEGIN{print '$ioall'/3}' )
	echo "I/O speed(1st run) : $io1" | tee -a $logfilename
	echo "I/O speed(2nd run) : $io2" | tee -a $logfilename
	echo "I/O speed(3rd run) : $io3" | tee -a $logfilename
	echo "I/O 平均值: $ioavg MB/s" | tee -a $logfilename
	echo ""
}


#开始进行PING测试
pingtest()
{
	ping_test $IP
}


benchtest()
{

	if [ "$os" == 'centos' ]; then
		yum -y install make gcc gcc-c++ gdbautomake autoconf time perl-Time-HiRes python perl
	else
		apt-get update
		apt-get -y install perl python automake autoconf time make gcc gdb
	fi
	
	# Download UnixBench5.1.3
	if [ -s UnixBench5.1.3.tgz ]; then
		echo "UnixBench5.1.3.tgz [found]"
	else
		echo "UnixBench5.1.3.tgz not found!!!download now..."
		if ! wget -c http://gongju.wn789.com/UnixBench5.1.3.tgz; then
			echo "Failed to download UnixBench5.1.3.tgz, please download it to ${cur_dir} directory manually and try again."
			exit 1
		fi
	fi
	tar -xzf UnixBench5.1.3.tgz
	cd UnixBench/

	#Run unixbench
	make
	echo "===开始测试bench===" | tee -a ../${logfilename}
	./Run
	benchfile=`ls results/ | grep -v '\.'`
	cat results/${benchfile} >> ../${logfilename}
	echo "===bench测试结束===" | tee -a ../${logfilename}	
	cd ..
	rm -rf UnixBench5.1.3.tgz UnixBench
}

simple_test()
{
	prewget
	systeminfo
	bdtest
	iotest
	pingtest
	#updatefile
}

normal_test()
{
	prewget
	virt
	systeminfo
	bdtest
	dltest
	iotest
	#tracetest
	#backtracetest
	pingtest
	#gotoping
	#updatefile
	
}

all_test()
{
	prewget
	virt
	systeminfo
	bdtest
	dltest
	iotest
	#tracetest
	#backtracetest
	pingtest
	#gotoping
	benchtest
	#updatefile
	
}




action=$1
[ -z $1 ] && action=n
case "$action" in
s)
    simple_test
    ;;
a)
    all_test
    ;;
n)
    normal_test
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {s | n| a}"
    ;;
esac
