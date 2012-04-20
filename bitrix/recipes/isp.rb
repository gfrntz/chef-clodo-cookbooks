remote_file "/tmp/install.4.4.2.tgz" do
    source "http://download.ispsystem.com/CentOS-5/x86_64/ISPmanager-Lite/install.4.4.2.tgz"
    owner "root"
    group "root"
    mode 0700
    backup 0
end

directory "/usr/local/ispmgr" do
    action :create
    owner "root"
    group "root"
    mode 0755
end

execute "utar ispmgr" do
    command "tar -zxf /tmp/install.4.4.2.tgz -C /usr/local/ispmgr"
end

remote_file "/usr/local/ispmgr/skins/userdata/mindterm.jar" do
    source "http://ru.download.ispsystem.com/mindterm.jar"
    owner "root"
    group "root"
    mode "0644"
    backup 0
end

group "mgradmin" do
    gid 502
end

group "mgrsecure" do
    gid 503
end

ipif = node['network']['interfaces']['eth0']['addresses'].select { |address, data| data['family'] == 'inet' }[0][0]

remote_file "/usr/local/ispmgr/etc/ispmgr.lic" do
    source "http://lic.ispsystem.com/ispmgr.lic?ip=#{ipif}"
    owner "root"
    group "root"
    mode "0644"
    backup 0
end

template "/usr/local/ispmgr/etc/ispmgr.conf" do
    source "ispmgr.conf.erb"
    mode "0600"
    owner "root"
    group "root"
    variables ( :ip => "#{ipif}" )	
end

execute "set mysql rootpw" do
    command "mysqladmin -u root password #{node[:bitrix][:rootpw]}"
end

cookbook_file "/usr/local/ispmgr/etc/ispmgr.inc" do
  source "ispmgr.inc"
  mode 0444
  owner "root"
  group "root"
end

template "/usr/local/ispmgr/etc/nginx.domain" do
    source "nginx.domain.erb"
    mode "0644"
    owner "root"
    group "root"
    variables ( :ip => "#{ipif}" )
end

template "/usr/local/ispmgr/etc/nginx.inc" do
    source "nginx.inc.erb"
    mode "0644"
    owner "root"
    group "root"
    variables ( :ip => "#{ipif}" )
end

execute "pkgctl -D cache" do
    command "/usr/local/ispmgr/sbin/pkgctl -D cache"
end

%w{db4 dns fw ntp quota tar unzip zip apache nginx}.each do |pkg|
  execute "pkgctl -D activate #{pkg}" do
    command "/usr/local/ispmgr/sbin/pkgctl -D activate #{pkg}"
  end
end

execute "install exim" do
    command "/usr/local/ispmgr/sbin/mgrctl feature.edit elid=smtp version=exim sok=yes"
end

execute "install pop3" do
    command "/usr/local/ispmgr/sbin/mgrctl feature.edit elid=pop3 sok=yes"
end

execute "clear pkg cache" do
    command "/usr/local/ispmgr/sbin/pkgctl -D cache && killall ispmgr"
end
