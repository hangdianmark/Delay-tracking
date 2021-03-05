#!/bin/bash

delay=0
pid=0
comm=""

while getopts 'd:p:c:a' OPT;do
        case $OPT in
		d)
			delay=$OPTARG
			;;
                p)
                        pid=$OPTARG
                        ;;
                c)
                        comm="$OPTARG"
                        ;;
                a)
                        echo "test all"
                        ;;
                ?)
                        echo "Usage: `basename $0` -p pid -d ns"
                        exit 1
                ;;
        esac
done

#需要指定毛刺时间
if [[ $delay -eq 0 ]];then
	echo "the delay time must be assined!"
	echo "Usage: `basename $0` -p pid -d ns"
	exit 1
fi

#需要指定pid或者comm
if [ -z $comm ] && [[ $pid -eq 0 ]];then
	echo "the pid or comm must be assined"
	echo "Usage: `basename $0` -p pid -d ns"
	exit 1
fi

#安装kernel-devel包
kernel_ver=`uname -r`
centos7_8=`cat /etc/redhat-release | tr '.' ' '|awk '{print $4}'`
yum install -y http://didiyum.sys.xiaojukeji.com/didiyum/didi/didi_kernel/$centos7_8/x86_64/kernel-$kernel_ver/kernel-devel-$kernel_ver.rpm
yum install -y elfutils-libelf-devel

#如果没有安装do_try_to_free_pages对应的ko，重新安装它
lmod=`lsmod | grep do_try_to_free_pages`
if [ -z "$lmod" ];then
	cd do_try_to_free_pages
	make
	cd ../
else
	rmmod do_try_to_free_pages
fi

if [ -z $comm ];then #如果只指定了pid
	temp="pid==$pid && delay>$delay"
	temp2="pid==$pid && runtime>$delay"
	insmod do_try_to_free_pages/do_try_to_free_pages.ko pid=$pid delay=$delay
elif [[ $pid -eq 0 ]];then #如果只指定了comm
	temp="comm==\"$comm\" && delay>$delay"
	temp2="comm==\"$comm\" && runtime>$delay"
	insmod do_try_to_free_pages/do_try_to_free_pages.ko comm="\"$comm\"" delay=$delay
else #如果既指定了pid又指定了comm
	temp="comm==\"$comm\" && pid==$pid && delay>$delay"
	temp2="comm==\"$comm\" && pid==$pid && runtime>$delay"
	insmod do_try_to_free_pages/do_try_to_free_pages.ko comm="\"$comm\"" delay=$delay pid=$pid
fi

#配置filter
echo $temp > /sys/kernel/debug/tracing/events/sched/sched_stat_wait/filter
echo $temp > /sys/kernel/debug/tracing/events/sched/sched_stat_blocked/filter
echo $temp2 > /sys/kernel/debug/tracing/events/sched/sched_stat_runtime/filter

#使能对应的trace事件
echo 1 > /sys/kernel/debug/tracing/events/sched/sched_stat_wait/enable
echo 1 > /sys/kernel/debug/tracing/events/sched/sched_stat_blocked/enable
echo 1 > /sys/kernel/debug/tracing/events/sched/sched_stat_runtime/enable

#sched stat必须将sched_schedstats置1
echo 1 > /proc/sys/kernel/sched_schedstats
#清除trace缓存
echo 0 > /sys/kernel/debug/tracing/trace

mkdir -p logs
python tracepipe.py &

#如果pid不为空，则将追踪pid被软中断打断的总时间
if [[ $pid -ne 0 ]] && [[ $centos7_8 -eq 8 ]];then
	t=`date "+%Y-%m-%d-%H:%M"`
	bpftrace soft_dis.bt $pid $delay > logs/$t-soft_dis.log &
	bpftrace soft_dis_enqueue.bt $pid $delay > logs/$t-soft_dis_enqueue.log &
	bpftrace block.bt $pid $delay > logs/$t-blocked.log &
fi
