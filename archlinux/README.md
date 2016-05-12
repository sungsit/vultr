# Vultr: Archlinux Installation

- Upload Arclinux install media
- Create server instance
- Launch console to login to `archiso`
- Set temp root password for `archiso`
- Create temp sudoer with passwordless `sudo`, so you can `ssh` into the server
  Example

  - `groupadd -g 1000 noob`
  - `useradd -m -g 1000 -u 1000 noob`
  - `passwd noob`
  - `echo "noob ALL=(ALL:ALL) NOPASSWD:ALL"`

- Start `sshd`: `systemctl start sshd.service`
- Login from your machine `ssh noob@your-ip` or `vultr ssh $YOUR_SUBID`
