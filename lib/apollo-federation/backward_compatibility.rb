# frozen_string_literal: true

module ApolloFederation
  module BackwardCompatibility
    # @return [GraphQL::Schema::Member]
    def get_graphql_type(type)
      if type.respond_to?(:metadata)
        type.metadata[:type_class]
      else
        type
      end
    end

    # @return [Hash]
    def get_graphql_type_metadata(type)
      if type.respond_to?(:metadata)
        type.metadata
      else
        type.to_graphql.metadata
      end
    end
  end
end
