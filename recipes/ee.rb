#
# Cookbook Name:: oracle-database
# Recipe:: ee
#
# Install and configure Oracle DB 11R2 Enterprise edition
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

###
# Check requirements
###
raise "Installation disks must be provided! Please set 'oracle.ee.install.disks' attribute" if node[:oracle][:ee][:install][:disks].empty?

bash "check #{node[:oracle][:ee][:root_path]} > 20G" do
  code "df -P #{node[:oracle][:ee][:root_path]} | awk '/\\//{if ($2/1024/1024 < 20) exit 1}'"
end

###
# Install prerequisites
###
case node[:platform_version].to_i
when 5
  # For RedHat/CentOS 5.x we could install validated RPM
  remote_file ::File.join("/tmp", ::File.basename(node[:oracle][:ee][:oracle_validated])) do 
    source node[:oracle][:ee][:oracle_validated]
    retries 2
    action :create_if_missing
  end

  yum_package "unixODBC" do
    retries 2
  end

  yum_package ::File.join("/tmp", ::File.basename(node[:oracle][:ee][:oracle_validated])) do
    retries 2
    options "--nogpgcheck"
    action :install
  end
else
  # For other versions trying to install all packages manually
  group "oinstall"
  user "oracle" do
    gid "oinstall"
  end
  group "dba" do
    members [ "oracle" ]
  end
  package "bc"
  package "binutils"
  package "compat-gcc-34"
  package "compat-gcc-34-c++"
  package "elfutils-libelf-devel"
  package "gcc"
  package "gcc-c++"
  package "gdb"
  package "ksh"
  package "libXp"
  package "libaio-devel"
  package "compat-db42"
  package "compat-libstdc++-33"
  package "make"
  package "procps"
  package "sysstat"
  package "xorg-x11-utils"
  package "xorg-x11-xinit"
end

package "unzip"

###
# Download/unpack installer
###
directory node[:oracle][:ee][:install_dir]
directory node[:oracle][:ee][:base_dir] do
  owner "oracle"
  group "oinstall"
  action :create
end

Array(node[:oracle][:ee][:install][:disks]).each do |disk_source|
  remote_file ::File.join(node[:oracle][:ee][:install_dir], ::File.basename(disk_source)) do
    source disk_source
    retries 2
    use_conditional_get true
    use_etag true
    use_last_modified true
    action :create_if_missing
  end
  bash "unpack #{::File.basename(disk_source)}" do
    cwd node[:oracle][:ee][:install_dir]
    creates ::File.join(node[:oracle][:ee][:install_dir], ::File.basename(disk_source)+".processed")
    code <<-END
      unzip -o #{::File.join(node[:oracle][:ee][:install_dir], ::File.basename(disk_source))} && \
      touch #{::File.join(node[:oracle][:ee][:install_dir], ::File.basename(disk_source)+".processed")}
    END
    only_if { File.exists?(::File.join(node[:oracle][:ee][:install_dir], ::File.basename(disk_source))) }
    action :run
  end
end

###
# Run installer
###
# ./runInstaller -showProgress -waitforcompletion -silent -ignoreSysPrereqs -responseFile /opt/database/db_install.rsp
template ::File.join(node[:oracle][:ee][:install_dir],"db_install.rsp") do
  variables({
    :oracle_base => node[:oracle][:ee][:base_dir],
    :oracle_home => node[:oracle][:ee][:home_dir]
  })
end

bash "postInstall configuration" do
  code <<-END
    #{::File.join(node[:oracle][:ee][:base_dir], "inventory", "orainstRoot.sh")} && \
    #{::File.join(node[:oracle][:ee][:home_dir], "root.sh")}
  END
  action :nothing
end

bash "install Oracle 11R2" do
  cwd ::File.join(node[:oracle][:ee][:install_dir], "database")
  creates node[:oracle][:ee][:home_dir]
  code <<-END
    su -l oracle -c "#{::File.join(node[:oracle][:ee][:install_dir], "database", "runInstaller")}\
    -showProgress \
    -waitforcompletion \
    -silent \
    -ignoreSysPrereqs \
    -responseFile #{::File.join(node[:oracle][:ee][:install_dir], "db_install.rsp")}"
  END
  returns [0, 6]
  notifies :run, "bash[postInstall configuration]", :immediately
end

file "/etc/profile.d/oracle-db.sh" do
  mode "0755"
  content <<-END.gsub(/^[^\|]*\|/,'')
    |export ORACLE_HOME=#{node[:oracle][:ee][:home_dir]}
    |export PATH=$PATH:$ORACLE_HOME/bin
    |export ORACLE_SID=#{node[:oracle][:db][:sid]}
    |export ORACLE_USER=oracle
  END
end

###
# Install patches
###

# OCM response file
cookbook_file ::File.join(node[:oracle][:ee][:install_dir], "ocm.rsp.base64") do
  source "ocm.rsp.base64"
  action :create
