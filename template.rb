# Create .gitignore
run "gibo OSX Linux Ruby Rails Vim > .gitignore" rescue nil
gsub_file ".gitignore", /^config\/initializers\/secret_token.rb\n/, ""
gsub_file ".gitignore", /^config\/secrets.yml\n/, ""

# Gems
gem "slim-rails"
gem "draper", ">= 3.0.0.pre1"

gem_group :development do
  gem "html2slim"
end

gem_group :development, :test do
  gem "pry-coolline"
  gem "pry-rails"
  gem "pry-byebug"
  gem "pry-stack_explorer"

  gem "awesome_print"

  gem "hirb"
  gem "hirb-unicode"

  gem "spring-commands-rspec"
end

gem_group :test do
  gem "rspec-rails"
  gem "rspec-its"
  gem "factory_girl_rails"
  gem "capybara"
  gem "capybara-webkit"
end

# Install gems
run "bundle install --jobs=4"

# Convert erb to slim
run "bundle exec erb2slim -d app/views"

# Install locales
remove_file 'config/locales/en.yml'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/en.yml -P config/locales/'
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

# Add settings to config/application.rb
application do
  <<-'EOS'
I18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}").to_s]
    config.i18n.default_locale = :en

    config.generators do |g|
      g.template_engine :slim
      g.javascripts false
      g.stylesheets false
      g.helper false
      g.test_framework :rspec,
        fixture: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: false
      g.fixture_replacement :factory_girl, dir: "spec/factories"
    end

    config.autoload_paths += Dir["#{Rails.root}/app/**/concerns"]

    config.time_zone = "UTC"
  EOS
end

# Setup rspec
generate "rspec:install"

# Install .pryrc
run 'wget https://raw.githubusercontent.com/necojackarc/dotfiles/master/pryrc -O .pryrc'

# Install .rubocop.yml
run 'wget https://gist.githubusercontent.com/necojackarc/f3c8323441b1bfc0d4f4/raw/a0448624b5da1483b7839fcf88d5ba0f20f06693/.rubocop.yml'

# Setup spring
run 'bundle exec spring binstub rspec'

# Format .gitignore and Gemfile
empty_line_pattern = /^\s*\n/
comment_line_pattern = /^\s*#.*\n/

gsub_file ".gitignore", empty_line_pattern, ""
gsub_file ".gitignore", comment_line_pattern, ""
gsub_file "Gemfile", comment_line_pattern, ""

run "sort .gitignore -uo .gitignore"

# Change the extension of application.css
run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss"

# Initialize git
git :init
git add: "."
git commit: "-m 'Initial commit'"
