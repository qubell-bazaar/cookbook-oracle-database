#
# Run Query specified by code
#

Array(node[:oracle][:sql][:code]).each_with_index do |sql, i|
  oracle_database_sqlplus "run query #{i}" do
    user node[:oracle][:sql][:username]
    password node[:oracle][:sql][:password]
    sid node[:oracle][:db][:sid]
    code <<-EEND
WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT
#{sql}
COMMIT;
EXIT;
    EEND
    action :run
  end
end
