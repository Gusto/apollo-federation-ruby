# frozen_string_literal: true

require 'graphql'
require 'apollo-federation/interface'

module ApolloFederation
  class Entity < GraphQL::Schema::Union
    graphql_name '_Entity'

    def self.resolve_type(object, context)
      context[object]
    end

    # GraphQL only allows object types as union members
    # (https://spec.graphql.org/October2021/#sec-Unions.Type-Validation), but a federation
    # entity interface has to be a member of the _Entity union for the router to resolve it
    # through Query._entities. Let federation interfaces through the validation.
    def self.assert_valid_union_member(type_defn)
      return if type_defn.is_a?(Module) && type_defn.included_modules.include?(ApolloFederation::Interface)

      super(type_defn)
    end
  end
end
