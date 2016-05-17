# Vultr: Archlinux Installation

- Create new instance with ipxe boot

  ~~~
  # Tokyo
  vultr server create --name="vultrarch" --region=25 --plan=29 --os=159 \
    --ipxe="https://raw.githubusercontent.com/sungsit/vultr/master/archlinux/arch64.jp.ipxe"
  ~~~

  Type `vultr regions` to see other region IDs.

  ~~~
  # New Jersey with Archlinux graphical installer
  vultr server create --name="vultrarch" --region=1 --plan=29 --os=159 \
    --ipxe="http://releng.archlinux.org/pxeboot/arch.ipxe"
  ~~~

  Note: OS ID **must be** `--os=159` (Custom ISO). **Or** login to https://my.vultr.com/ to create new instance. In **Server Type** section, choose **Custon ISO** then input **iPXE Chain URL** (`http://releng.archlinux.org/pxeboot/arch.ipxe` should be fine for all regions).

- Open Vultr console (**View Console** menu). After `archiso` successfully boot, run installation script  **inside the console**

  ~~~
  bash <(wget -qO- https://github.com/sungsit/vultr/raw/master/archlinux/install.sh)
  ~~~

- And don't forget to set new root password! (`passwd`)
