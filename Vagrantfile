# -*- mode: ruby -*-
# vi: set ft=ruby :
#
#
require 'erb'
VAGRANT_CONFIG_API_VERSION = 2

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(VAGRANT_CONFIG_API_VERSION) do |config|

  config.ssh.config = 'ssh_config'

  config.vm.box = "centos/7"

  # empty but it gives the VM a name
  config.vm.define 'spofford' do
  end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine; these are the
  # 'standard' ports +1 to allow for coexistence with apps using those
  # ports on the host
  
  # Rails on 3001
  config.vm.network "forwarded_port", guest: 3000, host: 3001
  # Solr on 8984
  config.vm.network "forwarded_port", guest: 8983, host: 8985

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
  #
  # this ought to be teh shared folder
  config.vm.synced_folder ".", "/vagrant" , owner: 'vagrant', group: 'vagrant', type: 'virtualbox'

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider :virtualbox do |vb|
    vb.name = 'Spofford'
    # Display the VirtualBox GUI when booting the machine
    vb.gui = false
    # Customize the amount of memory on the VM:
    vb.memory = "4096"
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
CREATE DATABASE shrindex_testing WITH OWNER shrindex;
TMPL

  if not File.exist?('.vagrant_rails_env')
    require 'securerandom'
    File.open(".vagrant_rails_env", "w") do |f|
      f.write(%Q{export DB_NAME="shrindex"\n})
      f.write(%Q{export DB_USER="shrindex"\n})
      # don't set DB_HOST or DB_PASSWORD; vagrant setup uses
      # UNIX socket/ident postgres auth
      f.write(%Q{export SECRET_KEY_BASE="#{SecureRandom.hex(32)}"\n})
      f.write(%Q{# set this to production if you want less logging\n})
      f.write(%Q{export TRANSACTION_STORAGE_BASE=/home/vagrant/spofford-data\n})
      f.write(%Q{export RAILS_ENV=development\n})
    end
  end

  if not File.exist?("postgres-setup.sql") 
        password = dbpw
        b = binding
        sqlSetup = sqlTemplate.result(b)
        File.open("postgres-setup.sql", 'w') do |f|
            f.write(sqlSetup)
        end
  end

  config.vm.provision("ansible_local") do |ansible|
      ansible.compatibility_mode = '2.0'
      ansible.playbook = "ansible/playbook.yml"
      ansible.galaxy_role_file = 'ansible/requirements.yml'
      ansible.verbose = '-vvv'
  end
end
