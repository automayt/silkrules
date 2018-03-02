# Examples

## Standard Usage

These examples identify queries that are used for the most basic searches. Any rwfilter command needs an INPUT_ARG, an OUTPUT_ARG, and a PARTITIONING_ARG at minimum. Pipe the rwfilter command to rwcut to print the results in a human readable format.

* Print all flows from the current day.

|  INPUT_ARGS | OUTPUT_ARGS | PARTITIONING_ARGS | End Result |
| ------------- |:-------------:| -----:| -----:|
| --type=all      | --protocol=0-255 | --pass=stdout | rwfilter --type=all --protocol=0-255 --pass=stdout |


rwfilter --type=all --protocol=0-255

## Examples from http://tools.netsa.cert.org/silk/analysis-handbook.pdf

5.2.3 Simple PySiLK with rwfilter --python-expr

`rwfilter --type=all --protocol=6,17 --python-expr='rec.sport==rec.dport' --pass=stdout | rwcut`
