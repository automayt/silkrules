## rwfilter/rwcut Examples

These examples identify queries that are used for the most basic searches. Any rwfilter command needs an INPUT_ARG, an OUTPUT_ARG, and a PARTITIONING_ARG at minimum. Pipe the rwfilter command to rwcut to print the results in a human readable format.

Example of arguments

|  INPUT_ARGS | OUTPUT_ARGS | PARTITIONING_ARGS | End Result |
| ------------- |:-------------:| -----:| -----:|
| --type=all      | --protocol=0-255 | --pass=stdout | rwfilter --type=all --protocol=0-255 --pass=stdout |

---

* Print all flows for the current day until the current time

`rwfilter --type=all --protocol=0-255 --pass=stdout | rwcut`

---

* Print flows where the src port AND dest port are 1024 or greater

`rwfilter --type=all --sport=1024- --dport=1024- --pass=stdout | rwcut`

---

* Print flows for UDP traffic where either the src ip or dest ip is in the 74.207.236.0/24 range, and where either src port or dest port are 13414. Use rwcut to only print the stime and 5 tuple information.

```
rwfilter --type=all --proto=0-255 --any-address=74.207.236.0/24 --aport=13414 --pass=stdout | \
rwcut --fields=stime,sip,sport,dip,dport,proto --num-recs=5
```

---

## rwcount Examples
* See how many Records, Bytes, and Packets were in each minute span of the data passed by rwfilter. If there are "zeroes" and you don't care about them, rwcount has options to skip them (--skip-zeroes).
```
jason@ubuntu:~$ rwfilter bigflows.rwf --protocol=0-255 --pass=stdout | rwcount --bin-size=60
               Date|        Records|               Bytes|          Packets|
2013/02/26T22:02:00|        3611.89|         18614204.53|         53002.61|
2013/02/26T22:03:00|        9256.81|         64563508.85|        159741.30|
2013/02/26T22:04:00|        9111.26|         78239972.02|        174633.24|
2013/02/26T22:05:00|        7769.27|         66208934.92|        157147.40|
2013/02/26T22:06:00|        7587.82|         79101053.99|        165364.23|
2013/02/26T22:07:00|        4421.96|         36035699.69|         81290.22|
```
----

## rwstats Examples

rwstats performs statistical calculations on the flow records provided from the previous flow file or rwfilter output. rwstats works off of the binary flow data, so churning data through rwcut is not necessary.

---

* Determine the top 10 protocols by bytes for the current day until the current time, and print the number of packets and records with each. The order of --value matters here. The calculation will be based on the first value in the list. Try saying what you want in common terms, and then making a statistical query out of it. In this case, "I want the TOP TEN PROTOCOLS by BYTES", and then you'll find that rwstats becomes easier to use. Here we generate the flows we want with the rwfilter command, and rwstats takes the binary output and runs stats against it.

`rwfilter --type=all --protocol=0-255 --pass=stdout | rwstats --top --count=10 --field=protocol --value=bytes,packets,records`

* Determine the top 10 externally facing RDP IP address and how many external addresses are connecting to it, as well as how many total bytes made up that conversation. In cases where the byte count might represent real data moving across, you could then filter down on the local address and do a rwstats for the external addresses themselves that make up the majority of the data.

`rwfilter --type=in --protocol=6 --dport=3389 --pass=stdout | rwstats --top --count=10 --field=dip --value=distinct:sip`

