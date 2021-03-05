#!/bin/bash

#这里会对系统做恢复，关闭用于数据抓取的trace功能

rmmod do_try_to_free_pages

echo 0 > /sys/kernel/debug/tracing/events/sched/sched_stat_wait/enable
echo 0 > /sys/kernel/debug/tracing/events/sched/sched_stat_blocked/enable
echo 0 > /sys/kernel/debug/tracing/events/sched/sched_stat_runtime/enable

echo 0 > /sys/kernel/debug/tracing/events/sched/sched_stat_wait/filter
echo 0 > /sys/kernel/debug/tracing/events/sched/sched_stat_blocked/filter
echo 0 > /sys/kernel/debug/tracing/events/sched/sched_stat_runtime/filter

echo 0 > /proc/sys/kernel/sched_schedstats

pids=`ps aux | grep  'python tracepipe.py' | grep -v color=auto | grep -v grep | awk '{print $2}'`
for pid in $pids
do
	kill -9 $pid
done

pids=`ps aux | grep  'bpftrace soft_dis.bt' | grep -v color=auto | grep -v grep |awk '{print $2}'`
for pid in $pids
do
        kill -9 $pid
done

pids=`ps aux | grep  'bpftrace soft_dis_enqueue.bt' | grep -v color=auto | grep -v grep |awk '{print $2}'`
for pid in $pids
do
        kill -9 $pid
done

pids=`ps aux | grep  'bpftrace block.bt' | grep -v color=auto | grep -v grep |awk '{print $2}'`
for pid in $pids
do
        kill -9 $pid
done
