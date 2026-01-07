# frozen_string_literal: true

require 'apollo-federation/entities_field'
require 'apollo-federation/service_field'
require 'apollo-federation/entity'
require 'apollo-federation/federated_document_from_schema_definition.rb'

module ApolloFederation
  module Schema
    IMPORTED_DIRECTIVES = ['inaccessible', 'tag'].freeze

    def self.included(klass)
      klass.extend(CommonMethods)
    end

    module CommonMethods
      DEFAULT_LINK_NAMESPACE = 'federation'

      def federation(version: '1.0', link: {})
        @federation_version = version
        @link = { as: DEFAULT_LINK_NAMESPACE }.merge(link)
      end

      def federation_version
        @federation_version || find_inherited_value(:federation_version, '1.0')
      end

      def federation_2?
        Gem::Version.new(federation_version.to_s) >= Gem::Version.new('2.0.0')
      end

      def federation_sdl(context: nil)
        document_from_schema = FederatedDocumentFromSchemaDefinition.new(self, context: context)

        output = GraphQL::Language::Printer.new.print(document_from_schema.document)
        output.prepend(federation_2_prefix) if federation_2?
        output
      end

      def link_namespace
        @link ? @link[:as] : find_inherited_value(:link_namespace)
      end

      def query(new_query_object = nil)
        return super if new_query_object.nil? && @query_object

        @orig_query_object = new_query_object
        federation_query_object = federation_query(original_query)
        federation_query_object.define_entities_field(schema_entities)

        super(federation_query_object)

        federation_query_object
      end

      private

      def original_query
        @orig_query_object || find_inherited_value(:original_query)
      end

      def federation_2_prefix
        federation_namespace = ", as: \"#{link_namespace}\"" if link_namespace != DEFAULT_LINK_NAMESPACE

        <<~SCHEMA
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3"#{federation_namespace}, import: [#{(IMPORTED_DIRECTIVES.map { |directive| "\"@#{directive}\"" }).join(', ')}])

        SCHEMA
      end

      def schema_entities
        # Create a temporary schema that inherits from this one to extract the types
        types_schema = Class.new(self)
        # Add the original query objects to the types. We have to use orphan_types here to avoid
        # infinite recursion
        types_schema.orphan_types(original_query)

        entities_collection, federation_entities, interface_types_map = collect_entitites(types_schema)

        if federation_entities.any?
          entity_names = entities_collection.map(&:graphql_name)

          federation_entities.each do |interface|
            members = interface_types_map.fetch(interface.graphql_name, [])
            not_entity_members = members.reject { |member| entity_names.include?(member) }

            # If all interface members are entities, it is valid so we add it to the collection
            if not_entity_members.empty?
              entities_collection << interface
            else
              raise "Interface #{interface.graphql_name} is not valid. " \
                "Types `#{not_entity_members.join(', ')}` do not have a @key directive. " \
                'All types that implement an interface with a @key directive must also have a @key directive.'
            end
          end
        end

        entities_collection
      end

      # Walk through all of the types and interfaces and determine which ones are entities
      # (any type with a "key" directive)
      # However, for interface entities, don't add them straight away, but first check that
      # all implementing types of the interfaces are also entities.
      def collect_entitites(types_schema)
        federation_entities = []
        interface_types_map = {}

        entities_collection = types_schema.send(:non_introspection_types).values.flatten.select do |type|
          # keep track of the interfaces -> type relations.
          if type.respond_to?(:implements)
            type.implements.each do |interface|
              interface_types_map[interface.abstract_type.graphql_name] ||= []
              interface_types_map[interface.abstract_type.graphql_name] << type.graphql_name
            end
          end

          # Only add Type entities to the collection
          # Interface entities will be added later if all implementing types are entities
          if type.include?(ApolloFederation::Object) && includes_key_directive?(type)
            true
          elsif type.include?(ApolloFederation::Interface) && includes_key_directive?(type)
            federation_entities << type
            false
          else
            false
          end
        end

        [entities_collection, federation_entities, interface_types_map]
      end

      def federation_query(query_obj)
        # Build the new query object with the '_service' field
        if query_obj.nil?
          base = GraphQL::Schema::Object
        elsif Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.10.0')
          base = query_obj
        else
          base = query_obj.metadata[:type_class]
        end

        klass = Class.new(base) do
          # TODO: Maybe the name should inherit from the original Query name
          # Or MAYBE we should just modify the original class?
          graphql_name 'Query'

          include EntitiesField
          include ServiceField
        end

        klass.define_service_field
        klass
      end

      def includes_key_directive?(type)
        type.federation_directives&.any? { |directive| directive[:name] == 'key' }
      end
    end
  end
end
