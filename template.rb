# ----------------------------------------------------------------
# gem追加&インストール
# ----------------------------------------------------------------
gem 'bootstrap-sass',          '3.3.7'
gem 'bootstrap-will_paginate', '1.0.0'
gem 'carrierwave',             '1.2.2'
gem 'config',                  '1.7.1'
gem 'high_voltage'
gem 'html2slim'
gem 'jquery-rails',            '4.3.1'
gem 'mini_magick',             '4.7.0'
gem 'slim-rails'
gem 'will_paginate',           '3.1.6'
gem 'faker',                   '1.7.3'

gem_group :development, :test do
  gem 'chromedriver-helper'
  gem 'factory_bot_rails', '~>4.10.0'
  gem 'guard', '2.13.0'
  gem 'guard-rspec', require: false
  gem 'rspec-rails', '~>3.8.0'
  gem 'spring-commands-rspec'
  gem 'hirb'
  gem 'hirb-unicode'
end

gem_group :test do
  gem 'shoulda-matchers', git: 'https://github.com/thoughtbot/shoulda-matchers.git', branch: 'rails-5'
end

run "bundle install"

# ----------------------------------------------------------------
# RSpec設定
# ----------------------------------------------------------------
# 初期設定
generate "rspec:install"

# ジェネレータ設定
environment "config.generators do |g| g.test_framework :rspec, view_specs: false, helper_specs: false, routing_specs: false, controller_specs: false end"
environment "config.generators.fixture_replacement :factory_bot, dir: 'spec/factories'"

# 出力形式をドキュメント形式に変更
inject_into_file ".rspec",
                 after: "--require spec_helper\n" do <<~EOS
                 --format documentation
                 EOS
                 end

# system spec用ディレクトリ作成
empty_directory "spec/system"

# supportライブラリ用ディレクトリ作成
empty_directory "spec/support"

# spec/supportディレクトリを読み込むよう設定
# なぜか挿入文字列の頭に\nを入れないと挿入されない。謎。
inject_into_file "spec/rails_helper.rb",
                  after: "# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }" do <<~EOS

                  Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }
                  EOS
                  end

# Capybaraライブラリを読み込むよう設定
# なぜか挿入文字列の頭に\nを入れないと挿入されない。謎。
inject_into_file "spec/rails_helper.rb",
                  after: "# Add additional requires below this line. Rails is not loaded until this point!" do <<~EOS

                  require 'capybara/rspec'
                  EOS
                  end

# Capybara用設定ファイル作成
create_file "spec/support/capybara.rb", <<~EOS
  RSpec.configure do |config|
    config.before(:each, type: :system) do
      driven_by :rack_test
    end
    config.before(:each, type: :system, js: true) do
      driven_by :selenium_chrome_headless
    end
  end
EOS

# focusタグを有効にする
# なぜか挿入文字列の頭に\nを入れないと挿入されない。謎。
inject_into_file "spec/spec_helper.rb",
                  after: "# with RSpec, but feel free to customize to your heart's content." do <<~EOS

                  config.filter_run_when_matching :focus
                  EOS
                  end

# Shoulda Matchers設定
# なぜか挿入文字列の頭に\nを入れないと挿入されない。謎。
inject_into_file "spec/rails_helper.rb",
                  after: %(  # config.filter_gems_from_backtrace("gem name")\nend\n) do <<~EOS

                  Shoulda::Matchers.configure do |config|
                    config.integrate do |with|
                      with.test_framework :rspec
                      with.library :rails
                    end
                  end
                  EOS
                  end

# 処理を待つ系のサポートモジュール作成
create_file "spec/support/wait_for_ajax.rb", <<~EOS
  module WaitForAjax
    # ajaxが完了するまで待つ
    def wait_for_ajax(wait_time = Capybara.default_max_wait_time)
      Timeout.timeout(wait_time) do
        loop until finished_all_ajax_requests?
      end
      yield
    end

    def finished_all_ajax_requests?
      page.evaluate_script('jQuery.active').zero?
    end
  end
  RSpec.configure do |config|
    config.include WaitForAjax, type: :system
  end
EOS
create_file "spec/support/wait_for_css.rb", <<~EOS
  module WaitForCss
    # cssが表示されるまで待つ
    def wait_for_css_appear(selector, wait_time = Capybara.default_max_wait_time)
      Timeout.timeout(wait_time) do
        loop until has_css?(selector)
      end
      yield
    end

    # cssが表示されなくなるまで待つ
    def wait_for_css_disappear(selector, wait_time = Capybara.default_max_wait_time)
      Timeout.timeout(wait_time) do
        loop until has_no_css?(selector)
      end
      yield
    end
  end

  RSpec.configure do |config|
    config.include WaitForCss, type: :system
  end
EOS

# ----------------------------------------------------------------
# Guard初期設定
# ----------------------------------------------------------------
run "bin/bundle exec guard init rspec"

# ----------------------------------------------------------------
# rails console設定
# ----------------------------------------------------------------
create_file ".irbrc", <<~EOS
  IRB.conf[:PROMPT_MODE] = :SIMPLE
  IRB.conf[:AUTO_INDENT_MODE] = false

  # Hirbを有効化する
  if defined? Rails::Console
    if defined? Hirb
      Hirb.enable
    end
  end
EOS

# ----------------------------------------------------------------
# jquery設定
# ----------------------------------------------------------------
application_js = "app/assets/javascripts/application.js"
inject_into_file application_js,
                 after: "//= require rails-ujs\n" do <<~EOS
                 //= require jquery
                 EOS
                 end

# ----------------------------------------------------------------
# bootstrap css設定
# ----------------------------------------------------------------
application_css  = "app/assets/stylesheets/application.css"
application_scss = "app/assets/stylesheets/application.css.scss"
File.rename(application_css, application_scss)

inject_into_file application_scss,
                 after: " */\n" do <<~EOS
                 @import "bootstrap-sprockets";
                 @import "bootstrap";
                 EOS
                 end

# ----------------------------------------------------------------
# bootstrap js設定
# ----------------------------------------------------------------
inject_into_file application_js,
                 after: "//= require jquery\n" do <<~EOS
                 //= require bootstrap
                 EOS
                 end

# ----------------------------------------------------------------
# 既存erb→slimへ変換
# ----------------------------------------------------------------
run "bin/bundle exec erb2slim -d app/views/layouts/"

# ----------------------------------------------------------------
# Config初期設定
# ----------------------------------------------------------------
generate "config:install"

# ----------------------------------------------------------------
# .gitignore設定追加
# ----------------------------------------------------------------
inject_into_file ".gitignore",
                  after: ".byebug_history\n" do <<~EOS
                  /spring/*.pid
                  *.swp
                  EOS
                  end

# ----------------------------------------------------------------
# git初期化
# ----------------------------------------------------------------
# gemのバンドルとbinstub生成の完了後に実行したいコールバックを登録
after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }

  # 最後にspringを止めて置かないとなぜかrails consoleが立ち上がらない
  run "bin/spring stop"
end