* Analyzing application protocol usage with the application field. See for more information; https://tools.netsa.cert.org/yaf/applabel.html
```
jason@jason-virtual-machine:~$ rwfilter --type=all --proto=0- --pass=stdout | rwstats --top --count=10 --fields=application --value=bytes
INPUT: 42016 Records for 18 Bins and 1105213572 Total Bytes
OUTPUT: Top 10 Bins by Bytes
appli|               Bytes|    %Bytes|   cumul_%|
  443|           811799057| 73.451781| 73.451781|
    0|           192358874| 17.404679| 90.856460|
   80|            99432602|  8.996687| 99.853147|
   53|              459438|  0.041570| 99.894717|
   22|              443244|  0.040105| 99.934822|
  161|              321043|  0.029048| 99.963870|
 5222|              206076|  0.018646| 99.982516|
   21|               65262|  0.005905| 99.988421|
  137|               46995|  0.004252| 99.992673|
 5060|               28158|  0.002548| 99.995221|
```
* Print the "TOP" "10" "SIP" addresses. Say what you want in a sentence, and you'll probably be able to write it like that in rwstats.
```
jason@ubuntu:~$ rwfilter bigflows.rwf --protocol=0-255 --pass=stdout | rwstats --top --count=10 --fields=sip
INPUT: 41759 Records for 1845 Bins and 41759 Total Records
OUTPUT: Top 10 Bins by Records
            sIP|   Records|  %Records|   cumul_%|
 172.16.128.169|      1429|  3.422017|  3.422017|
   172.16.133.6|      1263|  3.024498|  6.446515|
        8.8.8.8|      1063|  2.545559|  8.992074|
 172.16.133.116|      1031|  2.468929| 11.461002|
  172.16.133.41|       868|  2.078594| 13.539596|
 172.16.133.109|       839|  2.009148| 15.548744|
  172.16.133.66|       740|  1.772073| 17.320817|
  172.16.133.78|       712|  1.705022| 19.025839|
  172.16.133.54|       707|  1.693048| 20.718887|
  172.16.133.93|       677|  1.621207| 22.340094|
```
* Print the "TOP" "10" "DPORT"s, but this time you're doing stats against the summation of their bytes. This is counting the total bytes for every record with each respective dport and summing it up, then giving you the top 10.
```
jason@ubuntu:~$ rwfilter bigflows.rwf --protocol=0-255 --pass=stdout | rwstats --top --count=10 --fields=dport --value=bytes
INPUT: 41759 Records for 10420 Bins and 342763374 Total Bytes
OUTPUT: Top 10 Bins by Bytes
dPort|               Bytes|    %Bytes|   cumul_%|
  443|            63657651| 18.571894| 18.571894|
 1853|            23481685|  6.850698| 25.422593|
 5500|            16709768|  4.875016| 30.297608|
53037|            14835084|  4.328083| 34.625691|
 5440|            11190408|  3.264762| 37.890453|
   80|             9722995|  2.836649| 40.727103|
 1731|             5202254|  1.517739| 42.244842|
60658|             4674970|  1.363906| 43.608748|
49311|             4589792|  1.339056| 44.947803|
64373|             4586994|  1.338239| 46.286043|
```
* Using "plugins" for doing extra massaging of data. Here we are using the built-in "app-mismatch.so" plugin. It will compare ports with the application protocol that was detected and show records when those didn't match up.
* This command is taking all data for the rwf file, and identifying any ports that didn't match the applications that were decoded. It then does a stat on that data to pull the top 10 sip,dip pairs by bytes. I've thrown in source country code (scc) and destination country code (dcc) for decoration.
```
jason@ubuntu:~$ rwfilter bigflows.rwf --protocol=0-255 --plugin=app-mismatch.so --pass=stdout | rwstats --top --count=10 --fields=sip,scc,dip,dcc --value=bytes
```

---

## Advanced Examples
* Consider all data in bigflows.rwf, and pass it to another filter which will take that data, and FAIL and data that has a dcc of (us or --). The next filter takes that data (now with dcc=us or dcc=-- removed), and it will further remove --dport=80. These can't be done in the same rwfilter FAIL filter because rwfilter is "ANDing" all things within unless otherwise stated (single things like dcc that allow comma delimited values).
```
jason@ubuntu:~$ rwfilter bigflows.rwf --protocol=0-255  --pass=stdout | rwfilter --input-pipe=stdin --dcc=us,-- --fail=stdout | rwfilter --input-pipe=stdin --dport=80 --fail=stdout  | rwstats --top --count=10 --fields=dcc,dport --value=bytes
INPUT: 538 Records for 176 Bins and 513565 Total Bytes
OUTPUT: Top 10 Bins by Bytes
dcc|dPort|               Bytes|    %Bytes|   cumul_%|
 ca|33378|              198033| 38.560455| 38.560455|
 nl|  443|               52871| 10.294899| 48.855354|
 ag|  443|               52732| 10.267834| 59.123188|
 se| 4070|               37622|  7.325655| 66.448843|
 gb|  443|               27513|  5.357258| 71.806100|
 ie|  443|               23893|  4.652381| 76.458481|
 eu|  443|               22820|  4.443449| 80.901931|
 au|  443|               14712|  2.864681| 83.766612|
 cn|  443|               10660|  2.075687| 85.842298|
 hk|40011|                6007|  1.169667| 87.011965|
```
 * Using the flowrate.so plugin is a good way to do quick maths on data to consider addresses that did large transfer "rates". Pair that with a byte count for decoration and you've got some stuff to hunt with. In this example there is one outlier.
```
jason@ubuntu:~$ rwfilter bigflows.rwf --protocol=0-255  --pass=stdout | rwstats --top --count=10 --plugin=flowrate.so --fields=sip --value=bytes/sec,bytes
 INPUT: 41759 Records for 1845 Bins
 OUTPUT: Top 10 Bins by bytes/sec
             sIP|      bytes/sec|               Bytes|%bytes/sec|   cumul_%|
   111.221.74.16|    2145000.000|                1716|         ?|         ?|
  157.55.130.142|    1756250.000|                1405|         ?|         ?|
    208.85.44.22|    1745789.959|             1703891|         ?|         ?|
    157.56.52.13|    1417500.000|                 567|         ?|         ?|
   157.55.56.144|    1290000.000|                 516|         ?|         ?|
     64.4.23.157|    1287500.000|                 515|         ?|         ?|
     64.4.23.159|    1262500.000|                 505|         ?|         ?|
    65.55.223.25|    1196250.000|                 957|         ?|         ?|
  111.221.77.166|    1195000.000|                 478|         ?|         ?|
    86.162.66.33|    1135000.000|                 454|         ?|         ?|
```

## Examples from http://tools.netsa.cert.org/silk/analysis-handbook.pdf

* TCP and UDP traffic, but leveraging --python-expr to match records with the same sport and dport. Example 5.2.3

`rwfilter --type=all --protocol=6,17 --python-expr='rec.sport==rec.dport' --pass=stdout | rwcut`
