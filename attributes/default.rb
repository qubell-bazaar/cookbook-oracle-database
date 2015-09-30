###
# Common parameters
###
default[:oracle][:listener][:port] = 1521

###
# Database parameters
###
default[:oracle][:db][:sid] = "ORCL"
default[:oracle][:db][:sys_password] = "password"
default[:oracle][:db][:system_password] = node[:oracle][:db][:sys_password]
default[:oracle][:db][:em] = "NONE" # "NONE"/"LOCAL" TODO: not used yet
default[:oracle][:db][:sysman_password] = node[:oracle][:db][:sys_password]
default[:oracle][:db][:dbsnmp_password] = node[:oracle][:db][:sys_password]

###
# Enterprise edition
###

# Installation media for Oracle DB 11R2 (1of7 and 2of7 disks at least)
default[:oracle][:ee][:install][:disks] = []
default[:oracle][:ee][:install][:opatch] = ""
default[:oracle][:ee][:install][:patches] = []
default[:oracle][:ee][:oracle_validated] = "http://public-yum.oracle.com/repo/EnterpriseLinux/EL5/5/base/x86_64/getPackage/oracle-validated-1.0.0-22.el5.x86_64.rpm"
default[:oracle][:ee][:root_path] = "/opt"
default[:oracle][:ee][:install_dir] = ::File.join(node[:oracle][:ee][:root_path], "install_files")
default[:oracle][:ee][:base_dir] = ::File.join(node[:oracle][:ee][:root_path], "oracle")
default[:oracle][:ee][:home_dir] = ::File.join(node[:oracle][:ee][:base_dir], "product", "11.2.0")

###
# User creation
###
default[:oracle][:schema][:username] = nil
default[:oracle][:schema][:password] = nil
default[:oracle][:schema][:grants] = []
default[:oracle][:schemas] = []

###
# File query
###
default[:oracle][:sql][:url] = nil
default[:oracle][:sql][:user] = "sys"
default[:oracle][:sql][:password] = node[:oracle][:db][:sys_password]

###
# DataPump
###
default[:oracle][:dp][:url] = nil
default[:oracle][:dp][:params] = nil
