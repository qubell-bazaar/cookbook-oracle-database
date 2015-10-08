raise "Username must be provided! Please set 'oracle.schema.username' attribute" if String(node[:oracle][:schema][:username]).empty?

oracle_database_sqlplus "delete user #{node[:oracle][:schema][:username]}" do
  user "sys"
  password node[:oracle][:db][:sys_password]
  sid node[:oracle][:db][:sid]
  code <<-END
DECLARE
   lc_username   VARCHAR2 (32) := '#{node[:oracle][:schema][:username].upcase}';
BEGIN
   FOR ln_cur IN (SELECT sid, serial# FROM v$session WHERE username = lc_username)
   LOOP
      EXECUTE IMMEDIATE ('ALTER SYSTEM KILL SESSION ''' || ln_cur.sid || ',' || ln_cur.serial# || ''' IMMEDIATE');
   END LOOP;
END;
/
DECLARE
  var_count NUMBER(6);
BEGIN
  SELECT
  COUNT(*) INTO var_count
  FROM dba_users WHERE username = '#{node[:oracle][:schema][:username].upcase}';
  IF var_count = 1
  THEN
    EXECUTE IMMEDIATE 'DROP USER #{node[:oracle][:schema][:username]} CASCADE';
  END IF;
END;
/
QUIT;
  END
  action :run
end
