Array(node[:oracle][:schemas]).each do |schema|
  oracle_database_user schema["username"] do
    password schema["password"]
    grants schema["grants"]
    action :create
  end
end
