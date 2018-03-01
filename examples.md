Examples from http://tools.netsa.cert.org/silk/analysis-handbook.pdf

5.2.3 Simple PySiLK with rwfilter --python-expr

`rwfilter --type=all --protocol=6,17 --python-expr='rec.sport==rec.dport' --pass=stdout | rwcut`
