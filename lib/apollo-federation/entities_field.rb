# frozen_string_literal: true

require 'graphql'
require 'apollo-federation/any'
require 'apollo-federation/entity_type_resolution_extension'
require 'apollo-federation/entity'
require 'apollo-federation/backward_compatibility'
require 'apollo-federation/errors'

module ApolloFederation
  module EntitiesField
    include ApolloFederation::BackwardCompatibility

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def define_entities_field(entity_type)
        field(:_entities, [entity_type, null: true], null: false) do
          argument :representations, [Any], required: true
          extension(EntityTypeResolutionExtension)
        end
      end
    end

    def _entities(representations:)
      representations.map do |reference|
        # TODO: Use warden or schema?
        type = context.warden.get_type(reference[:__typename])

        if type.nil? || type.kind != GraphQL::TypeKinds::OBJECT
          raise UnsupportedEntityType, reference[:__typename]
        end

        type_class = get_graphql_type(type)
        if type_class.respond_to?(:resolve_reference)
          result = type_class.resolve_reference(reference, context)
        else
          result = reference
        end

        [type, result]
      end
    end
  end
end
