source 'https://rubygems.org'

gem 'spree', path: '/home/botree/Mittal/Projects/Actual_Spree_3_7/spree'
# Provides basic authentication functionality for testing parts of your engine
gem 'spree_auth_devise', '~> 3.5'

gemspec

group :test, :development do
  platforms :ruby_20, :ruby_21 do
    gem 'byebug'
  end
  platforms :ruby_19 do
    gem 'debugger'
  end
end
