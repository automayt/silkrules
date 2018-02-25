#!/bin/bash
usage() { echo "Usage: ./silkrules.sh [-h] [-f <filename>] ([-s <yyyy/mm/dd:hh>] [-e <yyyy/mm/dd:hh>] || [-t <minutes>]) rule1 rule2 rule3" 1>&2; exit 1; }
usageerror() { echo "Error: You can't use -t and -e together. -t calculates the start time and runs until the current time." 1>&2; exit 1; }
nohost() { echo "Error: You didn't specify a host file to run against. Please provide a list of hosts to run rules against with -f [filename]" 1>&2; exit 1; }
norule() { echo "Error: You didn't specify a rule or list of rules. Please pick a rule from the following;" 1>&2; echo; rulelist; echo; usage; }
toption() { echo "Error: The -t option specifies minutes to 'look back', and currently is limited to 1 week of data. Give it an integer value in minutes." 1>&2; exit 1; }
rulelist () {
rules=(dnstunneling ddos externalinfrastructure internalinfrastucture)
printf '%s\n' "${rules[@]}"
}
helpfunc() {
echo "Usage: ./silkrules.sh [-f <filename>] ([-s <yyyy/mm/dd>] [-e <yyyy/mm/dd>] || [-t <minutes>])- rule1 rule2 rule3" 1>&2;
echo
echo "-t [minutes] = How many minutes in the past would you like to run against. Useful for automated rolling rule runs. Most common."
echo "-s [<yyyy/mm/dd:hh>] = If specified with -e, specify the start date (or also use hourly resolution). Otherwise only look on that day."
echo "-e [<yyyy/mm/dd:hh>] = Specify only with -s as well. Specify the end date (or also use hourly resolution)."
echo "-f [<filename>] = Specify a filename containing a list of SiLK hosts to run queries against."
echo "The following rules are currently available;"
echo
rulelist
echo
exit 1; }

while getopts ":hs:e:t:f:" o; do
    case "${o}" in
        h)
            helpfunc
            ;;
        s)
            s=${OPTARG}
            ;;
        t)
            t=${OPTARG}
            ((t > 0 && t < 10081)) || toption
            ;;
        e)
            e=${OPTARG}
            ;;
        f)
            f=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -n "${h}" ]; then
    helpfunc
fi
if [ -z "${s}" ] && [ -z "${e}" ] && [ -z "${f}" ]; then
    usage
fi
if [ -z "${f}" ]; then
    nohost
fi
if ([ -n "${s}" ] || [ -n "${e}" ]) && [ -n "${t}" ]; then
    usageerror
fi
if [[ -z "${@}" ]]; then
    norule
fi

if [ -n "${s}" ]; then
starttime="--start-date=${s}"
echo $starttime
fi
if [ -n "${e}" ]; then
endtime="--end-date=${e}"
echo $endtime
fi
if [ -n "${t}" ]; then
enddate=`date -u "+%Y/%m/%d"`
endtimerange=`date -u "+%Y/%m/%dT%H:%M:%S.%3N"`
endtime="--end-date=$enddate"
startdate=`date -u -d "${t} minutes ago" "+%Y/%m/%d"`
starttimerange=`date -u -d "${t} minutes ago" "+%Y/%m/%dT%H:%M:%S.%3N"`
starttime="--start-date=$startdate"
activetime="--active-time=$starttimerange-$endtimerange"
echo $activetime $starttime $endtime

fi

#date -u +%Y/%m/%dT%H:%M:%S.%3N
if [ -n "${f}" ]; then
echo "hostlist = ${f}"
fi
#############
### ruleS ###
#############
###################################################################################################
#Detects DNS tunneling by looking at ratios of byte/packet sizes and their frequencies.
#Possible FPs related to unnatural dns queries by security appliances for reputation filtering
dnstunneling () {
echo "rwfilter $starttime $endtime $activetime --type=all --proto=17 --dport=53 --pass=stdout --bytes-per-packet=100- --plugin=flowrate.so --duration=1-60 --bytes=8000-  --payload-bytes=10000- --payload-rate=1500-| rwsort --plugin=flowrate.so --field=duration --reverse | rwcut --plugin=flowrate.so --fields=sIP,dIP,sPort,dPort,protocol,packets,bytes,sTime,dur,payload-bytes,payload-rate,bytes/sec,bytes/packet,pckts/sec"
}

###################################################################################################
#Detects DDOS patterns by flagging when a host exceeds 75 percents of all bytes on a network for the given time interval
ddos () {
echo "rwfilter $starttime $endtime $activetime --type=in,inweb --proto=0-255 --pass=stdout | rwstats --percentage=50 --fields=dip --value=bytes,distinct:dport,distinct:sport,distinct:sip"
}

###################################################################################################
#Identifies local infrastructure that is most known for talking to external hosts.
externalinfrastructure () {
echo "rwfilter $starttime $endtime $activetime --type=out,outweb --protocol=6 --flags-initial=SA/SA --pass=stdout | rwstats --top --percentage=.5 --fields=sip,sport --value=bytes,distinct:dip"
}

###################################################################################################
#Identifies internal2internal top talking infrastructure
internalinfrastructure () {
echo "rwfilter $starttime $endtime $activetime --type=int2int --protocol=6 --flags-initial=SA/SA --pass=stdout | rwstats --top --percentage=.5 --fields=sip,sport --value=bytes,distinct:dip"
}

