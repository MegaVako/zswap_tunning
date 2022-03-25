echo "$(LANG=c free -b |grep Swap |awk '{print $3}') - $(sudo \
cat /sys/kernel/debug/zswap/stored_pages)*$(getconf PAGESIZE)" |bc -l
echo bytes swapped on disk
