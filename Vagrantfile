# -*- mode: ruby -*-
# vi: set ft=ruby :
#
require 'erb'
require 'fileutils'

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "centos/7"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 3000, host: 3000

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder ".", "/home/vagrant/synced"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
     vb.gui = false
  # Customize the amount of memory on the VM:
     vb.memory = "1024"
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end
  #

  if not File.exist? ".password"
        puts "Creating a .password file for the database"
        chars = '#!@$%^&*()_+-=][|<>,.;'.split("")
        dbpw = [*('a'..'z'),*('A'..'Z'),*('0'..'9'),*chars].sample(24).join
        File.open(".password","w") do |f| 
                f.write(dbpw)
        end
  else
    dbpw = IO.read(".password").strip
  end

  sqlTemplate = ERB.new <<-TMPL
CREATE USER shrindex with PASSWORD '<%= password %>';
ALTER USER shrindex CREATEDB;
CREATE DATABASE shrindex WITH OWNER shrindex;
TMPL
    

  if not File.exist?("postgres-setup.sql") 
        password = dbpw
        b = binding
        sqlSetup = sqlTemplate.result(b)
        File.open("postgres-setup.sql", 'w') do |f|
            f.write(sqlSetup)
        end
  end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
     echo "#{dbpw}" > /home/vagrant/.dbpassword
     chown vagrant.vagrant /home/vagrant/.dbpassword
     chmod 0600 /home/vagrant/.dbpassword
     yum update -y

     # enable EPEL repository (packages)
     # wget and C++ compilers to compile ruby and native gems
     # redis for sidekiq
     yum install -y epel-release git wget gcc-c++ redis

     systemctl enable redis.service
     systemctl start redis.service

     # the RPMS in this directory should be placed
     # in the rpms/directory via init.sh
     echo "Installing RPMS"
     pushd ~vagrant/synced/rpms
     rpm -Uvh *.rpm
     if [ -e scripts/chruby.sh ]; then
        install -o root -g root -m 0755 scripts/chruby.sh /etc/profile.d/chruby.sh
     fi
     popd
     if [ -d /opt/rubies ]; then
        echo "ruby already present"
     else
        echo "Installing ruby (MRI), this will take a while"
        echo "If this errors out, check /tmp/ruby-install.log on the VM"
        ruby-install ruby > /tmp/ruby-install.log
        chruby ruby
        gem install bundler
     fi

     # the next bit adds the Postgresql yum repository
     # which gives us access to more recent versions of postgres
     # then enables it as a service and starts it

     rpm -ivh https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm
     sudo yum install -y libxml2-devel libxslt-devel sqlite-devel postgresql95-server postgresql95-devel libpqxx-devel yajl vim-enhanced wget nodejs
     /usr/pgsql-9.5/bin/postgresql95-setup initdb
     cp /vagrant/postgres-setup.sql /tmp
     systemctl enable postgresql-9.5.service
     systemctl start postgresql-9.5.service
     cd /tmp
     sudo -u postgres /usr/bin/psql < /tmp/postgres-setup.sql
     export RCFILE=/home/vagrant/.bashrc
     if [ ! "$(grep chruby $RCFILE)" ]; then
        printf "\n\n# Added by provisioner\n" >> $RCFILE
        echo "chruby ruby" >> $RCFILE
     fi
     if [ ! "$(grep pgsql-9.5 $RCFILE)" ]; then
        printf "\n\n# Added by provisioner\n" >> $RCFILE
        echo "export PATH=\"\${PATH}\":/usr/pgsql-9.5/bin" >> $RCFILE
     fi
     printf "\nchruby ruby" >> /home/vagrant/.bash_profile

  SHELL

end
