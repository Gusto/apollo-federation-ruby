# frozen_string_literal: true

require 'apollo-federation/entities_field'
require 'apollo-federation/service_field'
require 'apollo-federation/entity'
require 'apollo-federation/federated_document_from_schema_definition.rb'

# Random ideas:
#  - Create a temp schema inside .query and use that to extract the types
#  - Modify the query object after the fact? I doubt it would work...

module ApolloFederation
  module Schema
    def self.included(klass)
      # # TODO: Maybe make this a "use" interface?
      klass.extend(ClassMethods)
    end

    module ClassMethods
      # TODO: Hmmm. Is there a way to clear everything in the schema?
      def query(new_query_object = nil)
        if new_query_object
          super
        else
          @federation_query_object ||= begin
            # TODO: Better organize this method
            # Walk through all of the types and determine which ones are "entities"
            possible_entities = types.values.select do |type|
              !type.introspection? && type.include?(ApolloFederation::Object) &&
                type.federation_directives&.any? { |directive| directive[:name] == 'key' }
                # type.metadata[:federation_directives]&.any? { |directive| directive[:name] == 'key' }
            end

            # Build the new query object with the '_service' field
            federation_query_object = federation_query(super)

            # If there are any "entities", define the Entity union and and the Query._entities field
            if !possible_entities.empty?
              entity_type = Class.new(Entity) do
                possible_types(*possible_entities)
              end
              # TODO: Should/can we encapsulate all of this inside the module? What's the best/most Ruby
              # way to split this out?
              federation_query_object.define_entities_field(entity_type)
            end

            # TODO: Is there a way to avoid referencing the instance vars?
            @query_object = nil
            @own_types['Query'] = nil
            super(federation_query_object)

            federation_query_object
          end
        end
      end

      def federation_query(query_obj)
        if query_obj.nil?
          base = GraphQL::Schema::Object
        elsif Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.10.0')
          base = query_obj
        else
          base = query_obj.metadata[:type_class]
        end

        Class.new(base) do
          # TODO: Maybe the name should inherit from the original Query name
          # Or MAYBE we should just modify the original class?
          graphql_name 'Query'

          include EntitiesField
          include ServiceField
        end
      end

      def federation_sdl(context: nil)
        document_from_schema = FederatedDocumentFromSchemaDefinition.new(self, context: context)
        GraphQL::Language::Printer.new.print(document_from_schema.document)
      end
    end
  end
end
