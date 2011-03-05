#########
# Rails template for Viget Labs
#
# Some code taken from http://github.com/relevance/new-world-order/blob/master/template.rb
#########

# Setup constants
USING_19 = RUBY_VERSION =~ /1\.9/

# Add a .rvmrc
if File.exist?(File.expand_path("~/.rvm/bin/rvm-prompt"))
  file ".rvmrc", "rvm use #{`~/.rvm/bin/rvm-prompt i v g`}"
end

# Remove default files
%W[Gemfile README doc/README_FOR_APP public/index.html public/images/rails.png].each do |path|
  run "rm #{path}"
end

# Create Gemfile and run bundle install
file 'Gemfile', <<-CODE
source "http://rubygems.org"

CODE

gem "rails", "3.0.3"

unless options[:skip_activerecord]
  if require_for_database
    gem gem_for_database, :require => require_for_database
  else
    gem gem_for_database
  end
end

gem "jquery-rails"
gem "rails3-generators"
gem 'simple_form'

gem "unicorn", :group => ["development", "test"]
gem "shoulda", :group => "test"
gem "factory_girl_rails", :group => "test"
gem "mocha", :group => "test"
gem "capybara", :group => "test"
gem "database_cleaner", :group => "test"
gem "cucumber", :group => "test"
gem "cucumber-rails", :group => "test"
if USING_19
  gem "simplecov", :group => "test"
else
  gem "rcov", :group => "test", :require => false
end

run "bundle install 1>&2"

# Setup replacement generators
application %Q{
  config.generators do |g|
    g.test_framework :shoulda, :fixture_replacement => :factory_girl
  end
}

# Setup database
# Rails default generator uses 'app_name' as the username for postgresql -- that is dumb
# We replace that with 'postgres' which is a more common development configuration
if options[:database] == "postgresql"
  gsub_file 'config/database.yml', "username: #{app_name}", "username: postgres"
end

rake "db:create:all db:migrate"

# Setup tests
if USING_19
  inject_into_file "test/test_helper.rb", "require 'simplecov'\nSimpleCov.start 'rails'\n", :after => "require 'rails/test_help'\n"
else
  file "lib/tasks/rcov.rake", %q{
require 'rcov/rcovtask'

Rcov::RcovTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/unit/**/*.rb', 'test/functional/**/*.rb', 'test/integration/**/*.rb']
  t.rcov_opts = ['--rails', "--text-summary", "--exclude 'test,config,gems'"]
  t.verbose = true
end

task :default => :rcov
}
end

# Initialize cucumber
generate "cucumber:install", "--testunit", "--capybara"
gsub_file "lib/tasks/cucumber.rake", /^\s*task :default => :cucumber\s*$/, ""

# Remove Prototype defaults and replace them with jQuery
%w(controls.js dragdrop.js effects.js prototype.js).each do |js|
  remove_file "public/javascripts/#{js}"
end

run "curl http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js -o public/javascripts/jquery.min.js"
run "curl http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.js -o public/javascripts/jquery.js"
run "curl https://github.com/rails/jquery-ujs/raw/master/src/rails.js -o public/javascripts/rails.js"

# More generators
generate "simple_form:install"

# Setup CSS skeleton
get "https://github.com/paulirish/html5-boilerplate/raw/master/css/style.css", "public/stylesheets/screen.css"

# Add default README
file 'README.markdown', <<-EOL
# Welcome to #{app_name}

## Summary

#{app_name} is a .... TODO high level summary of app

## Getting Started

    gem install bundler
    # TODO other setup commands here
    
## Seed Data

Login as ....  # TODO insert typical test accounts for QA / devs to login to app as
EOL

# Initialize Git
git :init
append_file '.gitignore', "vendor/bundler_gems\nconfig/database.yml\n"
run "cp config/database.yml config/database.example.yml"
git :add => "."
git :commit => "-a -m 'Initial commit'"
