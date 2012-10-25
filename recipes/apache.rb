#
# Cookbook Name:: coldfuison10
# Recipe:: apache
#
# Copyright 2012, Nathan Mische
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Disable the default site
apache_site "000-default" do
  enable false  
end

# Add ColdFusion site
web_app "coldfusion" do
  cookbook "coldfusion10"
  template "coldfusion-site.conf.erb"
end

# Make sure CF is running
execute "start_cf_for_coldfusion10_wsconfig" do
  command "/bin/true"
  notifies :start, "service[coldfusion]", :immediately
end

# Run wsconfig 
execute "wsconfig" do
  case node['platform_family']
    when "rhel", "fedora", "arch"
      command <<-COMMAND
      #{node['cf10']['installer']['install_folder']}/cfusion/runtime/bin/wsconfig -ws Apache -dir #{node['apache']['dir']}/conf -bin #{node['apache']['binary']} -script /usr/sbin/apachectl -v
      mv #{node['apache']['dir']}/conf/httpd.conf.1 #{node['apache']['dir']}/conf/httpd.conf
      mv #{node['apache']['dir']}/conf/mod_jk.conf #{node['apache']['dir']}/conf.d/mod_jk.conf
      COMMAND
    else
      command <<-COMMAND
      #{node['cf10']['installer']['install_folder']}/cfusion/runtime/bin/wsconfig -ws Apache -dir #{node['apache']['dir']} -bin #{node['apache']['binary']} -script /usr/sbin/apache2ctl -v
      rm #{node['apache']['dir']}/httpd.conf -f
      mv #{node['apache']['dir']}/mod_jk.conf #{node['apache']['dir']}/conf.d/mod_jk.conf
      COMMAND
    end
  action :run
  not_if { File.exists?("#{node['apache']['dir']}/conf.d/mod_jk.conf") }
end

