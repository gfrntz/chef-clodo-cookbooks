%w{ ubuntu debian centos }.each do |os|
  supports os
end

default[:bitrix][:sitename] = "bitrix-test.ru"
