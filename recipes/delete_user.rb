raise "Username must be provided! Please set 'oracle.schema.username' attribute" if String(node[:oracle][:schema][:username]).empty?

oracle_database_sqlplus "delete user #{node[:oracle][:schema][:username]}" do
  user "sys"
  password node[:oracle][:db][:sys_password]
  sid node[:oracle][:db][:sid]
  code <<-END
declare
  var_count number(6);
begin
  select
  count(*) into var_count
  from dba_users where username = '#{node[:oracle][:schema][:username].upcase}';
  if var_count = 1
  then
    execute immediate 'drop user #{node[:oracle][:schema][:username]} cascade';
  end if;
end;
/
quit;
  END
  action :run
end
