echo "swappiness=`cat /proc/sys/vm/swappiness`"
echo "watermark=`sysctl vm.watermark_scale_factor`"
grep -r . /sys/module/zswap/parameters
