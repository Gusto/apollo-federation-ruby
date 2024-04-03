# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  class Entity < GraphQL::Schema::Union
    graphql_name '_Entity'

    def self.resolve_type(object, context)
      context[object]
    end

    # The main issue here is the fact that an union in GraphQL can't be an interface according
    # to the [spec](https://spec.graphql.org/October2021/#sec-Unions.Type-Validation), but at
    # the same time, according to the Federation spec, an interface can be an Entity, and an Entity
    # is an union. Therefore, we have to extend this validation to allow interfaces as possible types.
    def self.assert_valid_union_member(type_defn)
      if type_defn.is_a?(Module) &&
         type_defn.included_modules.include?(ApolloFederation::Interface)
        # It's an interface entity, defined as a module
      else
        super(type_defn)
      end
    end
  end
end
