#!/bin/bash

# 5
declare -a WATERMARK_CONFIGS=("10" "500" "1000")
# 5
declare -a SWAPPINESS_CONFIGS=("20" "60" "100")
# 4
declare -a ZSWAP_MAX_POOL_PERCENTS=("1" "8" "20")
# 4
declare -a ZSWAP_ACCEPT_THRESHOLDS=("80" "90" "95")
# 3
declare -a ZSWAP_ZPOOLS=("zbud" "z3fold" "zsmalloc")
# 5
declare -a ZSWAP_COMPRESSORS=("lzo" "lz4" "lz4hc" "deflate" "842")

declare -a SIMPLE_TESTS=("ycsb")

CURR_DIR=`pwd`
MEM_BENCH_DIR="/home/yans3/benchmarks/memsys-benchmarking"
REDIS_DIR=${MEM_BENCH_DIR}/tools/redis/src
RESULT_DIR="result"

# $1 = configuration str, used for saving results
run_test() {
  SAVING_DIR=${CURR_DIR}/${RESULT_DIR}/${1}
  mkdir -p ${SAVING_DIR}
  bash snapshot_config.sh > ${SAVING_DIR}/config.txt

  for TEST in "${SIMPLE_TESTS[@]}"; do
    # Redis setup
    sudo rm -f ${REDIS_DIR}/*.rdb; sudo rm -f ./*.rdb; sudo rm -f ../*.rdb; sleep 4
    ${REDIS_DIR}/redis-server & sleep 15

    cd "${MEM_BENCH_DIR}/${TEST}"

    echo "[driver]/load b"
    ./run_${TEST}.sh load b
    cp ${TEST}-results.txt ${SAVING_DIR}/ycsb-load1.txt

    echo "[driver]/load a"
    ./run_${TEST}.sh load a
    cp ${TEST}-results.txt ${SAVING_DIR}/ycsb-load2.txt

    free -m > ${SAVING_DIR}/mem_load2.txt

    echo "[driver]/run a"
    ./run_${TEST}.sh run a
    cp ${TEST}-results.txt ${SAVING_DIR}/ycsb-run.txt

    # Redis reset
    echo "[driver]/flush db"
    ${REDIS_DIR}/redis-cli FLUSHALL
    sudo pkill -9 redis-server & sleep 4
  done
}

# Baseline model, w/o zswap
run_baseline() {
  echo 0 > /sys/module/zswap/parameters/enabled & sleep 3
  for WATERMARK_CONFIG in "${WATERMARK_CONFIGS[@]}"; do
    cd ${CURR_DIR}
    bash ./set_watermark.sh ${WATERMARK_CONFIG}

    for SWAPPINESS_CONFIG in "${SWAPPINESS_CONFIGS[@]}"; do
        cd ${CURR_DIR}
        bash ./set_swappiness.sh ${SWAPPINESS_CONFIG}

        config_str="base/${WATERMARK_CONFIG}/${SWAPPINESS_CONFIG}"
        echo "[tittle]/${config_str}"
        echo ""

        bash ./flush_swap.sh
        echo "flush swap successful"

        # run test
        run_test "${config_str}"
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
                run_test "${CURR_DIR}/${config_str}"
            done
          done
        done
      done
    done
  done
}

run_baseline;
#run_zswap;
