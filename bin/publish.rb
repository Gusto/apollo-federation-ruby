# frozen_string_literal: true

# TODO: Rewrite in bash?
new_version = ARGV[0]
puts("gem push apollo-federation-#{new_version}.gem")
# system("gem push apollo-federation-#{new_version}.gem")
# puts('{}')