###################################################################################################
#Identify hosts speaking outbound to 2 or more distinct destination country codes. Requires tuple file (sent with first command in function)
vpnanomaly () {
echo -e "0,50 \n0,51 \n500,17 \n4500,17 \n10000,6 \n943,6 \n1194,17 \n1723,6 \n0,47" > vpn.tuple; pscp -p 5 -t 0 -o ConnectTimeout=10 -h ${f} vpn.tuple /tmp/vpn.tuple
echo "rwfilter $starttime $endtime $activetime --type=out,outweb --tuple-file=/tmp/vpn.tuple --tuple-direction=forward --tuple-delimiter=, --tuple-fields=dport,proto --protocol=0-255 --pass=stdout| rwfilter - --sport=500,1025-3388,3390-65535 --pass=stdout | rwfilter - --dcc=-- --fail=stdout| rwstats --top --threshold=2 --fields=sip --value=distinct:dcc,bytes,records,packets"
}

###################################################################################################
#Identify internal infrastructure that have reached out with unsolicited outbound requests.
inthostanomaly () {
parallel-ssh -p 5 -t 0 -o ConnectTimeout=10 -h ${f} 'if [ -f /tmp/int2intservers.set ]; then rm /tmp/int2intservers.set; fi' | grep -v SUCCESS | grep -v FAILURE
echo "rwfilter $starttime $endtime $activetime --type=int2int --protocol=6 --flags-initial=SA/SA --pass=stdout | rwstats --top --percentage=.5 --fields=sip --value=bytes --delimited=, --no-columns --no-titles | cut -d, -f1 | rwsetbuild stdin /tmp/int2intservers.set;"
echo "rwfilter $starttime $endtime $activetime --type=in,inweb --flags-initial=SA/SA --dipset=/tmp/int2intservers.set --pass=stdout | rwstats --top --count=20 --fields=dip --value=bytes,distinct:sport,distinct:dport"
}

###################################################################################################
#Identify local Slammer infected hosts by examination of payload bytes and traffic patterns.
slammer () {
echo "rwfilter $starttime $endtime $activetime --type=out,outweb,int2int --proto=17 --pass=stdout --plugin=flowrate.so --payload-bytes=376 --dport=1434 | rwcut --plugin=flowrate.so --fields=sIP,dIP,sPort,dPort,protocol,packets,bytes,payload-bytes,stime,dur"
}

slammertest () {
echo "rwfilter $starttime $endtime $activetime --type=out,outweb,int2int --proto=17 --pass=stdout --bytes=404 --dport=1434 | rwcut"
}
###################################################################################################
#Summary of total RDP traffic
rdp-summary () {
echo "rwfilter $starttime $endtime $activetime --type=all --proto=6,17 --aport=3389 --pass=stdout | rwfilter stdin --aport=1024- --print-volume-statistics=stdout | grep -B1 Total"
}

#Stats on top suspected RDP sip,dip pairs
rdp-top-hosts () {
echo "rwfilter $starttime $endtime $activetime --type=all --proto=6,17 --aport=3389 --pass=stdout | rwfilter stdin --aport=1024- --pass=stdout | rwstats --top --count=5 --fields=sip,dip --value=bytes"
}

#Stats on hosts suspected of having RDP open from the internet
rdp-from-internet () {
echo "rwfilter $starttime $endtime $activetime --type=in,inweb --proto=6,17 --sport=1024- --dport=3389 --pass=stdout | rwstats --top --count=5 --fields=dip --value=bytes,distinct:sip"
}

#Stats on hosts suspected of having RDP open from the internet
zeroaccess () {
echo "rwfilter $starttime $endtime $activetime --type=out --proto=6,17 --sport=1024- --dport=16470,16471,16464,16465 --pass=stdout | rwfilter --input-pipe=stdin --dcc=us,-- --fail=stdout| rwstats --top --threshold=3 --fields=sip --value=distinct:dcc"
}

smartinstall () {
echo "rwfilter $starttime $endtime $activetime --type=in --dport=4786 --proto=0-255 --pass=stdout | rwstats --top --threshold=5 --fields=sip --value=distinct:sport,distinct:dip,bytes"
}
#################################################################################################################################
#################################################################################################################################
#################################################################################################################################

if [[ -n "${@}" ]]; then
  for rule in "$@"; do
    rulecombine+="echo -e \"\n***** $rule rule results *****\""
    rulecombine+=";"
    rulecombine+=`$rule`
    rulecombine+=";"
  done

  #parallel-ssh -p 5 -i -t 0 -o ConnectTimeout=10 -h ${f} "$rulecombine"| sed -e $"/SUCCESS/i\\\n"|  sed "/SUCCESS/i----------------------------------------------------------------" | sed ''/SUCCESS/s//`printf "\033[32mSUCCESS\033[0m"`/'' | sed ''/FAILURE/s//`printf "\033[31mFAILURE\033[0m"`/'' | sed -e "s/^.*rule results.*$/\x1b[34m&\x1b[0m/"
#exit
parallel-ssh -v -p 5 -i -t 0 -o ConnectTimeout=10 -h ${f} "$rulecombine"| sed -e $"/SUCCESS/i\\\n"|  sed "/SUCCESS/i----------------------------------------------------------------" | sed ''/SUCCESS/s//`printf "\033[32mSUCCESS\033[0m"`/'' | sed ''/FAILURE/s//`printf "\033[31mFAILURE\033[0m"`/'' | sed -e "s/^.*rule results.*$/\x1b[1;34m&\x1b[0m/"
fi
