# check_cpu_stats
check_cpu_stats is an open source monitoring plugin which uses `iostat` (from the sysstat package) in the background and display CPU usage on the different states (user, system, iowait, nice, steal).

The script is a fork from the original check_cpu_stats plugin by Steve Bosek. It was using ksh as Shell. The newer release now runs natively on the Bash shell and supports additional parameters.

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
