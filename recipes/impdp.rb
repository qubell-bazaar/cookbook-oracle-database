raise "Dump file must be provided! Please set 'oracle.dp.url' attribute" if String(node[:oracle][:dp][:url]).empty?

dp_filename = ::File.basename(node[:oracle][:dp][:url])
dp_path = ::File.join(node[:oracle][:ee][:base_dir], "admin", node[:oracle][:db][:sid], "dpdump")

remote_file ::File.join(dp_path, dp_filename) do
  source node[:oracle][:dp][:url]
  retries 2
end

execute "decompress #{dp_filename}" do
  command "gunzip -f #{::File.join(dp_path, dp_filename)}"
  only_if { dp_filename.end_with? ".gz" }
end

bash "run impdp #{dp_filename.gsub(/\.gz$/, "")}" do
  code <<-END
    runuser -l oracle -c "\
      ORACLE_SID=#{node[:oracle][:db][:sid]} \
      impdp system/#{node[:oracle][:db][:system_password]} \
      dumpfile=#{dp_filename.gsub(/\.gz$/, "")} #{String(node[:oracle][:dp][:params])} \
    "
  END
  returns [0, 5]
end

