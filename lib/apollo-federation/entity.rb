# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  class Entity < GraphQL::Schema::Union
    graphql_name '_Entity'

    def self.resolve_type(object, context)
      context[object]
    end
  end
end
