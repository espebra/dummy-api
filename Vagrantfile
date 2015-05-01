# -*- mode: ruby -*-
# vi: set ft=ruby :

def linux config, ip, box, box_url, checksum
  config.vm.define box.to_sym do |c|
    # Give the VM a public or private IP address. PS: By default, the vagrant
    # images are not secure to expose as they allow login with known keys and 
    # passwords.
    #c.vm.network :public_network
    c.vm.network :private_network, ip: ip

    # Sync another folder
    #c.vm.synced_folder "../", "/vagrant", owner: "root", group: "root"

    # Force the VM names instead of using generated ones. May cause problems
    # if running the same VM in different vagrant projects.
    #c.vm.provider :virtualbox do |v|
    #  v.customize ['modifyvm', :id, '--name', box.to_sym]
    #end

    # Remove comments if you'd like to checksum the images
    #c.vm.box_download_checksum_type = 'md5'
    #c.vm.box_download_checksum = checksum

    c.vm.box_url = box_url
    c.vm.box = 'centos7-amd64'
    c.vm.hostname = '%s.local' % box.to_sym
    c.vm.boot_timeout = 900

    config.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/playbook.yml"
    end
  end
end

Vagrant.configure('2') do |config|
  linux config, '10.10.10.10',  'api', 'https://images.varnish-software.com/vagrant/centos-7-amd64-virtualbox.box', '53d9207739af6849b91cdc75f7b7f85c'
end
