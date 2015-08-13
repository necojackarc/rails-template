# Create .gitignore
run "gibo OSX Linux Ruby Rails Vim > .gitignore" rescue nil
gsub_file ".gitignore", /^config\/initializers\/secret_token.rb\n/, ""
gsub_file ".gitignore", /^config\/secrets.yml\n/, ""

# Gems
gem "slim-rails"
gem "draper"
gem "kaminari"

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
        controller_specs: true
      g.fixture_replacement :factory_girl, dir: "spec/factories"
    end

    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
  EOS
end

# Setup rspec
generate "rspec:install"

# Create .pryrc
#   Reference: [necojackarc/dotfiles/pryrc](https://github.com/necojackarc/dotfiles/blob/master/pryrc)
create_file ".pryrc", <<EOS
# awesome_print
begin
  require "awesome_print"
  Pry.config.print = proc { |output, value| output.puts value.ai }
rescue LoadError
  puts "no awesome_print :("
end

# hirb
begin
  require "hirb"
rescue LoadError
  puts "no hirb :("
end

if defined? Hirb
  # Slightly dirty hack to fully support in-session Hirb.disable/enable toggling
  Hirb::View.instance_eval do
    def enable_output_method
      @output_method = true
      @old_print = Pry.config.print
      Pry.config.print = proc do |*args|
        Hirb::View.view_or_page_output(args[1]) || @old_print.call(*args)
      end
    end

    def disable_output_method
      Pry.config.print = @old_print
      @output_method = nil
    end
  end

  Hirb.enable
end
EOS

# Create .rubocop.yml
#   Reference: [necojackarc/.rubocop.yml](https://gist.github.com/necojackarc/f3c8323441b1bfc0d4f4)
create_file ".rubocop.yml", <<EOS
AllCops:
  RunRailsCops: true
  Include:
    - '**/Rakefile'
    - '**/config.ru'
  Exclude:
    - 'vendor/**/*'
    - 'bin/*'
    - 'config/**/*'
    - 'Gemfile'
    - 'db/**/*'

# Top-level documentation of clases and modules are needless
Documentation:
  Enabled: false

# Allow to chain of block after another block that spans multiple lines
MultilineBlockChain:
  Enabled: false

# Allow `->` literal for multi line blocks
Lambda:
  Enabled: false

# Both nested and compact are okay
ClassAndModuleChildren:
  Enabled: false

# Prefer Kernel#sprintf
FormatString:
  EnforcedStyle: sprintf

# Maximum line length
LineLength:
  Max: 100

# Whatever we should use "postfix if/unless"
IfUnlessModifier:
  MaxLineLength: 100

# Maximum method length
MethodLength:
  Max: 20

# Prefer double_quotes strings unless your string literal contains escape chars
StringLiterals:
  EnforcedStyle: double_quotes
EOS

# Setup spring
run 'bundle exec spring binstub rspec'

# Remove comment and empty lines
empty_line_pattern = /^\s*\n/
comment_line_pattern = /^\s*#.*\n/

gsub_file ".gitignore", comment_line_pattern, ""
gsub_file "Gemfile", comment_line_pattern, ""

# Remove files
remove_file 'README.rdoc'

# Rename files
run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss"
