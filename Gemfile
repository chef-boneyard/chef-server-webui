source :rubygems

gem "rails", "~> 3.2.11"
gem "jquery-rails"
gem "haml-rails"
gem "coderay"
gem "http_status_exceptions", "~> 0.3.0"


gem "chef", :git => "git://github.com/opscode/chef.git", :branch => "master", :require => false

group(:development) do
  gem 'thin'
end

group(:production) do
  gem "unicorn", "~> 2.0.0"
  gem "therubyracer"
  gem "uglifier"
end
