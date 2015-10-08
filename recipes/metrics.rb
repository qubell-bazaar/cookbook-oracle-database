# Get metrics from database

schema_data_file = "/tmp/schema.data.txt"
cpu_data_file = "/tmp/cpu.data.txt"

file "/tmp/schema.sql" do
  owner "oracle"
  group "oinstall"
  content <<-EEND
set head off;
set newpage none;
set feedback off;
select to_char(sysdate, 'yyyy-mm-dd"T"hh24:mi:ss') as x, count(username) as users from all_users;
quit;
  EEND
end

bash "Schema number" do
  code <<-EEND
    su - oracle -c "\
      ORACLE_SID=#{node[:oracle][:db][:sid]} sqlplus -S / as sysdba @/tmp/schema.sql >> #{schema_data_file}; \
      tail -n 10 #{schema_data_file} > #{schema_data_file}.tmp; \
      mv -f #{schema_data_file}.tmp #{schema_data_file} \ 
    "
  EEND
end

bash "CPU number" do
  code <<-EEND
    case `uname -s` in
      'SunOS')
        CPU=`/bin/ps -efo "user, pcpu, pid" | awk '/oracle/{a+=$2}END{print a}'`
      ;;
      'Linux')
        CPU=`/bin/ps -eo "user pcpu pid" | awk '/oracle/{a+=$2}END{print a}'`
      ;;
    esac
    DATE=`date +%Y-%m-%dT%H:%M:%S`
    echo $DATE $CPU >> #{cpu_data_file}
    tail -n 10 #{cpu_data_file} > #{cpu_data_file}.tmp
    mv -f #{cpu_data_file}.tmp #{cpu_data_file}
  EEND
end

ruby_block "Convert schema number" do
  block do
    node.set[:oracle][:metrics][:schemas] = Hash[*(::File::readlines(schema_data_file).map {|x| x.strip.split}.insert(0, ["x", "user"]).transpose.map {|x| [x[0], x[1..-1]]}.flatten(1))]
  end
end

ruby_block "Convert CPU number" do
  block do
    node.set[:oracle][:metrics][:cpu] = Hash[*(::File::readlines(cpu_data_file).map {|x| x.strip.split}.insert(0, ["x", "cpu"]).transpose.map {|x| [x[0], x[1..-1]]}.flatten(1))]
  end
end
