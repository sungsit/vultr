#!/usr/bin/env bash

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

# sync
pacman -Syy

# partitioning
parted -s /dev/vda mklabel msdos
parted -s /dev/vda mkpart primary linux-swap 1MiB 769MiB
parted -s /dev/vda mkpart primary ext4 769MiB 100%
parted -s /dev/vda set 2 boot on
parted -s /dev/vda print
mkfs.ext4 /dev/vda2
mkswap /dev/vda1
swapon /dev/vda1

# pacstrap
mount /dev/vda2 /mnt
pacstrap /mnt base

genfstab -p /mnt > /mnt/etc/fstab
cp /etc/pacman.conf /mnt/etc/.
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/.

# basic settings
echo 'en_US.UTF-8 UTF-8' > /mnt/etc/locale.gen
echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf
echo 'vultrarch' > /mnt/etc/hostname
arch-chroot /mnt /bin/sh -c 'locale-gen'

# required packages
arch-chroot /mnt /bin/sh -c 'pacman -Syy'
arch-chroot /mnt /bin/sh -c 'pacman --noconfirm --needed -S grub openssh'

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
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication yes
UsePAM yes
PrintMotd no
AllowUsers root
EOF

# enable required services
arch-chroot /mnt /bin/sh -c 'systemctl enable sshd.service'
arch-chroot /mnt /bin/sh -c 'systemctl enable dhcpcd.service'

# cleaup
arch-chroot /mnt /bin/bash -c 'rm -rf /var/cache/pacman/pkg/*'
arch-chroot /mnt /bin/bash -c 'rm -rf /var/lib/pacman/sync/*'
arch-chroot /mnt /bin/sh -c 'dd if=/dev/zero of=/EMPTY bs=1M'
arch-chroot /mnt /bin/sh -c 'rm -f /EMPTY'

# root passwd
arch-chroot /mnt /bin/sh -c 'echo root:CHANGEME | chpasswd'
tput smso; tput bold; echo " Temporal root password is CHANGEME "; tput rmso; tput sgr0; echo
tput smso; tput bold; echo " Do not forget to change that after first login! "; tput rmso; tput sgr0; echo
