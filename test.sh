#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo -n $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}


echo "欢迎使用一键VPS性能检测，继续请按回车！[default:Enter]"
read hostp
echo "开始测试，如果服务器带宽比较低可能会需要较长点时间，请耐心等待！"


_included_benchmarks=""



#取参数
while getopts "i:" opt; do
    case $opt in
        i) _included_benchmarks=$OPTARG;;
    esac
done

#默认参数
if [ "$_included_benchmarks" == "" ]; then
	_included_benchmarks="io,bandwidth,download,traceroute,backtraceroute,allping"
fi

_included_benchmarks="systeminfo,"${_included_benchmarks}

#预先安装库，如果有进行benchtest就会多安装些东西
bt="benchtest"
if [[ $_included_benchmarks == *$bt* ]]
then
    apt-get >/dev/null 2>&1
	[ $? -le '1' ] && ( apt-get update | apt-get -y install curl mtr virt-what python perl automake autoconf time make gcc gdb )
	yum >/dev/null 2>&1
	[ $? -le '1' ] && yum -y install which sed curl mtr virt-what python make gcc gcc-c++ gdbautomake autoconf time perl-Time-HiRes perl
else
    apt-get >/dev/null 2>&1
	[ $? -le '1' ] && ( apt-get update | apt-get -y install curl mtr virt-what python )
	yum >/dev/null 2>&1
	[ $? -le '1' ] && yum -y install which sed curl mtr virt-what python
fi

#要用到的变量
backtime=`date +%Y%m%d`
logfilename="testwn789.log"
dir=`pwd`
IP=$(curl -s myip.ipip.net | awk -F ' ' '{print $2}' | awk -F '：' '{print $2}')
echo "====开始记录测试信息====">${dir}/$logfilename

#创建测试目录
mkdir -p wn789test
cd wn789test

clear

#取得测试的参数值
arr=(${_included_benchmarks//,/ })    

#下载执行相应的代码
for i in ${arr[@]}    
do 
	wget -q --no-check-certificate https://raw.githubusercontent.com/wn789/vpsxn/test/test_code/${i}.sh
    . ${dir}/vpsxn/${i}.sh
	eval ${i}
done    

#删除目录
rm -rf ${dir}/wn789test
