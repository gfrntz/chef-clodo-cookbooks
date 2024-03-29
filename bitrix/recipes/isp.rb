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

%w{db4 dns fw ntp quota tar unzip zip apache nginx mysql}.each do |pkg|
  execute "pkgctl -D activate #{pkg}" do
    command "/usr/local/ispmgr/sbin/pkgctl -D activate #{pkg}"
  end
end

ruby_block "find mysql pass" do
    block do
      begin
	      str = open('ispmgr.conf').grep(/\sPassword\ [a-zA-Z0-9]/)
	      pass = str.to_s.chomp.gsub(/^\s*Password./,"")
      rescue
	      Chef::Log.info("I have some errors in read and parse ispmgr.conf")
      end

    end
  action :create
end

ruby_block "change bitrix pass" do
    block do
      text = File.read("/home/bitrix/www/bitrix/php_interface/dbconn.php")
      replace = text.to_s.gsub(/\$DBPassword\ \= \"\"/, "\$DBPassword\ =\ \"#{pass}\"")
      File.open("dbconn.php", "w") {|file| file.puts replace}
    end
  action :create
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
