#
# Create database using dbca
#

###
# Template for dbca
###
template "/tmp/dbca.rsp" do
  variables({
    :oracle_sid => node[:oracle][:db][:sid],
    :sys_password => node[:oracle][:db][:sys_password],
    :system_password => node[:oracle][:db][:system_password],
    :sysman_password => node[:oracle][:db][:sysman_password],
    :dbsnmp_password => node[:oracle][:db][:dbsnmp_password],
    :em => node[:oracle][:db][:em]
  })
end

# dbca -silent -responseFile /opt/database/dbca.rsp
bash "create database #{node[:oracle][:db][:sid]}" do
  not_if "su -l oracle -c 'test -e $ORACLE_HOME/dbs/spfile#{node[:oracle][:db][:sid]}.ora'"
  code <<-END
    su -l oracle -c "dbca -silent -responseFile /tmp/dbca.rsp"
  END
  action :run
end

bash "autostart #{node[:oracle][:db][:sid]}" do
  code <<-END
    sed -i -e 's@#{node[:oracle][:db][:sid]}:.*@#{node[:oracle][:db][:sid]}:#{node[:oracle][:ee][:home_dir]}:Y@' /etc/oratab
  END
  action :run
end
