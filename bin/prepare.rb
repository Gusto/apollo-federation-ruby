# frozen_string_literal: true

def set_version
  new_version = ARGV[0]

  contents = File.read('lib/apollo-federation/version.rb')

  new_contents = contents.gsub(/VERSION = '[0-9.]*'/, "VERSION = '#{new_version}'")
  File.write('lib/apollo-federation/version.rb', new_contents)
end

def bundle_install
  system('bundle exec appraisal install')
end

def build_gem
  system('gem build apollo-federation.gemspec')
end

set_version
bundle_install
build_gem
