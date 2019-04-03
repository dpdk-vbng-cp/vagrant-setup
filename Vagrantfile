# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'json'

ENV['OVS_BRIDGE'] ||= 'ovs-br0'

Vagrant.configure('2') do |config|
  config.vm.provider :libvirt do |libvirt|
    libvirt.storage_pool_name = 'images'
  end

  config.trigger.before :up, :destroy, :halt, :provision, :reload, :resume, :suspend,
                        only_on: :accel1 do |trigger|
    trigger.info = "Cleaning up bridge environment #{ENV['OVS_BRIDGE']} on host"
    trigger.run = { path: './scripts/ovs-bridge.sh',
                    args: 'delete'}
  end

  config.trigger.before :up, :resume, :reload, :provision, only_on: :accel1 do |trigger|
    trigger.info = "Creating bridge environment #{ENV['OVS_BRIDGE']} on host"
    trigger.run = { path: './scripts/ovs-bridge.sh',
                    args: 'create'}
  end

  [
     { name: :accel1,
       mac: '00:00:00:00:00:a1'},
     { name: :accel2,
       mac: '00:00:00:00:00:b1'}
  ].each do |vm|
    config.vm.define vm[:name] do |vm_conf|
      vm_conf.vm.box = 'generic/ubuntu1604'
      vm_conf.vm.hostname = "vbng-ctl.#{vm['name']}.vbras"

      vm_conf.vm.network :public_network,
        auto_config: false,
        dev: ENV['OVS_BRIDGE'],
        type: 'bridge',
        mac: vm[:mac],
        ovs: true

      vm_conf.vm.synced_folder 'salt/srv/', '/srv/'

      vm_conf.vm.provision :salt do |salt|
        salt.minion_key = "salt/key/minion.pem"
        salt.minion_pub = "salt/key/minion.pub"
        salt.minion_json_config = {
          :master => 'localhost',
          :grains => { :roles => ['vbng-control'] }
        }.to_json

        salt.install_master = true
        salt.master_key = "salt/key/master.pem"
        salt.master_pub = "salt/key/master.pub"
        salt.master_json_config = {
          :file_roots => { :base => ['/srv/salt'] },
	  :pillar_roots => { :base => ['/srv/pillar'] }
	}.to_json
        salt.seed_master = {"vbng-ctl.#{vm['name']}.vbras" => salt.minion_pub}
        salt.run_highstate = true
      end
    end
  end
end
