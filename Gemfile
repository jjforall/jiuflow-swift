# Gemfile for fastlane and related tools

source "https://rubygems.org"

# Fastlane - Automate iOS and Android deployment
gem "fastlane", "~> 2.220"

# Plugins
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
