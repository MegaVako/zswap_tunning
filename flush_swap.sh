echo "swapofff"
sudo swapoff -a
sleep 10
echo "swapon"
sudo swapon -a
sudo swapon /swap_file
sudo swapon /swapfile2
