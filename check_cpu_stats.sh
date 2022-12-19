#!/bin/bash
# ==============================================================================
# CPU Utilization Statistics plugin for Nagios 
#
# Original author:  Steve Bosek
# Creation date:    8 September 2007
# Description:      Monitoring plugin (script) to check cpu utilization statistics.
#                   This script has been designed and written on Unix platforms
#                   requiring iostat as external program.
#                   The script is used to query 6 of the key cpu statistics
#                   (user,system,iowait,steal,nice,idle) at the same time.
# History/Changes:  HISTORY moved out of plugin into Git repository / README.md
# License:          GNU General Public License v3.0 (GPL3), see LICENSE in Git repository
#
# Copyright 2007-2009,2011 Steve Bosek
# Copyright 2008 Bas van der Doorn
# Copyright 2008 Philipp Lemke
# Copyright 2016 Philipp Dallig
# Copyright 2022 Claudio Kuenzler
#
# Usage:   ./check_cpu_stats.sh [-w <user,system,iowait>] [-c <user,system,iowait>] ( [-i <report interval>] [-n <report number> ] [-b <N,processname>])
#
# Example: ./check_cpu_stats.sh
#          ./check_cpu_stats.sh -w 70,40,30 -c 90,60,40
#          ./check_cpu_stats.sh -w 70,40,30 -c 90,60,40 -i 3 -n 5 -b 1,apache2
# ========================================================================================
# -----------------------------------------------------------------------------------------
# Plugin description
PROGNAME=$(basename $0)
RELEASE="Revision 3.1.2"

# Paths to commands used in this script.  These may have to be modified to match your system setup.
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin # Set path
IOSTAT="iostat"
#Needed for HP-UX
SAR="/usr/bin/sar"

# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Plugin default parameters value if not defined
LIST_WARNING_THRESHOLD=${LIST_WARNING_THRESHOLD:="70,40,30"}
LIST_CRITICAL_THRESHOLD=${LIST_CRITICAL_THRESHOLD:="90,60,40"}
INTERVAL_SEC=${INTERVAL_SEC:="1"}
NUM_REPORT=${NUM_REPORT:="3"}
# -----------------------------------------------------------------------------------------
# Check required commands
if [ `uname` = "HP-UX" ];then
  if [ ! -x $SAR ]; then
    echo "UNKNOWN: sar not found or is not executable by the nagios user."
    exit $STATE_UNKNOWN
  fi
else
  for cmd in iostat; do
  if ! `which ${cmd} >/dev/null 2>&1`; then
    echo "UNKNOWN: ${cmd} does not exist, please check if command exists and PATH is correct"
    exit ${STATE_UNKNOWN}
  fi
done
fi
# -----------------------------------------------------------------------------------------
# Functions plugin usage
print_release() {
  echo "$RELEASE"
  exit ${STATE_UNKNOWN}
}

print_usage() {
  echo ""
  echo "$PROGNAME $RELEASE - Monitoring plugin to check CPU Utilization"
  echo ""
  echo "Usage: check_cpu_stats.sh [-w] [-c] [-i] [-n] [-b]+"
  echo ""
  echo "  -w  Warning threshold in % for warn_user,warn_system,warn_iowait CPU (default : 70,40,30)"
  echo "  -c  Critical threshold in % for crit_user,crit_system,crit_iowait CPU (default : 90,60,40)"
  echo "  -i  Interval in seconds for iostat (default : 1)"
  echo "  -n  Number of reports for iostat (default : 3)"
  echo "  -b  The plugin will exit OK when condition matches (number of CPUs and process running), expects an input of N,process (e.g. 4,apache2). Can be used multiple times: -b 1,puppet -b 4,apache2 -b 4,containerd. Works only under Linux."
  echo "  -v  Show version"
  echo "  -h  Show this page"
  echo ""
  echo "Usage: $PROGNAME"
  echo "Usage: $PROGNAME --help"
  echo ""
  exit 0
}

print_help() {
  print_usage
    echo ""
    echo "This plugin will check cpu utilization (user,system,iowait,idle in %)"
    echo ""
  exit 0
}
# -----------------------------------------------------------------------------------------
# Parse parameters
if [ "${1}" = "--help" ]; then print_help; exit $STATE_UNKNOWN; fi

while getopts "c:w:i:n:b:hv" Input
do
  case ${Input} in
  w)      LIST_WARNING_THRESHOLD=${OPTARG};;
  c)      LIST_CRITICAL_THRESHOLD=${OPTARG};;
  i)      INTERVAL_SEC=${OPTARG};;
  n)      NUM_REPORT=${OPTARG};;
  b)      BAIL+=("${OPTARG}");;
  h)      print_help;;
  v)      print_release;;
  *)      print_help;;
  esac
