#!/usr/bin/env bash

# change mirrors
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
tee /etc/pacman.d/mirrorlist <<EOF
Server = http://ftp.tsukuba.wide.ad.jp/Linux/archlinux/\$repo/os/\$arch
Server = http://ftp.jaist.ac.jp/pub/Linux/ArchLinux/\$repo/os/\$arch
Server = http://ftp.kddilabs.jp/Linux/packages/archlinux/\$repo/os/\$arch
Server = http://srv2.ftp.ne.jp/Linux/packages/archlinux/\$repo/os/\$arch
Server = http://ftp.nara.wide.ad.jp/pub/Linux/archlinux/\$repo/os/\$arch
Server = http://mirror.rackspace.com/archlinux/\$repo/os/\$arch
EOF

# yaourt
cp /etc/pacman.conf /etc/pacman.conf.orig
tee -a /etc/pacman.conf <<EOF

# yaourt
[archlinuxfr]
SigLevel = Optional
Server = http://repo.archlinux.fr/\$arch

EOF

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
pacstrap /mnt base base-devel
genfstab -p /mnt > /mnt/etc/fstab
cp /etc/pacman.conf /mnt/etc/.
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/.

# arch-chroot
arch-chroot /mnt /bin/sh -c 'pacman -Syyu'

# basic settings
echo 'en_US.UTF-8 UTF-8' > /mnt/etc/locale.gen
echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf
echo 'vultrarch' > /mnt/etc/hostname
arch-chroot /mnt /bin/sh -c 'locale-gen'
arch-chroot /mnt /bin/sh -c 'pacman --noconfirm -S yaourt'
arch-chroot /mnt /bin/sh -c 'yaourt --noconfirm --needed -S grub openssh git sudo nano vim zip unzip wget curl rsync'

# grub
arch-chroot /mnt /bin/sh -c 'grub-install /dev/vda'
arch-chroot /mnt /bin/sh -c 'grub-mkconfig -o /boot/grub/grub.cfg'

# generate new host keys
arch-chroot /mnt /bin/sh -c "ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa"
arch-chroot /mnt /bin/sh -c "ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa"
arch-chroot /mnt /bin/sh -c "ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa"
arch-chroot /mnt /bin/sh -c "ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519"

# enable required services
arch-chroot /mnt /bin/sh -c 'systemctl enable sshd.service'
arch-chroot /mnt /bin/sh -c 'systemctl enable dhcpcd.service'

# cleaup
arch-chroot /mnt /bin/bash -c 'rm -rf /var/cache/pacman/pkg/*'
arch-chroot /mnt /bin/bash -c 'rm -rf /var/lib/pacman/sync/*'
arch-chroot /mnt /bin/sh -c 'dd if=/dev/zero of=/EMPTY bs=1M'
arch-chroot /mnt /bin/sh -c 'rm -f /EMPTY'
