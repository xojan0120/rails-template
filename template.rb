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

gem_group :test do
  gem 'chromedriver-helper'
  gem 'factory_bot_rails', '~>4.10.0'
  gem 'guard', '2.13.0'
  gem 'guard-rspec', require: false
  gem 'rspec-rails', '~>3.8.0'
  gem 'spring-commands-rspec'
end

run "bundle install"

# ----------------------------------------------------------------
# RSpec設定
# ----------------------------------------------------------------
# 初期設定
generate "rspec:install"

# ジェネレータ設定
application <<-APPEND_APPLICATION
config.generators do |g|
  g.test_framework :rspec, fixtures: true, view_specs: false, helper_specs: false, routing_specs: false, request_specs: false
end
APPEND_APPLICATION

# 出力形式をドキュメント形式に変更
inject_into_file ".rspec",
                 after: "--require spec_helper\n" do
                 "--format documentation\n"
                 end

# system spec用ディレクトリ作成
empty_directory "spec/system"

# supportライブラリ用ディレクトリ作成
empty_directory "spec/support"

# spec/supportディレクトリを読み込むよう設定
# なぜか第2引数の挿入文字列の頭に\nを入れないと挿入されない。謎。
inject_into_file "spec/rails_helper.rb",
                  after: "# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }" do
                  "\nDir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }"
                  end

# Capybaraライブラリを読み込むよう設定
inject_into_file "spec/rails_helper.rb",
                  after: "# Add additional requires below this line. Rails is not loaded until this point!" do
                  "\nrequire 'capybara/rspec'"
                  end

# Capybara用設定ファイル作成
create_file "spec/support/capybara.rb", <<EOS
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
inject_into_file "spec/spec_helper.rb",
                  after: "# with RSpec, but feel free to customize to your heart's content." do
                  "\nconfig.filter_run_when_matching :focus"
                  end


# ----------------------------------------------------------------
# Guard初期設定
# ----------------------------------------------------------------
run "bin/bundle exec guard init rspec"

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
