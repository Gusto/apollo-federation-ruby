require 'graphql'

# TODO: Should this and Any be in their own files or just in-line with EntitiesField?
module ApolloFederation
  class Entity < GraphQL::Schema::Union
    graphql_name '_Entity'

    def self.resolve_type(object, context)
      context[object]
    end
  end
end
