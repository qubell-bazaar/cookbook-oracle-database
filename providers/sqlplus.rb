use_inline_resources

action :run do
  opts = ""
  if String(new_resource.user).upcase == "SYS"
    opts = "as sysdba"
  end
  tmp_path = "/tmp/sqlplus-script.sql"
  temp_file = ::File.open(tmp_path, "w")
  if !String(new_resource.source).empty?
    temp_file.close
    remote_file tmp_path do
      owner "oracle"
      source new_resource.source
      retries 2
      backup false
    end
  elsif !String(new_resource.code).empty?
    temp_file.puts(new_resource.code)
    temp_file.close
  end
  bash "run sqlplus[#{new_resource.name}]" do
    code <<-END
      runuser -l oracle -c "\
      sqlplus #{new_resource.user}/#{new_resource.password}@#{new_resource.sid} #{opts} @#{tmp_path} \
      &> /tmp/sqlplus.log"
    END
  end
#  converge_by(nil) do
#    temp_file && temp_file.close!
#  end
end