end
bash "create ocm.rsp" do
  cwd node[:oracle][:ee][:install_dir]
  creates ::File.join(node[:oracle][:ee][:install_dir], "ocm.rsp")
  code "base64 -d #{::File.join(node[:oracle][:ee][:install_dir], "ocm.rsp.base64")} > #{::File.join(node[:oracle][:ee][:install_dir], "ocm.rsp")}"
end
# opatch apply -silent -ocmrf <path_to_response_file>

# Update OPatch if available
if !String(node[:oracle][:ee][:install][:opatch]).empty?
  remote_file ::File.join(node[:oracle][:ee][:install_dir], ::File.basename(node[:oracle][:ee][:install][:opatch])) do
    source node[:oracle][:ee][:install][:opatch]
    retries 2
    use_conditional_get true
    use_etag true
    use_last_modified true
    action :create_if_missing
  end
  bash "install OPatch (#{::File.basename(node[:oracle][:ee][:install][:opatch])})" do
    creates ::File.join(node[:oracle][:ee][:install_dir], ::File.basename(node[:oracle][:ee][:install][:opatch])+".processed")
    code <<-END
      rm -rf #{::File.join(node[:oracle][:ee][:home_dir], "OPatch", "*")} && \
      su -l oracle -c 'cd #{node[:oracle][:ee][:home_dir]}; unzip -o #{::File.join(node[:oracle][:ee][:install_dir], ::File.basename(node[:oracle][:ee][:install][:opatch]))}' && \
      touch #{::File.join(node[:oracle][:ee][:install_dir], ::File.basename(node[:oracle][:ee][:install][:opatch])+".processed")}
    END
    only_if { File.exists?(::File.join(node[:oracle][:ee][:install_dir], ::File.basename(node[:oracle][:ee][:install][:opatch]))) }
    action :run
  end
end

# Install Patches
Array(node[:oracle][:ee][:install][:patches]).each do |patch|
  patch_num = ::File.basename(patch).sub(/^p(\d*)_.*$/, '\1')
  remote_file ::File.join(node[:oracle][:ee][:install_dir], ::File.basename(patch)) do
    source patch
    retries 2
    use_conditional_get true
    use_etag true
    use_last_modified true
    action :create_if_missing
  end
  directory ::File.join(node[:oracle][:ee][:install_dir], "patch."+patch_num) do
    action :create
  end
  bash "extract patch: #{::File.basename(patch)}" do
    cwd ::File.join(node[:oracle][:ee][:install_dir], "patch."+patch_num)
    creates ::File.join(node[:oracle][:ee][:install_dir], ::File.basename(patch)+".processed")
    code <<-END
      unzip -o #{::File.join(node[:oracle][:ee][:install_dir], ::File.basename(patch))} && \
      touch #{::File.join(node[:oracle][:ee][:install_dir], ::File.basename(patch)+".processed")}
    END
    only_if { File.exists?(::File.join(node[:oracle][:ee][:install_dir], ::File.basename(patch))) }
    action :run
  end
  bash "install patch: #{::File.basename(patch)}" do
    cwd ::File.join(node[:oracle][:ee][:install_dir], "patch."+patch_num)
    creates ::File.join(node[:oracle][:ee][:install_dir], "patch.#{patch_num}.processed")
    code <<-END
      su -l oracle -c '$ORACLE_HOME/OPatch/opatch apply -silent -ocmrf #{::File.join(node[:oracle][:ee][:install_dir], "ocm.rsp")} #{::File.join(node[:oracle][:ee][:install_dir], "patch."+patch_num, patch_num)}' && \
      touch #{::File.join(node[:oracle][:ee][:install_dir], "patch.#{patch_num}.processed")}
    END
    only_if { File.exists?(::File.join(node[:oracle][:ee][:install_dir], "patch."+patch_num)) }
    action :run
  end
end

###
# Configure Listener
###
template ::File.join(node[:oracle][:ee][:home_dir], "network", "admin", "listener.ora") do
  variables({
    :listener_port => node[:oracle][:listener][:port]
  })
end

bash "start listener" do
  not_if "su -l oracle -c 'lsnrctl status'"
  code <<-END
    su -l oracle -c "lsnrctl start"
  END
  action :run
end

###
# Init scripts
###
template "/etc/init.d/oracle-db" do
  mode "0755"
end

service "oracle-db" do
  action :enable
end

###
# Set up firewall
###
include_recipe "simple_iptables::redhat"

simple_iptables_rule "listener" do
  chain "INPUT"
  rule "--proto tcp --dport #{node[:oracle][:listener][:port]} -m conntrack --ctstate NEW"
  jump "ACCEPT"
  weight 70
  ip_version :ipv4
end

node.set[:oracle][:home] = node[:oracle][:ee][:home_dir]
include_recipe "oracle-database::ruby"
