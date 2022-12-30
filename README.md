# check_cpu_stats
check_cpu_stats is an open source monitoring plugin which uses `iostat` (from the sysstat package) in the background and display CPU usage on the different states (user, system, iowait, nice, steal).

The script is a fork from the original check_cpu_stats plugin by Steve Bosek. It was using ksh as Shell. The newer release now runs natively on the Bash shell and supports additional parameters.


### Parameters

All parameters are optional.

| Parameter | Description | Default |
| ----------| ----------- | ------- |
| -w | Warning thresholds for cpu usage. Syntax: cpu_user,cpu_system,cpu_iowait. Must be used together with `-c`. | 70,40,30 |
| -c | Warning thresholds for cpu usage. Syntax: cpu_user,cpu_system,cpu_iowait. Must be used together with `-w`. | 90,60,40 |
| -i | Interval in seconds to run `iostat` in the background | 1 |
| -n | Number of `iostat` reports to obtain average values | 3 |
| -b | Bailout condition(s). The plugin will exit OK when condition matches (number of CPUs and process running), expects an input of N,process (e.g. 4,apache2). Can be used multiple times | - |
| -v | Show version | - |
| -h / --help | Show help | - |



### Usage / Examples
Basic CPU usage check without any options:

```
$ ./check_cpu_stats.sh 
CPU STATISTICS OK : user=0.84% system=0.50%, iowait=0.00%, idle=98.66%, nice=0.00%, steal=0.00% | CpuUser=0.84%;70;90;0; CpuSystem=0.50%;40;60;0; CpuIowait=0.00%;30;40;0; CpuIdle=98.66%;0;0;0; CpuNice=0.00%;0;0;0; CpuSteal=0.00%;0;0;0;
```

CPU Usage check with thresholds. Warning alert when USER is above 50%, SYSTEM is above 30% and IOWAIT is above 10%. Critial alert when USER is above 80%, SYSTEM is above 50% and IOWAIT is above 30%:

```
$ ./check_cpu_stats.sh -w 50,30,10 -c 80,50,30
CPU STATISTICS OK : user=1.17% system=0.25%, iowait=0.00%, idle=98.58%, nice=0.00%, steal=0.00% | CpuUser=1.17%;50;80;0; CpuSystem=0.25%;30;50;0; CpuIowait=0.00%;10;30;0; CpuIdle=98.58%;0;0;0; CpuNice=0.00%;0;0;0; CpuSteal=0.00%;0;0;0;
```

CPU Usage check with a bailout condition: `-b 'N,process to match'`. Bailout condition means if the number of processes match and the 'process to match' is currently running (seen with `ps aux`), the plugin will return OK, even if thresholds are hit:

```
$ ./check_cpu_stats.sh -w 50,30,10 -c 80,50,30 -b "12,sshd"
CPU STATISTICS OK - bailing out because of matched bailout patterns - user=0.50% system=0.17%, iowait=0.00%, idle=99.33%, nice=0.00%, steal=0.00% | CpuUser=0.50%;50;80;0; CpuSystem=0.17%;30;50;0; CpuIowait=0.00%;10;30;0; CpuIdle=99.33%;0;0;0; CpuNice=0.00%;0;0;0; CpuSteal=0.00%;0;0;0;
```





### History

| Release | Date | Author(s) | Desciption/Modification |
| --------| ---- | --------- | ------------------------|
| ???     | 2007-09-08 | Steve Bosek | created/released the plugin |
| 2.0     | 2008-02-16 | Steve Bosek | Solaris support and new parameters, addtional parameters (-i, -n) |
| 2.1     | 2008-06-08 | Steve Bosek | Bug perfdata and convert comma in point for Linux result |
| 2.1.1   | 2008-12-05 | Steve Bosek | Fixed improperly terminated string that was left open at line 130 |
| 2.1.2   | 2008-12-06 | Bas van der Doorn | Fixed linux steal reported as idle, comparisons |
| 2.2     | 2008-12-06 | Bas van der Doorn | Capable systems will output nice and steal data |
| 2.2.1   | 2008-12-06 | Steve Bosek | Add for uniform Unix output nice and steal data on all perfdata |
| 2.3     | 2008-12-11 | Steve Bosek | Add Threshold for user and system output with format -w user,system,iowait -c user,system,iowait |
| 2.3.1   | 2008-12-16 | Steve Bosek | Potability AIX,SOLARIS,LINUX for table initialisation (TAB_WARNING_THRESHOLD and TAB_CRITICAL_THRESHOLD) |
| 2.3.2   | 2008-12-22 | Steve Bosek | Strict Guideline Nagios for perfdata |
| 2.3.3   | 2008-02-08 | Philipp Lemke / Steve Bosek | Add HP-UX support (tested on HP-UX B.11.23 U ia64), uniform perfdata |
| 2.3.4   | 2009-03-29 | Steve Bosek | Bug in line 176: return only critical state for warning condition for USER Stats. |
| 2.3.5   | 2009-05-05 | Steve Bosek | Bug fix in NAGIOS_DATA for HP-UX |
| 2.3.6   | 2011-08-05 | Steve Bosek | Bug fix in NAGIOS_DATA : replace comma with semicolon in perfdata - compatibility with pnp |
| ???   | 2016-06-11 | Philipp Dallig | Switch from ksh to bash |
| 3.0.0   | 2022-12-16 | Claudio Kuenzler | Multiple changes, added `-b` parameters for bailing out under certain conditions |
| 3.0.1   | 2022-12-16 | Claudio Kuenzler | Use pgrep -f for full process name in bailout check conditions |
| 3.1.0   | 2022-12-19 | Claudio Kuenzler | Change to pidof to avoid hitting own process, support multiple bailout conditions (multple `-b N,process` possible) |
| 3.1.1   | 2022-12-19 | Claudio Kuenzler | Change bailout process check back to pgrep to support process match with spaces (e.g. `-b "12,starter --daemon"`) |
| 3.1.2   | 2022-12-19 | Claudio Kuenzler | Bugfix in loop when using multiple bailout input |
| 3.1.3   | 2022-12-19 | Claudio Kuenzler | Change to pidof to avoid hitting own process |
| 3.1.4   | 2022-12-30 | Claudio Kuenzler | Change to ps aux to allow process matching, not just executable name |
