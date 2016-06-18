#!/usr/bin/env bash

set -e -u

#
# Vultr PXE boot 
#
# vultr server create --name="boonux" --region=25 --plan=29 --os=159 --ipxe="https://raw.githubusercontent.com/sungsit/vultr/master/archlinux/arch64.jp.ipxe"
    
user="boonux"

# change mirrors
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
tee /etc/pacman.d/mirrorlist <<EOF
Server = http://ftp.tsukuba.wide.ad.jp/Linux/archlinux/\$repo/os/\$arch
Server = http://ftp.jaist.ac.jp/pub/Linux/ArchLinux/\$repo/os/\$arch
Server = http://ftp.kddilabs.jp/Linux/packages/archlinux/\$repo/os/\$arch
Server = http://srv2.ftp.ne.jp/Linux/packages/archlinux/\$repo/os/\$arch
Server = http://ftp.nara.wide.ad.jp/pub/Linux/archlinux/\$repo/os/\$arch
Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch
EOF

# get pacman.conf
mv /etc/pacman.conf /etc/pacman.conf.orig
wget -cO /etc/pacman.conf https://raw.githubusercontent.com/sungsit/boonux/master/airootfs/etc/pacman.conf

# add infinality-bundle repos key
mkdir -p /root/.gnupg
touch /root/.gnupg/S.dirmngr
pacman-key -r 962DDE58
pacman-key --lsign-key 962DDE58

# sync
pacman -Syy

# partitioning
parted -s /dev/vda mklabel msdos
parted -s /dev/vda mkpart primary linux-swap 1MiB 2049MiB
parted -s /dev/vda mkpart primary ext4 2049MiB 100%
parted -s /dev/vda set 2 boot on
parted -s /dev/vda print
mkfs.ext4 /dev/vda2
mkswap /dev/vda1
swapon /dev/vda1

# pacstrap
mount /dev/vda2 /mnt
LANG=C pacstrap /mnt base

genfstab -p /mnt > /mnt/etc/fstab
cp /etc/pacman.conf /mnt/etc/.
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/.

# basic settings
echo 'en_US.UTF-8 UTF-8' > /mnt/etc/locale.gen
echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf
echo ${user} > /mnt/etc/hostname
arch-chroot /mnt /bin/sh -c 'locale-gen'

# required packages
wget -cO /mnt/packages.txt https://raw.githubusercontent.com/sungsit/boonux/master/packages-build-env.txt
arch-chroot /mnt /bin/sh -c 'pacman -Syy'
arch-chroot /mnt /bin/sh -c 'pacman --noconfirm --needed -S $(grep -h -v ^# /packages.txt)'

# grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /mnt/etc/default/grub
arch-chroot /mnt /bin/sh -c 'grub-install /dev/vda'
arch-chroot /mnt /bin/sh -c 'grub-mkconfig -o /boot/grub/grub.cfg'

# generate new host keys
arch-chroot /mnt /bin/sh -c "ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa"
arch-chroot /mnt /bin/sh -c "ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa"
arch-chroot /mnt /bin/sh -c "ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa"
arch-chroot /mnt /bin/sh -c "ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519"

# temporal allow root login with password via ssh
# don't forget to make it more secure!
mv /mnt/etc/ssh/sshd_config /mnt/etc/ssh/sshd_config.orig
tee /mnt/etc/ssh/sshd_config <<EOF
PermitRootLogin no
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication yes
UsePAM yes
PrintMotd no
AllowUsers root ${user}
EOF

# enable required services
arch-chroot /mnt /bin/sh -c 'systemctl enable sshd.service'
arch-chroot /mnt /bin/sh -c 'systemctl enable dhcpcd.service'

# cleaup
#arch-chroot /mnt /bin/bash -c 'rm -rf /var/cache/pacman/pkg/*'
#arch-chroot /mnt /bin/bash -c 'rm -rf /var/lib/pacman/sync/*'
#arch-chroot /mnt /bin/sh -c 'dd if=/dev/zero of=/tmp/EMPTY bs=1M'
#arch-chroot /mnt /bin/sh -c 'rm -f /tmp/EMPTY'

# root passwd
arch-chroot /mnt /bin/sh -c 'echo root:CHANGEME | chpasswd'
tput smso; tput bold; echo " Temporal root password is CHANGEME "; tput rmso; tput sgr0; echo
tput smso; tput bold; echo " Do not forget to change that after first login! "; tput rmso; tput sgr0; echo

# user passwd (we cannot parse var to chroot env)
arch-chroot /mnt /bin/sh -c 'groupadd -g 1000 boonux'
arch-chroot /mnt /bin/sh -c 'useradd -m -g 1000 -u 1000 -G wheel boonux'
arch-chroot /mnt /bin/sh -c 'echo boonux ALL=(ALL:ALL) NOPASSWS:ALL > /etc/sudoers.d/boonux'
arch-chroot /mnt /bin/sh -c 'echo boonux:boonux | chpasswd'
tput smso; tput bold; echo " Temporal boonux password is booux "; tput rmso; tput sgr0; echo
tput smso; tput bold; echo " Do not forget to change that after first login! "; tput rmso; tput sgr0; echo

arch-chroot /mnt /bin/sh -c 'mkdir /home/repos'
arch-chroot /mnt /bin/sh -c 'chown -R boonux:boonux /home/repos'
arch-chroot /mnt /bin/sh -c 'sudo -u boonux git clone https://github.com/sungsit/boonux.git /home/repos/boonux'
arch-chroot /mnt /bin/sh -c 'sudo -u boonux cp -rf /home/repos/boonux/airootfs/etc/skel/.bashrc /home/boonux/.'

