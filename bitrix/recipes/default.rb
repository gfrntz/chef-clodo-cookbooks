remote_file "/tmp/bitrix-env.sh" do
  source "http://mirror.clodo.ru/repos.1c-bitrix.ru/yum/bitrix-env.sh"
  owner "root"
  group "root"
  mode 0700
  backup 0
end

remote_file "/tmp/install.sh" do
  source "http://download.ispsystem.com/install.sh"
  owner "root"
  group "root"
  mode 0700
  backup 0
end

execute "bitrix" do
  command "/tmp/bitrix-env.sh"
end

execute "firewall" do
  command "/usr/bin/system-config-securitylevel-tui -q --enabled --port=80:tcp --port=443:tcp --port=10082:tcp --port=5222:tcp --port=5223:tcp --port=25:tcp"
end

execute "performance" do
  command "sed 's|zend_datacache.enable=0|zend_datacache.enable=1|g' -i /usr/local/zend/etc/conf.d/datacache.ini"
end

execute "memcached param" do
  command "sed 's|OPTIONS=\"\"|OPTIONS=\"-a 0777 -s /var/run/memcached/memcached.sock\"|g' -i /etc/sysconfig/memcached"
end

execute "change node host" do
  command "rm -f /etc/nginx/bx/node_host.conf"
end

template "/etc/nginx/bx/node_host.conf" do
  source "node_host.conf.erb"
  mode 0644
  owner "root"
  group "root"
end

template "/etc/nginx/bx/site_avaliable/s1.conf" do
   source "s1.conf.erb"
   mode 0644
   owner "root"
   group "root"
   variables ( :ip => node['network']['interfaces']['eth0']['addresses'].select { |address, data| data['family']=='inet' }[0][0] ) 
end

%w{nginx httpd zend-server}.each do |srv|
  service "#{srv}" do
    action :restart
  end
end
