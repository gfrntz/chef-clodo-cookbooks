remote_file "/tmp/one-click-installer" do
	source "http://autoinstall.plesk.com/one-click-installer"
	owner "root"
	group "root"
	mode 0700
	backup 0
end

remote_file "/tmp/PLESK-key" do
	source "http://some source"
	owner "root"
	group "root"
	mode 0700
	backup 0
end
	
execute "one-click-installer" do
	command "sh /tmp/one-click-installer"
end

directory "/var/lib/plesk-billing/tmp" do
	owner "root"
	group "root"
	mode 0755
	action :create
	recursive true
end

service "apache2" do
	action :restart
end

execute "add key" do
	command "/usr/local/psa/admin/sbin/keymng --install --source-file /tmp/PLESK-key"
end
