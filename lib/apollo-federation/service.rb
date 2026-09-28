# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  class Service < GraphQL::Schema::Object
    graphql_name '_Service'
    description 'The sdl representing the federated service capabilities. Includes federation ' \
      'directives, removes federation types, and includes rest of full schema after schema ' \
      'directives have been applied'

    # hash_key: so Next reads the { sdl: ... } Hash (see ServiceField#_service) directly.
    field(:sdl, String, null: true, hash_key: :sdl)
  end
end
