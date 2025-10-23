# frozen_string_literal: true

require 'apollo-federation/entities_field'
require 'apollo-federation/service_field'
require 'apollo-federation/entity'
require 'apollo-federation/federated_document_from_schema_definition'

module ApolloFederation
  module Schema
    def self.included(klass)
      klass.extend(CommonMethods)
    end

    module CommonMethods
      # All federation directives that can be imported from Apollo Federation specs
      FEDERATION_DIRECTIVES = %w[
        external requires provides key shareable inaccessible override policy
        cost listSize tag extends interfaceObject composeDirective
      ].freeze

      def federation(version: '1.0', default_link_namespace: nil, links: [], compose_directives: [])
        @federation_version = version
        @default_link_namespace = default_link_namespace
        @links = links
        @compose_directives = compose_directives
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
        if federation_2?
          used = document_from_schema.used_directives.to_a
          output.prepend(federation_2_prefix(used_directives: used))
        end
        output
      end

      def default_link_namespace
        @default_link_namespace || find_inherited_value(:default_link_namespace, nil)
      end

      def query(new_query_object = nil)
        return super if new_query_object.nil? && @query_object

        @orig_query_object = new_query_object
        federation_query_object = federation_query(original_query)
        federation_query_object.define_entities_field(schema_entities)

        super(federation_query_object)

        federation_query_object
      end

      def compose_directives
        @compose_directives || find_inherited_value(:compose_directives, [])
      end

      def links
        @links || find_inherited_value(:links, [])
      end

      def all_links(used_directives: [])
        # Filter used_directives to only include federation directives
        federation_used_directives = used_directives.select { |directive| FEDERATION_DIRECTIVES.include?(directive) }

        # If custom namespace is provided, don't import any directives (use prefixed versions instead)
        if default_link_namespace
          imported_directives = []
        else
          # Collect all directives that should be imported
          all_directives = federation_used_directives
          # Include @composeDirective when compose_directives are configured
          all_directives << 'composeDirective' if compose_directives.any?

          # Remove duplicates while preserving order
          imported_directives = all_directives.uniq
        end

        default_link = {
          url: "https://specs.apollo.dev/federation/v#{federation_version}",
          import: imported_directives,
        }
        default_link[:as] = default_link_namespace if default_link_namespace
        [default_link, *links]
      end

      private

      def original_query
        @orig_query_object || find_inherited_value(:original_query)
      end

      def federation_2_prefix(used_directives: [])
        schema = ['extend schema']

        all_links(used_directives: used_directives).each do |link|
          link_str = '  @link('
          link_str += "url: \"#{link[:url]}\""
          link_str += ", as: \"#{link[:as]}\"" if link[:as]
          if link[:import] && !link[:import].empty?
            imported_directives = link[:import].map { |d| "\"@#{d}\"" }.join(', ')
            link_str += ", import: [#{imported_directives}]"
          end
          link_str += ')'
          schema << link_str
        end

        compose_directives.each do |directive|
          schema << "  @composeDirective(name: \"@#{directive}\")"
        end

        schema << ''
        schema << ''

        schema.join("\n")
      end

      def schema_entities
        # Create a temporary schema that inherits from this one to extract the types
        types_schema = Class.new(self)
        # Add the original query objects to the types. We have to use orphan_types here to avoid
        # infinite recursion
        types_schema.orphan_types(original_query) if original_query

        # Walk through all of the types and determine which ones are entities (any type with a
        # "key" directive)
        types_schema.send(:non_introspection_types).values.flatten.select do |type|
          # TODO: Interfaces can have a key...
          type.include?(ApolloFederation::Object) &&
            type.federation_directives&.any? { |directive| directive[:name] == 'key' }
        end
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
    end
  end
end
