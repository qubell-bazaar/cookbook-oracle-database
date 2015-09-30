raise "Username must be provided! Please set 'oracle.schema.username' attribute" if String(node[:oracle][:schema][:username]).empty?

# Oracle limits name to 30 symbols
node.set[:oracle][:schema][:username] = String(node[:oracle][:schema][:username])[0..29].gsub(/\./, '_')
if String(node[:oracle][:schema][:password]).empty?
  node.set[:oracle][:schema][:password] = [*('a'..'z'),*('0'..'9'),*('A'..'Z')].shuffle[0,10].join
end
node.set[:oracle][:schema][:password] = node[:oracle][:schema][:password]

oracle_database_sqlplus "create user #{node[:oracle][:schema][:username]}" do
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
  if var_count = 0
  then
    execute immediate 'create user #{node[:oracle][:schema][:username]} identified by "#{node[:oracle][:schema][:password]}" account unlock';
    execute immediate 'grant resource, create session to #{node[:oracle][:schema][:username]}';
  end if;
end;
/
quit;
  END
  action :run
end
Array(node[:oracle][:schema][:grants]).each do |grant|
  oracle_database_sqlplus "grant #{grant} to #{node[:oracle][:schema][:username]}" do
    user "sys"
    password node[:oracle][:db][:sys_password]
    sid node[:oracle][:db][:sid]
    code <<-END
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    WHENEVER OSERROR EXIT
    GRANT #{grant} TO #{node[:oracle][:schema][:username]};
    COMMIT;
    EXIT;
    END
    action :run
  end
end