done
# -----------------------------------------------------------------------------------------
# List to Table for warning threshold
TAB_WARNING_THRESHOLD=( `echo $LIST_WARNING_THRESHOLD | sed 's/,/ /g'` )
if [ "${#TAB_WARNING_THRESHOLD[@]}" -ne "3" ]; then
  echo "ERROR : Bad count parameter in Warning Threshold"
  exit $STATE_WARNING
else  
USER_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[0]}`
SYSTEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[1]}`
IOWAIT_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[2]}` 
fi

# List to Table for critical threshold
TAB_CRITICAL_THRESHOLD=( `echo $LIST_CRITICAL_THRESHOLD | sed 's/,/ /g'` )
if [ "${#TAB_CRITICAL_THRESHOLD[@]}" -ne "3" ]; then
  echo "ERROR : Bad count parameter in CRITICAL Threshold"
  exit $STATE_WARNING
else 
USER_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[0]}`
SYSTEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[1]}`
IOWAIT_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[2]}`
fi

if [ ${TAB_WARNING_THRESHOLD[0]} -ge ${TAB_CRITICAL_THRESHOLD[0]} -o ${TAB_WARNING_THRESHOLD[1]} -ge ${TAB_CRITICAL_THRESHOLD[1]} -o ${TAB_WARNING_THRESHOLD[2]} -ge ${TAB_CRITICAL_THRESHOLD[2]} ]; then
  echo "ERROR : Critical CPU Threshold lower as Warning CPU Threshold "
  exit $STATE_WARNING
