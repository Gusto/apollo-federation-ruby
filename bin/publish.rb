# frozen_string_literal: true

new_version = ARGV[0]
gem_name = "apollo-federation-#{new_version}.gem"
system("gem push #{gem_name}")
File.delete(gem_name)
