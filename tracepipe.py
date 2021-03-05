#!/usr/bin/python
  
from datetime import datetime

logfile = "tracepipe.out"
hour = datetime.now().strftime('%m_%d_%H')
logfile = logfile + hour
logdir = "logs/"
log = open(logdir + logfile, 'w')

f = open("/sys/kernel/debug/tracing/trace_pipe", "r")
while (1):
    try:
        line = f.readline()
        #hour2 = datetime.now().strftime('%m_%d_%H')
	time = datetime.now().strftime('%m_%d_%H:%M:%S.%f')
	hour2 = time.split(':')[0]
        if hour2 != hour:
            hour = hour2
            log.close()
            logfile = "tracepipe.out" + hour
            log = open(logdir + logfile, 'w')
	log.write(time + line)
#        log.write(datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f') + line)
    except:
        log.close()
        f.close()
        exit()

log.close()
f.close()

