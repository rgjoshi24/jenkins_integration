#Install Apache2 as a web application for example.

package 'apache2' do
    action :install
  end
  
  file '/var/www/html/index.html' do
    action :create
    content 'Jenkin Pipeline!!!'
  end
  
  service 'apache2' do
    action [:enable, :start ]
  end