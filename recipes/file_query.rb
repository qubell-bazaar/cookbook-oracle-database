#
# Run file specified by URL
#

Array(node[:oracle][:sql][:url]).each do |url|
  oracle_database_sqlplus url do
    user node[:oracle][:sql][:username]
    password node[:oracle][:sql][:password]
    sid node[:oracle][:db][:sid]
    source url
    action :run
  end
end
