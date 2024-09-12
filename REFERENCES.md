# References

## sysctl

```bash
# References:
# https://github.com/CryoByte33/steam-deck-utilities/blob/main/docs/tweak-explanation.md
# https://wiki.cachyos.org/configuration/general_system_tweaks/
# https://gitlab.com/cscs/maxperfwiz/-/blob/master/maxperfwiz?ref_type=heads

# Disabling watchdog will speed up your boot and shutdown, because one less module is loaded. Additionally disabling watchdog timers increases performance and lowers power consumption.
kernel.nmi_watchdog=0

# In some cases, split lock mitigate can slow down performance in some applications and games. https://github.com/doitsujin/dxvk/issues/2938
kernel.split_lock_mitigate=0

# This feature proactively defragments memory when Linux detects "downtime".
# Note that compaction has a non-trivial system-wide impact as pages belonging to different processes are moved around, which could also lead to latency spikes in unsuspecting applications.
vm.compaction_proactiveness=0

# PLU configures how many times a process can try to get a lock on a page before "fair" behavior kicks in, and guarantees that process access to a page. https://www.phoronix.com/review/linux-59-fairness
vm.page_lock_unfairness=1

# total available memory that contains free pages and reclaimable pages, the number of pages at which a process which is generating disk writes will itself start writing out dirty data. Note the optimum percentage may change depending on amount of available memory. Values resulting in 100MB-600MB are ideal.
vm.dirty_bytes=419430400

# total available memory that contains free pages and reclaimable pages, the number of pages at which the background kernel flusher threads will start writing out dirty data.Note the optimum percentage may change depending on amount of available memory. Values resulting in 50MB-400MB are ideal.
vm.dirty_background_bytes=209715200

# Dirty expire centisecs tunable is used to define when dirty data is old enough to be eligible for writeout by the kernel flusher threads, expressed in 100'ths of a second. Data which has been dirty in-memory for longer than this interval will be written out next time a flusher thread wakes up.
vm.dirty_expire_centisecs=3000

# The kernel flusher threads will periodically wake up and write 'old' data out to disk.  This tunable expresses the interval between those wakeups, in 100'ths of a second.
vm.dirty_writeback_centisecs=1500
```

## AMD P-State EPP

```bash
# References:
# https://www.phoronix.com/review/amd-pstate-epp-ryzen-mobile
# https://www.phoronix.com/review/linux-63-amd-epyc-epp
# https://www.reddit.com/r/linux/comments/15p4bfs/amd_pstate_and_amd_pstate_epp_scaling_driver/

# Check scaling driver in use
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver

# Check EPP in use
cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference

# Check available EPP
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences

# Check scaling governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Check available scaling governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
```
