# build pikafish on Android arm64

export NDKROOT=/Users/admin/Library/Android/sdk/ndk/25.1.8937393
export PLATFORM=$NDKROOT/toolchains/llvm/prebuilt/darwin-x86_64/sysroot
export CROSS_COMPILE=$NDKROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android31-

CC=${CROSS_COMPILE}clang++

$CC \
    -I${PWD} \
    -I${PLATFORM}/usr/include \
    -Wall \
    -Wcast-qual \
    -Wextra \
    -Wshadow \
    -std=c++17 \
    -DNDEBUG -O3 \
    -DUSE_NEON=8 \
    -DIS_64BIT \
    -DUSE_PTHREADS \
    -DUSE_POPCNT \
    -pedantic \
    -fno-exceptions \
    -flto=full \
    ./thread.cpp \
    ./timeman.cpp \
    ./ucioption.cpp \
    ./nnue/evaluate_nnue.cpp \
    ./nnue/features/half_ka_v2_hm.cpp \
    ./misc.cpp \
    ./bitboard.cpp \
    ./benchmark.cpp \
    ./movepick.cpp \
    ./tune.cpp \
    ./evaluate.cpp \
    ./search.cpp \
    ./compression/zip.cpp \
    ./movegen.cpp \
    ./tt.cpp \
    ./main.cpp \
    ./position.cpp \
    ./uci.cpp \
    -o pikafish
