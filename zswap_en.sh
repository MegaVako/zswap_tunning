echo 1 > /sys/module/zswap/parameters/enabled
swapon -a
swapon /swap_file
