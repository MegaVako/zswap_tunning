sudo echo 0 > /sys/module/zswap/parameters/enabled;
sudo sysctl -w vm.watermark_scale_factor=10;
sudo echo 60 > /proc/sys/vm/swappiness;