fi 
# -----------------------------------------------------------------------------------------
# CPU Utilization Statistics Unix Plateform ( Linux,AIX,Solaris are supported )
case `uname` in
  Linux )
      CPU_REPORT=`iostat -c $INTERVAL_SEC $NUM_REPORT | sed -e 's/,/./g' | tr -s ' ' ';' | sed '/^$/d' | tail -1`
      CPU_REPORT_SECTIONS=`echo ${CPU_REPORT} | grep ';' -o | wc -l`
      CPU_USER=`echo $CPU_REPORT | cut -d ";" -f 2`
      CPU_NICE=`echo $CPU_REPORT | cut -d ";" -f 3`
      CPU_SYSTEM=`echo $CPU_REPORT | cut -d ";" -f 4`
      CPU_IOWAIT=`echo $CPU_REPORT | cut -d ";" -f 5`
      if [ ${CPU_REPORT_SECTIONS} -ge 6 ]; then
      CPU_STEAL=`echo $CPU_REPORT | cut -d ";" -f 6`
      CPU_IDLE=`echo $CPU_REPORT | cut -d ";" -f 7`
      NAGIOS_DATA="user=${CPU_USER}% system=${CPU_SYSTEM}%, iowait=${CPU_IOWAIT}%, idle=${CPU_IDLE}%, nice=${CPU_NICE}%, steal=${CPU_STEAL}% | CpuUser=${CPU_USER}%;${TAB_WARNING_THRESHOLD[0]};${TAB_CRITICAL_THRESHOLD[0]};0; CpuSystem=${CPU_SYSTEM}%;${TAB_WARNING_THRESHOLD[1]};${TAB_CRITICAL_THRESHOLD[1]};0; CpuIowait=${CPU_IOWAIT}%;${TAB_WARNING_THRESHOLD[2]};${TAB_CRITICAL_THRESHOLD[2]};0; CpuIdle=${CPU_IDLE}%;0;0;0; CpuNice=${CPU_NICE}%;0;0;0; CpuSteal=${CPU_STEAL}%;0;0;0;"
      else
      CPU_IDLE=`echo $CPU_REPORT | cut -d ";" -f 6`
      NAGIOS_DATA="user=${CPU_USER}% system=${CPU_SYSTEM}%, iowait=${CPU_IOWAIT}%, idle=${CPU_IDLE}%, nice=${CPU_NICE}%, steal=0.00% | CpuUser=${CPU_USER}%;${TAB_WARNING_THRESHOLD[0]};${TAB_CRITICAL_THRESHOLD[0]};0; CpuSystem=${CPU_SYSTEM}%;${TAB_WARNING_THRESHOLD[1]};${TAB_CRITICAL_THRESHOLD[1]};0; CpuIowait=${CPU_IOWAIT}%;${TAB_WARNING_THRESHOLD[2]};${TAB_CRITICAL_THRESHOLD[2]};0; CpuIdle=${CPU_IDLE}%;0;0;0; CpuNice=${CPU_NICE}%;0;0;0; CpuSteal=0.0%;0;0;0;"
      fi

      # Bail out possible under certain situations
      if [[ ${#BAIL[*]} -gt 0 ]]; then
        BC_CPU=$(nproc)
        o=0
	while [ ${o} -lt ${#BAIL[*]} ]; do
          BAIL_CPU[${o}]=$(echo "${BAIL[${o}]}" | awk -F',' '{print $1}')
          BAIL_PROCESS[${o}]=$(echo "${BAIL[${o}]}" | awk -F',' '{print $2}')
          BC_PROCESS=$(pgrep -fo "${BAIL_PROCESS[${o}]}")
          if [[ ${BAIL_CPU[${o}]} -eq ${BC_CPU} && ${BC_PROCESS} -gt 0 ]]; then
            echo "CPU STATISTICS OK - bailing out because of matched bailout patterns - ${NAGIOS_DATA}"
            exit $STATE_OK
          fi
          let o++
        done
      fi

      ;;
  AIX ) CPU_REPORT=`iostat -t $INTERVAL_SEC $NUM_REPORT | sed -e 's/,/./g'|tr -s ' ' ';' | tail -1`
      CPU_USER=`echo $CPU_REPORT | cut -d ";" -f 4`
      CPU_SYSTEM=`echo $CPU_REPORT | cut -d ";" -f 5`
      CPU_IOWAIT=`echo $CPU_REPORT | cut -d ";" -f 7`
      CPU_IDLE=`echo $CPU_REPORT | cut -d ";" -f 6`
      NAGIOS_DATA="user=${CPU_USER}% system=${CPU_SYSTEM}%, iowait=${CPU_IOWAIT}%, idle=${CPU_IDLE}%, nice=0.00%, steal=0.00% | CpuUser=${CPU_USER}%;${TAB_WARNING_THRESHOLD[0]};${TAB_CRITICAL_THRESHOLD[0]};0; CpuSystem=${CPU_SYSTEM}%;${TAB_WARNING_THRESHOLD[1]};${TAB_CRITICAL_THRESHOLD[1]};0; CpuIowait=${CPU_IOWAIT}%;${TAB_WARNING_THRESHOLD[2]};${TAB_CRITICAL_THRESHOLD[2]};0; CpuIdle=${CPU_IDLE}%;0;0;0; CpuNice=0.0%;0;0;0; CpuSteal=0.0%;0;0;0;"
            ;;
  SunOS ) CPU_REPORT=`iostat -c $INTERVAL_SEC $NUM_REPORT | tail -1`
          CPU_USER=`echo $CPU_REPORT | awk '{ print $1 }'`
          CPU_SYSTEM=`echo $CPU_REPORT | awk '{ print $2 }'`
          CPU_IOWAIT=`echo $CPU_REPORT | awk '{ print $3 }'`
          CPU_IDLE=`echo $CPU_REPORT | awk '{ print $4 }'`
          NAGIOS_DATA="user=${CPU_USER}% system=${CPU_SYSTEM}%, iowait=${CPU_IOWAIT}%, idle=${CPU_IDLE}%, nice=0.00%, steal=0.00% | CpuUser=${CPU_USER}%;${TAB_WARNING_THRESHOLD[0]};${TAB_CRITICAL_THRESHOLD[0]};0; CpuSystem=${CPU_SYSTEM}%;${TAB_WARNING_THRESHOLD[1]};${TAB_CRITICAL_THRESHOLD[1]};0; CpuIowait=${CPU_IOWAIT}%;${TAB_WARNING_THRESHOLD[2]};${TAB_CRITICAL_THRESHOLD[2]};0; CpuIdle=${CPU_IDLE}%;0;0;0; CpuNice=0.0%;0;0;0; CpuSteal=0.0%;0;0;0;"
          ;;
  HP-UX) CPU_REPORT=`$SAR $INTERVAL_SEC $NUM_REPORT | grep Average`
          CPU_USER=`echo $CPU_REPORT | awk '{ print $2 }'`
          CPU_SYSTEM=`echo $CPU_REPORT | awk '{ print $3 }'`
          CPU_IOWAIT=`echo $CPU_REPORT | awk '{ print $4 }'`
          CPU_IDLE=`echo $CPU_REPORT | awk '{ print $5 }'`
          NAGIOS_DATA="user=${CPU_USER}% system=${CPU_SYSTEM}% iowait=${CPU_IOWAIT}% idle=${CPU_IDLE}% nice=0.00% steal=0.00% | CpuUser=${CPU_USER}%;${TAB_WARNING_THRESHOLD[0]};${TAB_CRITICAL_THRESHOLD[0]};0; CpuSystem=${CPU_SYSTEM}%;${TAB_WARNING_THRESHOLD[1]};${TAB_CRITICAL_THRESHOLD[1]};0; CpuIowait=${CPU_IOWAIT};${TAB_WARNING_THRESHOLD[2]};${TAB_CRITICAL_THRESHOLD[2]};0; CpuIdle=${CPU_IDLE}%;0;0;0; CpuNice=0.0%;0;0;0; CpuSteal=0.0%;0;0;0;"
          ;;  
  #  MacOS X test       
  # Darwin ) CPU_REPORT=`iostat -w $INTERVAL_SEC -c $NUM_REPORT | tail -1`
    #   CPU_USER=`echo $CPU_REPORT | awk '{ print $4 }'`
    #   CPU_SYSTEM=`echo $CPU_REPORT | awk '{ print $5 }'`
    #   CPU_IDLE=`echo $CPU_REPORT | awk '{ print $6 }'`
    #   NAGIOS_DATA="user=${CPU_USER}% system=${CPU_SYSTEM}% iowait=0.00% idle=${CPU_IDLE}% nice=0.00% steal=0.00% | CpuUser=${CPU_USER}%;${TAB_WARNING_THRESHOLD[0]};${TAB_CRITICAL_THRESHOLD[0]};0; CpuSystem=${CPU_SYSTEM}%;${TAB_WARNING_THRESHOLD[1]};${TAB_CRITICAL_THRESHOLD[1]};0; CpuIowait=0.0%;0;0;0; CpuIdle=${CPU_IDLE}%;0;0;0; CpuNice=0.0%;0;0;0; CpuSteal=0.0%;0;0;0;"
    #   ;;
  *)  echo "UNKNOWN: `uname` not yet supported by this plugin. Coming soon !"
      exit $STATE_UNKNOWN 
      ;;
esac
# -----------------------------------------------------------------------------------------
# Add for integer shell issue
CPU_USER_MAJOR=`echo $CPU_USER| cut -d "." -f 1`
CPU_SYSTEM_MAJOR=`echo $CPU_SYSTEM | cut -d "." -f 1`
CPU_IOWAIT_MAJOR=`echo $CPU_IOWAIT | cut -d "." -f 1`
CPU_IDLE_MAJOR=`echo $CPU_IDLE | cut -d "." -f 1`
# -----------------------------------------------------------------------------------------
# Return
if [ ${CPU_USER_MAJOR} -ge $USER_CRITICAL_THRESHOLD ]; then
    echo "CPU STATISTICS CRITICAL : ${NAGIOS_DATA}"
    exit $STATE_CRITICAL
    elif [ ${CPU_SYSTEM_MAJOR} -ge $SYSTEM_CRITICAL_THRESHOLD ]; then
    echo "CPU STATISTICS CRITICAL : ${NAGIOS_DATA}"
    exit $STATE_CRITICAL
    elif [ ${CPU_IOWAIT_MAJOR} -ge $IOWAIT_CRITICAL_THRESHOLD ]; then
    echo "CPU STATISTICS CRITICAL : ${NAGIOS_DATA}"
    exit $STATE_CRITICAL
    elif [ ${CPU_USER_MAJOR} -ge $USER_WARNING_THRESHOLD ] && [ ${CPU_USER_MAJOR} -lt $USER_CRITICAL_THRESHOLD ]; then
    echo "CPU STATISTICS WARNING : ${NAGIOS_DATA}"
    exit $STATE_WARNING 
    elif [ ${CPU_SYSTEM_MAJOR} -ge $SYSTEM_WARNING_THRESHOLD ] && [ ${CPU_SYSTEM_MAJOR} -lt $SYSTEM_CRITICAL_THRESHOLD ]; then
    echo "CPU STATISTICS WARNING : ${NAGIOS_DATA}"
    exit $STATE_WARNING 
    elif  [ ${CPU_IOWAIT_MAJOR} -ge $IOWAIT_WARNING_THRESHOLD ] && [ ${CPU_IOWAIT_MAJOR} -lt $IOWAIT_CRITICAL_THRESHOLD ]; then
    echo "CPU STATISTICS WARNING : ${NAGIOS_DATA}"
    exit $STATE_WARNING   
else
    echo "CPU STATISTICS OK : ${NAGIOS_DATA}"
    exit $STATE_OK
fi

echo "CPU STATISTICS UNKNOWN: Should never reach this."
exit $STATE_UNKNOWN
