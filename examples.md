# Examples

## Standard Usage

These examples identify queries that are used for the most basic searches. Any rwfilter command needs an INPUT_ARG, an OUTPUT_ARG, and a PARTITIONING_ARG at minimum. Pipe the rwfilter command to rwcut to print the results in a human readable format.

Example of arguments

|  INPUT_ARGS | OUTPUT_ARGS | PARTITIONING_ARGS | End Result |
| ------------- |:-------------:| -----:| -----:|
| --type=all      | --protocol=0-255 | --pass=stdout | rwfilter --type=all --protocol=0-255 --pass=stdout |

---

* Print all flows for the current day until the current time

`rwfilter --type=all --protocol=0-255 --pass=stdout | rwcut`

---

* Print flows where the src and dest port are 1024 or greater

`--type=all --sport=1024- --dport=1024- --pass=stdout | rwcut`

## Examples from http://tools.netsa.cert.org/silk/analysis-handbook.pdf

5.2.3 Simple PySiLK with rwfilter --python-expr

`rwfilter --type=all --protocol=6,17 --python-expr='rec.sport==rec.dport' --pass=stdout | rwcut`
