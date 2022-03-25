FRONTSWAP_PATH="/sys/kernel/debug/frontswap";
ZSWAP_PATH="/sys/kernel/debug/zswap";

echo "[STAT] frontswap ==================";
for i in `ls $FRONTSWAP_PATH`; do echo -n $i = ; cat "$FRONTSWAP_PATH/$i"; done;
echo "[STAT] zswap ======================";
for i in `ls $ZSWAP_PATH`; do echo -n $i = ; cat "$ZSWAP_PATH/$i"; done;
echo "[STAT] psi-mem ====================";
cat /proc/pressure/memory;
echo "[STAT] psi-cpu ====================";
cat /proc/pressure/cpu;
echo "[STAT] free-m =====================";
free -m;
