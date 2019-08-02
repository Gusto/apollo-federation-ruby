# frozen_string_literal: true

# TODO: Rewrite in bash?
new_version = ARGV[0]
gem_name = "apollo-federation-#{new_version}.gem"
puts("gem push #{gem_name}")
File.delete(gem_name)
# system("gem push apollo-federation-#{new_version}.gem")
# puts('{}')
