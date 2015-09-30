#
# Install Ruby Oracle driver
#
ENV["ORACLE_HOME"] = node[:oracle][:home]
gem_package "ruby-oci8" do
  action :install
end
