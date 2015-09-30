use_inline_resources

action :create do
  username = String(new_resource.user)[0..29].gsub(/\./, '_')
  oracle_database_sqlplus "create user #{username}" do
    user "sys"
    password node[:oracle][:db][:sys_password]
    sid node[:oracle][:db][:sid]
    code <<-END
  declare
    var_count number(6);
  begin
    select
    count(*) into var_count
    from dba_users where username = '#{username.upcase}';
    if var_count = 0
    then
      execute immediate 'create user #{username} identified by "#{new_resource.password}" account unlock';
      execute immediate 'grant resource, create session to #{username}';
    end if;
  end;
  /
  quit;
    END
    action :run
  end
  grant_stmts = Array(new_resource.grants).map {|x| "GRANT #{x} TO #{username};"}.join("\n")
  if ! grant_stmts.empty?
    oracle_database_sqlplus "apply grants to #{username}" do
      user "sys"
      password node[:oracle][:db][:sys_password]
      sid node[:oracle][:db][:sid]
      code <<-END
      #{grant_stmts}
      quit;
      END
      action :run
    end
  end
end
