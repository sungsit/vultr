# My Vultr installation scripts

Vultr supports [iPXE](http://ipxe.org/) network boot. So the simplest way to boot various OSes is using public mirrors, like [this one](http://boot.salstar.sk) (with checksummed binaries). There is useful client tool, see https://jamesclonk.github.io/vultr/, to create Vultr instance. An example for creating custom instance on Tokyo location

  ~~~
  vultr server create --name="CustomOS" --region=25 --plan=29 --os=159 --ipxe="http://boot.salstar.sk"
  ~~~

Then use **View Console** in https://my.vultr.com/ to see how it works.
