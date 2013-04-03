source "https://rubygems.org"

gem "rails", "~> 3.2.13"
gem "jquery-rails"
gem "haml-rails"
gem "coderay"
gem "http_status_exceptions", "~> 0.3.0"

# Used as a REST client to access the API
gem "chef", "~> 11.4.0"

group(:development) do
  gem 'thin'
end

group(:production) do
  gem "unicorn", "~> 2.0.0"
  gem "therubyracer"
  gem "uglifier"
end
