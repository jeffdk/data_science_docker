#!/bin/bash

useradd -m $NEW_USER -u $NEW_USER_ID
chown -R $NEW_USER /home/$NEW_USER
chgrp -R $NEW_USER /home/$NEW_USER
cp /etc/pam.d/login /etc/pam.d/rstudio
echo "$NEW_USER:$NEW_USER_PW" | chpasswd
adduser $NEW_USER sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
