CONFIG_MODULE_SIG=y
obj-m += do_try_to_free_pages.o
#Kretprobe-objs := kretprobe.o
CURRENT_PATH := $(shell pwd)
LINUX_KERNEL := /lib/modules/$(shell uname -r)/build
LINUX_KERNEL_PATH := $(LINUX_KERNEL)
all:
	make -C $(LINUX_KERNEL_PATH) M=$(CURRENT_PATH) modules
clean:
	make -C $(LINUX_KERNEL_PATH) M=$(CURRENT_PATH) clean
