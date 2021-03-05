#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kprobes.h>
#include <linux/ktime.h>
#include <linux/limits.h>
#include <linux/sched.h>

static char func_name[NAME_MAX] = "do_try_to_free_pages";
static char comm[NAME_MAX] = "need_to_assin";
static unsigned int pid = 0;
static unsigned long delay=1000000;
module_param(pid, uint, S_IRUGO);
module_param(delay, ulong, S_IRUGO);
module_param_string(comm, comm, NAME_MAX, S_IRUGO);
MODULE_PARM_DESC(service, "this module will report the do_try_to_free_pages's execution time");

/* per-instance private data */
struct my_data {
        ktime_t entry_stamp;
};

/* Here we use the entry_hanlder to timestamp function entry */
static int entry_handler(struct kretprobe_instance *ri, struct pt_regs *regs)
{
        struct my_data *data;

        data = (struct my_data *)ri->data;
        data->entry_stamp = ktime_get_real();
        return 0;
}

/*
 *  * Return-probe handler: Log the return value and duration. Duration may turn
 *   * out to be zero consistently, depending upon the granularity of time
 *    * accounting on the platform.
 *     */
static int ret_handler(struct kretprobe_instance *ri, struct pt_regs *regs)
{
        int retval = regs_return_value(regs);
        struct my_data *data = (struct my_data *)ri->data;
        s64 delta;
        ktime_t now;

        now = ktime_get_real();
        delta = ktime_to_ns(ktime_sub(now, data->entry_stamp));

	if (pid == 0) {
		if (delta > delay && strcmp(current->comm, comm) == 0) {
        		trace_printk("%s took %lld ns to execute when %d is running\n",
                        		func_name, (long long)delta, current->pid);
		}
	} else if(strcmp(comm, "need_to_assin") == 0) {
		if (delta > delay && current->pid == pid) {
			trace_printk("%s took %lld ns to execute when %d is running\n",
					func_name, (long long)delta, current->pid);
		}
	} else {
		if (delta > delay && current->pid == pid && strcmp(current->comm, comm) == 0) {
			trace_printk("%s took %lld ns to execute when %d is running\n",
					func_name, (long long)delta, current->pid);
		}
	}
        return 0;
}

static struct kretprobe my_kretprobe = {
        .handler                = ret_handler,
        .entry_handler          = entry_handler,
        .data_size              = sizeof(struct my_data),
        /* Probe up to 20 instances concurrently. */
        .maxactive              = 48,
};

static int __init kretprobe_init(void)
{
        int ret;

        my_kretprobe.kp.symbol_name = func_name;
        ret = register_kretprobe(&my_kretprobe);
        if (ret < 0) {
                printk(KERN_INFO "register_kretprobe failed, returned %d\n",
                                ret);
                return -1;
        }
        printk(KERN_INFO "Planted return probe at %s: %p\n",
                        my_kretprobe.kp.symbol_name, my_kretprobe.kp.addr);
        return 0;
}

static void __exit kretprobe_exit(void)
{
        unregister_kretprobe(&my_kretprobe);
        printk(KERN_INFO "kretprobe at %p unregistered\n",
                        my_kretprobe.kp.addr);

        /* nmissed > 0 suggests that maxactive was set too low. */
        printk(KERN_INFO "Missed probing %d instances of %s\n",
                my_kretprobe.nmissed, my_kretprobe.kp.symbol_name);
}

module_init(kretprobe_init)
module_exit(kretprobe_exit)
MODULE_LICENSE("GPL");
