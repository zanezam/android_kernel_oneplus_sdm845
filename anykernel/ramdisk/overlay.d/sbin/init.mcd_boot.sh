#!/system/bin/sh

# (c) 2018-2022 changes for mcd-kernel by mcdachpappe

# Wait to set proper init values
sleep 30

# Set TCP congestion algorithm
echo "westwood" > /proc/sys/net/ipv4/tcp_congestion_control

# Tweak IO performance after boot complete
echo "zen" > /sys/block/sda/queue/scheduler
echo 512 > /sys/block/sda/queue/read_ahead_kb
echo "zen" > /sys/block/sdb/queue/scheduler
echo 512 > /sys/block/sdb/queue/read_ahead_kb
echo "zen" > /sys/block/sdc/queue/scheduler
echo 512 > /sys/block/sdc/queue/read_ahead_kb
echo "zen" > /sys/block/sdd/queue/scheduler
echo 512 > /sys/block/sdd/queue/read_ahead_kb
echo "zen" > /sys/block/sde/queue/scheduler
echo 512 > /sys/block/sde/queue/read_ahead_kb
echo "zen" > /sys/block/sdf/queue/scheduler
echo 512 > /sys/block/sdf/queue/read_ahead_kb

# Input boost and stune configuration
echo "0:1056000 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 500 > /sys/module/cpu_boost/parameters/input_boost_ms
echo 5 > /dev/stune/top-app/schedtune.boost

# Disable scheduler core_ctl
echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/enable

# Set min cpu freq
echo 300000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 825600 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq

# Configure cpu governor settings
echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 50 > /sys/devices/system/cpu/cpu0/cpufreq/zzmoove/down_threshold
echo 80000 > /sys/devices/system/cpu/cpu0/cpufreq/zzmoove/sampling_rate
echo "zzmoove" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
echo 55 > /sys/devices/system/cpu/cpu4/cpufreq/zzmoove/down_threshold
echo 80000 > /sys/devices/system/cpu/cpu4/cpufreq/zzmoove/sampling_rate

# Enable OTG by default
echo 1 > /sys/class/power_supply/usb/otg_switch

echo "Boot mcd completed " >> /dev/kmsg
