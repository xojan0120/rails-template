# ----------------------------------------------------------------
# git初期化
# ----------------------------------------------------------------
git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }

# ----------------------------------------------------------------
# gem追加&置換え&インストール
# ----------------------------------------------------------------
gem 'config',                  '1.7.1'
gem 'dotenv-rails'
gem 'faker',                   '1.7.3'

gem_group :development, :test do
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

gsub_file 'Gemfile', %r(gem 'sqlite3'), "gem 'sqlite3', '~> 1.3.0'"

run "bundle install"

# ----------------------------------------------------------------
# RSpec設定
# ----------------------------------------------------------------
# 初期設定
generate "rspec:install"

# ジェネレータ設定
environment "config.generators do |g| g.test_framework :rspec, view_specs: false, helper_specs: false, routing_specs: false, controller_specs: false end"
environment "config.generators.fixture_replacement :factory_bot, dir: 'spec/factories'"
environment "config.time_zone = 'Tokyo'"

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
# dotenv設定
# ----------------------------------------------------------------
create_file ".env", <<~EOS
# Example
# VAR = 'something' # ENV['VAR'] => 'something'
EOS

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
                  .env
                  EOS
                  end

# ----------------------------------------------------------------
# template適用後
# ----------------------------------------------------------------
# gemのバンドルとbinstub生成の完了後に実行したいコールバックを登録
after_bundle do
  git add: "."
  git commit: %Q{ -m 'After template applying' }

  # 最後にspringを止めて置かないとなぜかrails consoleが立ち上がらない
  run "bin/spring stop"
end
