---
layout: post
title: "Introduction to Oracle OSWatcher and reading logs"
date: 2019-06-05 00:01
comments: true
author: Suryakanta Sahu
published: true
authorIsRacker: true
categories:
    - Oracle
    - Database
metaTitle: "Introduction to Oracle OSWatcher and reading logs"
metaDescription: "Oracle&reg; OSWatcher is a utility that automatically looks for operating system issues and helps to determine their root causes."
ogTitle: "Introduction to Oracle OSWatcher and reading logs"
ogDescription: "Oracle&reg; OSWatcher is a utility that automatically looks for operating system issues and helps to determine their root causes."
---

Oracle&reg; OSWatcher is a utility that collects data from commands such as
`vmstat`, `iostat`, `top`, `ps`, `netstat`, HP-UX&reg; `sar`, and Linux&reg;
`meminfo`. OSWatcher archives the data files, automatically looks for issues, and helps
to determine the root cause of the issues, if possible.

<!-- more -->

### Introduction

On an hourly basis, OSWatcher collects operating system (OS) statistics in the background
by using the following OS commands:

- CPU
- Memory
- Disk I/O

OSWatcher writes the files to **$TFA_HOME/repository/suptools/walhall/oswbb/oracle/archive/**.

Because no automatic housekeeping exists, you should create a cron job to
automatically delete files older than some number of days to clean up the OS
statistics. For example, your cleanup cron job might run the following command
to remove files older than 10 days:

    find $TFA_HOME/repository/suptools/walhall/oswbb/oracle/archive -name "*.*" -mtime +10 -exec rm -f {} \;

### Read the oswiostat log output

If `iostat` is installed and the OSWatcher user has privileges to run the utility,
the OSWatcher logs collect and archive output on an hourly basis, by default,
from the `iostat` command.

`iostat`, which is used for monitoring system input and output device load, collects the
following information:

-	The time
-	The physical disks and their average data transfer rate

#### Output examples

The `oswiostat` log file includes the following data:

- `device`: Device name
- `r/s`: Reads per second
- `w/s`: Writes per second
- `rsec/s`: Kilobytes read per second
- `wsec/s`: Kilobytes written per second
- `avgrq-sz`: Average number of transactions waiting for service
- `avgqu-sz`: Average number of transactions actively being serviced
- `%util`: Percent of time that the disk is busy

Following are two examples of `oswiostat` logs, which were taken seven hours apart:

At a slow time:

    Time: 00:01:09

    avg-cpu:  %user   %nice %system %iowait  %steal   %idle

               5.22    0.01    1.77    0.10    0.00   92.90

    Device:         rrqm/s   wrqm/s   r/s   w/s   rsec/s   wsec/s avgrq-sz avgqu-sz   await  svctm  %util

    sda              10.24   101.92 10.28 29.60   569.53  1057.09    40.79     0.21    5.30   0.53   2.11
    sda1              0.00     0.00  0.00  0.00     0.17     0.00   138.66     0.00   12.37   3.45   0.00
    sda2             10.24   101.92 10.28 29.57   569.36  1057.09    40.81     0.21    5.30   0.53   2.11
    dm-0              0.00     0.00  1.72 77.98    75.95   623.85     8.78     1.20   14.99   0.08   0.67
    dm-1              0.00     0.00  0.46  2.37     3.80    18.94     8.04     0.01    2.71   0.29   0.08
    dm-2              0.00     0.00  7.44 50.74   278.30   410.79    11.84     0.72   12.30   0.23   1.33
    dm-3              0.00     0.00  0.00  0.00     0.15     0.00   509.61     0.00   46.78   7.53   0.00
    dm-4              0.00     0.00  0.49  0.00   117.41     0.02   238.95     0.00    1.94   1.05   0.05
    dm-5              0.00     0.00  0.05  0.00    10.84     0.00   230.78     0.00    2.58   1.34   0.01
    dm-6              0.00     0.00  0.00  0.00     0.10     0.00   479.96     0.00   54.94   8.70   0.00

At a busy time:

    Time: 07:32:57

    avg-cpu:  %user   %nice %system %iowait  %steal   %idle

               8.16    0.00   70.29   21.55    0.00    0.00

    Device:         rrqm/s   wrqm/s   r/s   w/s   rsec/s   wsec/s avgrq-sz avgqu-sz   await  svctm  %util

    sda             163.40     7.73 2074.74 53.95 73642.61   493.47    34.83   107.13   50.07   0.47 100.07
    sda1              0.00     0.00  0.00  0.00     0.00     0.00     0.00     0.00    0.00   0.00   0.00
    sda2            163.40     7.73 2074.74 53.95 73642.61   493.47    34.83   107.13   50.07   0.47 100.07
    dm-0              0.00     0.00 201.03  0.86  8412.37     6.87    41.70    58.68  281.80   4.96 100.07
    dm-1              0.00     0.00 180.76 26.46  1446.05   211.68     8.00    25.24  119.01   4.83 100.07
    dm-2              0.00     0.00 1868.90 34.54 63913.40   276.29    33.72   332.23  172.22   0.53 100.09
    dm-3              0.00     0.00  0.00  0.00     0.00     0.00     0.00     0.00    0.00   0.00   0.00
    dm-4              0.00     0.00  0.00  0.00     0.00     0.00     0.00     0.00    0.00   0.00   0.00
    dm-5              0.00     0.00  0.00  0.00     0.00     0.00     0.00     0.00    0.00   0.00   0.00
    dm-6              0.00     0.00  0.00  0.00     0.00     0.00     0.00     0.00    0.00   0.00   0.00

*Images Source*: [https://www.dbas-oracle.com/2013/05/How-to-Analyze-or-Read-OS-Watcher-Output-in-three-easy-steps-With-Example.html](https://www.dbas-oracle.com/2013/05/How-to-Analyze-or-Read-OS-Watcher-Output-in-three-easy-steps-With-Example.html)

The snapshot from midnight shows good performance, and the one from 7:32 AM shows
poor performance. Note the following indications of poor performance in the
second snapshot:

- Several disks are 100% busy, as seen in the `%util` column.
- The `r/s` column shows a very high number of reads per second.
- The `avg-cpu %idle` statistic shows the system is 0% idle versus 92% idle
  in the earlier snapshot.

### Read the mpstat log output

If `mpstat` is installed and the OSWatcher user has privileges to run the utility,
the OSWatcher logs collect and archive output on an hourly basis, by default,
from the `mpstat` command. Database administrators use this command to
monitor the central processing unit (CPU) utilization.

#### Output examples

The `mpstat` log file includes the following data:

- `CPU`: Which CPUs. `all` includes stats from all available CPUs in the system.
- `%user`: The percent of the CPUs used by USER programs
- `%sys`: The percent of the CPUs used by system programs
- `%iowait`: The percent of the CPUs consumed by IO waits
- `%idle`: The percent of idle system resources

Following are two examples of `mpstat` logs taken one hour apart:

At a slow time:

    zzz ***Tue Apr 23 06:13:44 EDT 2013 Sample interval: 5 seconds

    Linux 2.6.32-400.21.1.el5uek (remote.database.com)     04/23/13

    06:13:44     CPU   %user   %nice    %sys %iowait    %irq   %soft  %steal   %idle    intr/s

    06:13:49     all    6.26    0.00    1.32    0.00    0.01    0.02    0.00   92.39  36448.70
    06:13:54     all    8.17    0.00    1.92    0.01    0.00    0.05    0.00   89.86  38918.09
    06:13:59     all    8.11    0.00    1.18    0.01    0.00    0.05    0.00   90.65  40989.86
    06:14:04     all    8.04    0.00    1.25    0.06    0.00    0.05    0.00   90.61  40242.86
    06:14:09     all    6.62    0.00    1.27    0.02    0.00    0.05    0.00   92.04  37460.32
    06:14:14     all    7.56    0.00    1.47    0.02    0.00    0.02    0.00   90.94  37288.67
    06:14:19     all    7.19    0.00    1.21    0.14    0.00    0.02    0.00   91.44  36947.91
    06:14:24     all    6.50    0.00    1.02    0.01    0.00    0.02    0.00   92.45  35792.86
    06:14:29     all    7.28    0.00    1.82    0.01    0.00    0.02    0.00   90.87  36795.42
    06:14:34     all    7.37    0.02    1.20    0.02    0.00    0.01    0.00   91.37  36818.80
    06:14:39     all    7.41    0.00    1.05    0.02    0.00    0.02    0.00   91.49  36874.90
    06:14:44     all    7.15    0.01    1.62    0.04    0.00    0.02    0.00   91.16  35904.77
    06:14:49     all    7.21    0.00    1.22    0.14    0.00    0.02    0.00   91.41  38867.73
    06:14:54     all    7.31    0.00    1.00    0.00    0.00    0.03    0.00   91.65  39378.74

At a busy time:

    zzz ***Tue Apr 23 07:23:02 EDT 2013 Sample interval: 5 seconds

    Linux 2.6.32-400.21.1.el5uek (remote.database.com)     04/23/13

    07:24:20     CPU   %user   %nice    %sys %iowait    %irq   %soft  %steal   %idle    intr/s

    07:24:25     all    2.74    0.00   97.16    0.00    0.00    0.10    0.00    0.00  39066.67
    07:24:30     all    3.06    0.00   96.87    0.00    0.00    0.07    0.00    0.00  37637.52
    07:24:37     all    3.13    0.00   96.79    0.01    0.00    0.07    0.00    0.00  36788.64
    07:24:42     all    2.69    0.00   97.17    0.05    0.00    0.09    0.00    0.00  38270.04
    07:24:48     all    3.86    0.01   94.92    1.02    0.00    0.20    0.00    0.00  43247.39
    07:24:53     all    3.51    0.00   96.19    0.20    0.00    0.11    0.00    0.00  39887.45
    07:24:59     all    4.22    0.00   93.51    2.12    0.00    0.15    0.00    0.00  40638.08
    07:25:04     all    6.26    0.00   85.04    8.56    0.00    0.13    0.00    0.00  41915.79
    07:25:09     all    8.69    0.00   67.31   23.85    0.00    0.11    0.00    0.03  44586.56
    07:25:15     all    8.09    0.00   80.62   11.17    0.00    0.12    0.00    0.00  44321.66
    07:25:21     all    7.18    0.00   71.95   20.80    0.00    0.07    0.00    0.00  35399.65
    07:25:26     all    6.69    0.00   68.20   24.97    0.01    0.12    0.00    0.00  38734.99
    07:25:31     all    7.11    0.01   74.71   18.09    0.00    0.08    0.00    0.00  36695.68
    07:25:36     all    7.46    0.00   14.17   78.20    0.00    0.05    0.00    0.13  32934.53
    07:25:50     all    9.71    0.00   23.99   66.24    0.00    0.05    0.00    0.00  33617.64
    07:25:56     all    7.80    0.00   85.97    6.13    0.00    0.10    0.00    0.00  41234.83

The snapshot from 06:13 shows good performance, and the one from 7:32 AM shows
poor performance. Note the following indications of poor performance in the
second snapshot:

- The `%sys` column shows peak utilization of 97.17.
- The `%iowait` column shows a peak utilization of 78.20.

### Read top output

The `top` command provides an hourly snapshot of processor activity.
The log shows processes listed in the descending order of CPU utilization so
that the process using the most CPU is listed first.

In cases when CPU utilization on the system suddenly increases and number of
processes hasn't changed, `top` can help identify the issue.

#### Output examples

Consider the following scenario, where the CPU spikes even though load did not
increase:

    zzz ***Tue Apr 23 03:13:44 EDT 2013 Sample interval: 5 seconds. All measurements in KB (1024 bytes)

    top - 04:13:44 up 22 days, 21:12, 10 users,  load average: 65.80, 169.78, 117.65

    Tasks: 2297 total,   4 running, 2229 sleeping,   0 stopped,  64 zombie

    Cpu0  : 12.7%us,  2.6%sy,  0.0%ni, 84.2%id,  0.5%wa,  0.0%hi,  0.0%si,  0.0%st
    Cpu1  :  6.7%us,  2.0%sy,  0.0%ni, 91.1%id,  0.1%wa,  0.0%hi,  0.1%si,  0.0%st
    Cpu2  :  6.4%us,  1.7%sy,  0.0%ni, 91.8%id,  0.1%wa,  0.0%hi,  0.0%si,  0.0%st
    Cpu3  :  5.5%us,  1.3%sy,  0.0%ni, 93.1%id,  0.1%wa,  0.0%hi,  0.0%si,  0.0%st
    Cpu4  :  7.6%us,  1.6%sy,  0.0%ni, 90.7%id,  0.0%wa,  0.0%hi,  0.0%si,  0.0%st
    Cpu5  :  5.3%us,  1.1%sy,  0.0%ni, 93.5%id,  0.0%wa,  0.0%hi,  0.0%si,  0.0%st
    Cpu6  : 11.8%us,  2.7%sy,  0.0%ni, 85.3%id,  0.1%wa,  0.0%hi,  0.1%si,  0.0%st
    Cpu7  :  7.0%us,  2.2%sy,  0.0%ni, 90.6%id,  0.1%wa,  0.0%hi,  0.1%si,  0.0%st
    Cpu8  :  5.8%us,  1.5%sy,  0.0%ni, 91.8%id,  0.8%wa,  0.0%hi,  0.1%si,  0.0%st
    Cpu9  :  8.0%us,  1.7%sy,  0.0%ni, 90.0%id,  0.1%wa,  0.0%hi,  0.2%si,  0.0%st
    Cpu10 :  3.8%us,  1.2%sy,  0.0%ni, 94.9%id,  0.1%wa,  0.0%hi,  0.0%si,  0.0%st
    Cpu11 :  3.6%us,  1.0%sy,  0.0%ni, 95.3%id,  0.0%wa,  0.0%hi,  0.0%si,  0.0%st

    Mem:  99060540k total, 91969324k used,  7091216k free,    84044k buffers
    Swap: 25165816k total, 17797404k used,  7368412k free,   609612k cached

     PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND

    20343 oracle    20   0 13.4g  10g 5864 R 98.4 10.7  18:56.54 oraclevntrd2 (LOCAL=NO)
    30180 root      20   0 11872 2312  656 R 98.4  0.0   0:00.68 /bin/netstat -n -p -l
     6568 root      39  19     0    0    0 R 89.9  0.0 263:39.04 [kipmi0]
    30262 root      20   0 23704 3116 1048 R 11.9  0.0   0:00.15 /usr/bin/top -b -d 5 -n 720
     4921 root      RT   0  247m  86m  55m S  6.8  0.1 328:08.44 /u01/app/11.2.0.3/grid/bin/osysmond.bin
    28116 oracle    20   0 2623m  71m  14m S  6.8  0.1  51:51.62 /u01/app/11.2.0.3/grid/bin/oraagent.bin
     4970 grid      RT   0  359m 176m  54m S  5.1  0.2 157:05.89 /u01/app/11.2.0.3/grid/bin/ocssd.bin
       64 root      20   0     0    0    0 S  1.7  0.0   4:39.22 [ksoftirqd/20]
     4903 root      20   0  367m  20m  13m S  1.7  0.0  26:09.97 /u01/app/11.2.0.3/grid/bin/orarootagent.bin
     6496 root      20   0 1274m  15m  11m S  1.7  0.0  28:27.53 /u01/app/11.2.0.3/grid/bin/orarootagent.bin
     6535 oracle    20   0 1830m 263m 4620 S  1.7  0.3  88:05.31 /u01/app/oracle/product/agent12c/core/12.1.0.2.0/jdk/bin/java -Xmx128M -server -Djava.secu
     7803 oracle    -2   0 1266m  11m 4068 S  1.7  0.0   9:15.42 ora_lms0_oradb2
     7874 oracle    -2   0 1266m  15m 4188 S  1.7  0.0   9:16.20 ora_lms0_oradb2
     7999 oracle    20   0 1284m  10m 3292 S  1.7  0.0   2:49.08 ora_lmd0_oradb2
     8297 oracle    20   0 1230m 3368 2864 S  1.7  0.0   0:39.95 ora_pmon_oradb2
     8333 oracle    -2   0 1252m 2380 2108 S  1.7  0.0  13:19.99 ora_vktm_bid2
     8443 oracle    -2   0 1252m 2340 2096 S  1.7  0.0  13:21.86 ora_vktm_oradb2
     8535 oracle    20   0 1253m 2712 2412 S  1.7  0.0   0:14.28 ora_dskm_oradb2
     8727 oracle    -2   0 1266m  11m 3656 S  1.7  0.0   9:01.37 ora_lms0_im1d2
     8905 oracle    20   0 1267m  13m 3468 S  1.7  0.0   9:52.75 ora_dia0_pstd2

**Analysis of the log:**

Line `zzz ***Tue Apr 23 03:13:44 EDT 2013 Sample interval: 5 seconds. All measurements in KB (1024 bytes)`
identifies the time that the log captured the statistics.

Line `top - 04:13:44 up 22 days, 21:12, 10 users` indicates that system has been
running for 22 days since the last reboot.

Line `load average: 65.80, 169.78, 117.65` shows the average number of processes
in the run queue for the last one, five, and fifteen minutes. The higher the
average load, the busier the system is. Significant increases in load average
might indicate a problem. For example, the preceding log indicates a busy time
compared to a log from seven minutes later, based on the load average numbers:
`top - 04:20:53 up 22 days, 21:19, 10 users,  load average: 2.93, 43.22, 75.56`

Line `Tasks: 2297 total,   4 running, 2229 sleeping,   0 stopped,  64 zombie`:
At the time of this snapshot, there were 2297 processes, 2229 were sleeping,
that is blocked by I/O or a system call, and 4 were
running or assigned to a CPU.  The number of running processes can never exceed
the number of CPUs. An additional 64 processes are zombies, that is they are dead,
but the system hasn't completely cleaned them up. The number of processes varies,
but if the number suddenly increases or decreases, that might indicate a problem.

Line `Mem:  99060540k total, 91969324k used,  7091216k free,    84044k buffers`
shows how much random access memory (RAM) in kilobytes is in use and is free.
Pay attention to how this changes over time so you can identify problems.

Line `Swap: 25165816k total, 17797404k used,  7368412k free,   609612k cached`:
If RAM is exhausted, the system switches to swap memory. When swap memory use is
consistently more than about 40% of RAM, you should consider increasing RAM.
High swap usage negatively affects performance. If it reaches 100%, the system
might reboot.

The following CPU lines show the number and utilization of the 12 CPUs in this
system:

    Cpu0  : 12.7%us,  2.6%sy,  0.0%ni, 84.2%id,  0.5%wa,  0.0%hi,  0.0%si,  0.0%st
    ...
    Cpu11 :  3.6%us,  1.0%sy,  0.0%ni, 95.3%id,  0.0%wa,  0.0%hi,  0.0%si,  0.0%st


The following process lines show details of the processes running at the time of
the snapshot:

     PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND

    20343 oracle    20   0 13.4g  10g 5864 R 98.4 10.7  18:56.54 oraclevntrd2 (LOCAL=NO)
    30180 root      20   0 11872 2312  656 R 98.4  0.0   0:00.68 /bin/netstat -n -p -l
     6568 root      39  19     0    0    0 R 89.9  0.0 263:39.04 [kipmi0]
    30262 root      20   0 23704 3116 1048 R 11.9  0.0   0:00.15 /usr/bin/top -b -d 5 -n 720
    ...
     8727 oracle    -2   0 1266m  11m 3656 S  1.7  0.0   9:01.37 ora_lms0_im1d2
     8905 oracle    20   0 1267m  13m 3468 S  1.7  0.0   9:52.75 ora_dia0_pstd2

The processes section contains the following information:

- `PID`: The OS process ID of the process
- `USER`: The owner of the process
- `%CPU`: What percent of the CPU is used by the process
- `%MEM`: The percentage of memory consumption
- `COMMAND`: The executing command

### Conclusion

By using OSWatcher, you can keep an eye on system performance and identify
possible problems. For example, check to see if a process is heavily using a
CPU for a consistent amount of time. If an SQL command has a high load, then
this might be a candidate for tuning. If a process is using a lot of memory,
then you might investigate whether this is normal.

There are other stats available in OSWatcher to consider, after looking at CPU,
memory, and disk I/O (such as system load). If you identify a load increase on the
system by using OSWatcher analysis, half the battle is won.

Use the Feedback tab to make any comments or ask questions.

### Reference source:

[How to Analyze or Read OSWatcher Output in Three Easy Steps with Example](https://www.dbas-oracle.com/2013/05/How-to-Analyze-or-Read-OS-Watcher-Output-in-three-easy-steps-With-Example.html)

### Optimize your environment with expert administration, management, and configuration

[Rackspace's Application services](https://www.rackspace.com/application-management/managed-services)
**(RAS)** experts provide the following [professional](https://www.rackspace.com/application-management/professional-services)
and
[managed services](https://www.rackspace.com/application-management/managed-services) across
a broad portfolio of applications:

- [eCommerce and Digital Experience platforms](https://www.rackspace.com/ecommerce-digital-experience)
- [Enterprise Resource Planning (ERP)](https://www.rackspace.com/erp)
- [Business Intelligence](https://www.rackspace.com/business-intelligence)
- [Salesforce Customer Relationship Management (CRM)](https://www.rackspace.com/salesforce-managed-services)
- [Databases](https://www.rackspace.com/dba-services)
- [Email Hosting and Productivity](https://www.rackspace.com/email-hosting)

We deliver:

- **Unbiased expertise**: We simplify and guide your modernization journey,
focusing on the capabilities that deliver immediate value.
- **Fanatical Experience**&trade;: We combine a *process first, technology second*
approach with dedicated technical support to provide comprehensive solutions.
- **Unrivaled portfolio**: We apply extensive cloud experience to help you
choose and deploy the right technology on the right cloud.
- **Agile delivery**: We meet you where you are in your journey and align
our success with yours.

[Chat now](https://www.rackspace.com/#chat) to get started.
