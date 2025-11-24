Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.define "monitoring-server" do |monitoring|
    monitoring.vm.hostname = "monitoring-server"
    monitoring.vm.network "public_network",
      ip: "192.168.20.40",
      netmask: "255.255.255.0",
      gateway: "192.168.20.1"

    monitoring.vm.provider "virtualbox" do |vb|
      vb.name = "monitoring-server"
      vb.memory = "2048"
      vb.cpus = 2
    end

    monitoring.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y python3 python3-pip
    SHELL
  end
end
