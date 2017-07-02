# Linux系统VPS(服务器)性能一键测试脚本
#来自91yun的制作

一键包主要是为了让大家快速对服务器的基本状况有一个了解。考虑到天朝的网络出口问题，所以这个一键包更加偏向网络的测试。

影响测试耗时主要是下载，整个测试如果是能跑满100M带宽的话，应该在20分钟-30分钟。但如果只有几百k下载速度的话，就要耗很长时间了，所以如果大家看到测试卡在了下载测试，希望大家耐心等候。

测试结果存在当前目录的testwn789.log。大家可以用vim或者cat看，同时也会生成html的页面，方便大家查看和分享。具体html页面的样式参考以下内容。

# 使用方法：

## 普通模式：

    wget -N --no-check-certificate https://raw.githubusercontent.com/wn789/vpsxn/master/test_wn789.sh && bash test_wn789.sh
    
普通模式就是之前的测试常规内容。测试输出结果请参考：普通模式结果样式参考

## 简单模式：

    wget -N --no-check-certificate https://raw.githubusercontent.com/wn789/vpsxn/master/test_wn789.sh && bash test_wn789.sh s
    
简单模式的测试包含：常规系统参数检测，带宽测试，IO测试和全国ping测试。测试输出结果请参考：简单模式结果样式参考

主要因为普通模式的下载测试和路由测试有些耗时，有时大家可能只需要快速获得这台服务器的参数，带宽，io和延迟是多少。那么简单模式可以节省大量的时间。如果需要进一步的信息则可以使用普通模式。

相比普通模式，就是在命令最后加个s参数： bash test_wn789.sh s

## 完全模式：

    wget -N --no-check-certificate https://raw.githubusercontent.com/wn789/vpsxn/master/test_wn789.sh && bash test_wn789.sh a
    
完全模式相比普通模式多了unixbench的测试，测试输出结果请参考：完全模式结果样式参考

相比普通模式，就是在命令最后加个a参数： bash test_wn789.sh a

由于unixbench的测试极其耗资源（cpu和io会长时间处于占满状态），有些IDC禁用，会杀进程或者判断滥用。请谨慎测试。

# 问题反馈

[服务器测试一键包反馈页面](https://www.wn789.com/4705.html)
