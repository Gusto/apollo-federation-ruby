# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  class Service < GraphQL::Schema::Object
    graphql_name '_Service'

    field(:sdl, String, null: true)
  end
end
