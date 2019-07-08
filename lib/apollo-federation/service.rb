# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  class Service < GraphQL::Schema::Object
    graphql_name '_Service'
    description 'The sdl representing the federated service capabilities. Includes federation ' \
      'directives, removes federation types, and includes rest of full schema after schema ' \
      'directives have been applied'

    field(:sdl, String, null: true)
  end
end
