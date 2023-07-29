#!/bin/bash
################################################################
#  Copyright © 2020-2021 by SAS Institute Inc., Cary, NC, USA  #
#  All Rights Reserved.                                        #
################################################################

- ()
{
   :sudo || :reenter                                     # This function must run as root

   :log: --push-section 'Updating' '/etc/sysctl and /etc/hosts' "$FUNCNAME $@"

   :file:ensure_nl_at_end /etc/sysctl.conf               # Ensure file ends with a newline

   local -i SwapSize
   SwapSize="$( swapon --show=SIZE --bytes | tail -1 )"

   if [[ -n $SwapSize && $SwapSize =~ ^[0-9]+$ ]]; then
      if (( SwapSize <= 16*1024**3 )); then              # At least 16GB is required for Oracle
         if [[ -f /swapfile ]]; then                     # A swapfile must not already exist
            :error: 0 "Swapfile /swapfile already exists and size $SwapSize < 16GB"

         else
            SwapSize=$(( (17*1024**3 - SwapSize) / (1024**2) ))
                                                         # Add at least 16GB and up to 1GB more than 16GB
                                                         # Divide by 1024**2 to yield units in MB
            dd if=/dev/zero of=/swapfile bs=1M count=$SwapSize
                                                         # Allocate the required space
            mkswap /swapfile                             # Setup a Linux swap area
            chmod 0600 /swapfile                         # Set required permissions
            swapon /swapfile                             # Enable the swap device
         fi
      fi
   fi

   # Update sysctl.conf for use by SAS and Oracle
   cat >/etc/sysctl.conf <<EOF
######################################################################
# Kernel sysctl configuration file for Red Hat Linux                 #
#                                                                    #
# For binary values, 0 is disabled, 1 is enabled.  See sysctl(8) and #
# sysctl.conf(5) for more details.                                   #
#                                                                    #
# Use '/sbin/sysctl -a' to list all possible parameters.             #
######################################################################

# +---------------------------------------------------------+
# | KERNEL PARAMETERS                                       |
# +---------------------------------------------------------+

# Controls the System Request debugging functionality of the kernel
kernel.sysrq = 0

# Controls whether core dumps will append the PID to the core filename.
# Useful for debugging multi-threaded applications.
kernel.core_uses_pid = 1

# Controls the use of TCP syncookies
net.ipv4.tcp_syncookies = 1

# Controls the default maxmimum size of a mesage queue
kernel.msgmnb = 65536

# Controls the maximum size of a message, in bytes
kernel.msgmax = 65536

# Maximum shared segment size (in bytes) for a shared memory segment
kernel.shmmax = 16835590144

# Maximum amount of shared memory (in pages) that
# can be used at one time on the system and should be at
# least ceil(SHMMAX/PAGE_SIZE)
kernel.shmall = 4110252

# Maximum number of shared memory segments system wide
kernel.shmmni = 4096

# +---------------------------------------------------------+
# | SEMAPHORES                                              |
# +---------------------------------------------------------+

# SEMMSL_value  SEMMNS_value  SEMOPM_value  SEMMNI_value
kernel.sem = 250 32000 100 128

# +---------------------------------------------------------+
# | NETWORKING                                              |
# ----------------------------------------------------------+

# Controls IP packet forwarding
net.ipv4.ip_forward = 0

# Controls source route verification
net.ipv4.conf.default.rp_filter = 1

# Do not accept source routing
net.ipv4.conf.default.accept_source_route = 0

# Defines the local port range that is used by TCP and UDP
# traffic to choose the local port
net.ipv4.ip_local_port_range = 9000 65500

# Default setting in bytes of the socket "receive" buffer which
# may be set by using the SO_RCVBUF socket option
net.core.rmem_default = 4194304

# Maximum setting in bytes of the socket "receive" buffer which
# may be set by using the SO_RCVBUF socket option
net.core.rmem_max = 4194304

# Default setting in bytes of the socket "send" buffer which
# may be set by using the SO_SNDBUF socket option
net.core.wmem_default = 4194304

# Maximum setting in bytes of the socket "send" buffer which
# may be set by using the SO_SNDBUF socket option
net.core.wmem_max = 4194304

# The pfifo_fast algorithm was intended for WiFi, but others have not been tested
net.core.default_qdisc = pfifo_fast

# Discourage Linux from swapping out idle processes to disk (default is 60)
vm.swappiness = 20
vm.dirty_ratio = 40
vm.dirty_background_ratio = 10

net.core.somaxconn = 3000
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5

# Do not cache metrics on closing connections
net.ipv4.tcp_no_metrics_save = 1

# Maximum number of remembered connection requests, which did not yet
# receive an acknowledgment from connecting client.
net.ipv4.tcp_max_syn_backlog = 10240

# Increase number of incoming connections backlog queue
# Sets the maximum number of packets, queued on the INPUT
# side, when the interface receives packets faster than
# kernel can process them.
net.core.netdev_max_backlog = 65536

# Increase the maximum amount of option memory buffers
net.core.optmem_max = 4194304

# Disable the TCP timestamps option for better CPU utilization
net.ipv4.tcp_timestamps = 0

# Enable the TCP selective acks option for better throughput
net.ipv4.tcp_sack = 1


# Increase memory thresholds to prevent packet dropping
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 65536 4194304

# Enable low latency mode for TCP
net.ipv4.tcp_low_latency = 1

# +---------------------------------------------------------+
# | FILE HANDLES                                            |
# ----------------------------------------------------------+

# Maximum number of file-handles that the Linux kernel will allocate
fs.file-max = 6815744

# Maximum number of allowable concurrent asynchronous I/O requests requests
fs.aio-max-nr = 1048576
EOF

   sysctl -p
   dracut -v -f

   sed -i -e '/^::1/d' -e '/^\s*$/d' /etc/hosts          # Ensure ipv6 is not referenced

   :log: --pop
}
