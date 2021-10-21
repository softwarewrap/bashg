#!/bin/bash
################################################################
#  Copyright © 2020-2021 by SAS Institute Inc., Cary, NC, USA  #
#  All Rights Reserved.                                        #
################################################################

.dev:need:xvfb:linux-7()
{
   :sudo || :reenter                                     # This function must run as root

   [[ ! -f /etc/systemd/system/xvfb@.service ]] || return 0

   :log: --push-section 'Installing' 'xvfb' "$FUNCNAME $@"

   :require:packages xorg-x11-server-Xvfb

   cat >/etc/systemd/system/xvfb@.service <<EOF
[Unit]
Description=virtual frame buffer X server for display %I
After=network.target

[Service]
ExecStart=/usr/bin/Xvfb %I -screen 0 1280x1024x24

[Install]
WantedBy=multi-user.target
EOF

   systemctl daemon-reload
   systemctl enable xvfb@:1.service
   systemctl start xvfb@:1.service

   :log: --pop
}
