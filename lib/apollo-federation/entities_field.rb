require 'graphql'
require 'apollo-federation/any'

module ApolloFederation
  module EntitiesField
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      extend GraphQL::Schema::Member::HasFields

      def define_entities_field(entity_type)
        field(:_entities, [entity_type, null: true], null: false) do
          argument :representations, [Any], required: true
        end
      end
    end

    def _entities(representations:)
      representations.map do |reference|
        typename = reference[:__typename]
        # TODO: Use warden or schema?
        type = context.warden.get_type(typename)
        if type.nil? || type.kind != GraphQL::TypeKinds::OBJECT
          # TODO: Raise a specific error class?
          raise "The _entities resolver tried to load an entity for type \"#{typename}\", but no object type of that name was found in the schema"
        end

        # TODO: Handle non-class types?
        type_class = type.metadata[:type_class]
        result = type_class.respond_to?(:resolve_reference) ?
          type_class.resolve_reference(reference, context) :
          reference

        # TODO: This isn't 100% correct: if (for some reason) 2 different resolve_reference calls
        # return the same object, it might not have the right type
        # Right now, apollo-federation just adds a __typename property to the result,
        # but I don't really like the idea of modifying the resolved object
        context[result] = type
        # TODO: Handle lazy objects?
        result
      end
    end
  end
end
