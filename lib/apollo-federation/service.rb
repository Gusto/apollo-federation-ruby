require 'graphql'

# TODO: Should this and Any be in their own files or just in-line with EntitiesField?
module ApolloFederation
  class Service < GraphQL::Schema::Object
    graphql_name '_Service'

    field(:sdl, String, null: true)
  end
end
