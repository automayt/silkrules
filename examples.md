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

## rwstats Examples

rwstats performs statistical calculations on the flow records provided from the previous flow file or rwfilter output. rwstats works off of the binary flow data, so churning data through rwcut is not necessary.

---

* Determine the top 10 protocols by bytes for the current day until the current time, and print the number of packets and records with each. The order of --value matters here. The calculation will be based on the first value in the list. Try saying what you want in common terms, and then making a statistical query out of it. In this case, "I want the TOP TEN PROTOCOLS by BYTES", and then you'll find that rwstats becomes easier to use. Here we generate the flows we want with the rwfilter command, and rwstats takes the binary output and runs stats against it.

`rwfilter --type=all --protocol=0-255 --pass=stdout | rwstats --top --count=10 --field=protocol --value=bytes,packets,records`

## Examples from http://tools.netsa.cert.org/silk/analysis-handbook.pdf

* TCP and UDP traffic, but leveraging --python-expr to match records with the same sport and dport. Example 5.2.3

`rwfilter --type=all --protocol=6,17 --python-expr='rec.sport==rec.dport' --pass=stdout | rwcut`
