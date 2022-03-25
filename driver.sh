#!/bin/bash

# 5
declare -a WATERMARK_CONFIGS=("1" "10" "100" "500" "1000")
# 5
declare -a SWAPPINESS_CONFIGS=("1" "10" "20" "50" "100")
# 4
declare -a ZSWAP_MAX_POOL_PERCENTS=("1", "5", "10", "20")
# 4
declare -a ZSWAP_ACCEPT_THRESHOLDS=("80", "85", "90", "95")
# 3
declare -a ZSWAP_ZPOOLS=("zbud", "z3fold", "zsmalloc")
# 5
declare -a ZSWAP_COMPRESSORS=("lzo", "lz4", "lz4hc", "deflate", "842")

declare -a TESTS=("tailbench" "ycsb" "memtier")

CURR_DIR=`pwd`
MEM_BENCH_DIR="home/yans3/benchmarks/memsys-benchmarking"

run_test() {
  for TEST in "${TESTS[@]}"; do
    # start collecting statistic

    cd "${MEM_BENCH_DIR}/${TEST}"
    ./run.sh

  done
}

# Baseline model, w/o zswap
run_baseline() {
  echo 0 > /sys/module/zswap/parameters/enabled & sleep 3
  for WATERMARK_CONFIG in "${WATERMARK_CONFIGS[@]}"; do
    for SWAPPINESS_CONFIG in "${SWAPPINESS_CONFIGS[@]}"; do
        config_str="base/${WATERMARK_CONFIG}/${SWAPPINESS_CONFIG}"
        echo "[tittle]/${config_str}"
        echo ""
        # Clear swap
        swapoff -a & sleep 10


        # Enable swap
        swapon -a & sleep 3
        swapon /swap_file & sleep 3

        # run test
        run_test
    done
  done
}
# zswap model, w/ zswap
run_zswap() {

  for WATERMARK_CONFIG in "${WATERMARK_CONFIGS[@]}"; do
    for SWAPPINESS_CONFIG in "${SWAPPINESS_CONFIGS[@]}"; do
      for MAX_POOL_PERCENT in "${ZSWAP_MAX_POOL_PERCENTS[@]}"; do
        for THRESHOLD in "${ZSWAP_ACCEPT_THRESHOLDS[@]}"; do
          for ZPOOL in "${ZSWAP_ZPOOLS[@]}"; do
            for COMPRESSOR in "${ZSWAP_COMPRESSORS[@]}"; do
                config_str="zswap/${WATERMARK_CONFIG}/${SWAPPINESS_CONFIG}/${MAX_POOL_PERCENT}/${THRESHOLD}/${ZPOOL}/${COMPRESSOR}"
                echo "[tittle]/${config_str}"
                echo ""

                echo 0 > /sys/module/zswap/parameters/enabled & sleep 3
                # Clear swap
                swapoff -a & sleep 10

                # Enable swap
                swapon -a & sleep 3
                swapon /swap_file & sleep 3
                echo 1 > /sys/module/zswap/parameters/enabled & sleep 3

                # run test
                run_test config_str;
            done
          done
        done
      done
    done
  done
}

run_baseline;
run_zswap;