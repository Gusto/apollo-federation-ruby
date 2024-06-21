# frozen_string_literal: true

require 'apollo-federation/field_set_serializer'
require 'apollo-federation/has_directives'

module ApolloFederation
  module Interface
    def self.included(klass)
      klass.definition_methods do
        include DefinitionMethods
      end
    end

    module DefinitionMethods
      include HasDirectives

      def extend_type
        add_directive(name: 'extends')
      end

      def inaccessible
        add_directive(name: 'inaccessible')
      end

      def authenticated
        add_directive(name: 'authenticated')
      end

      def requires_scopes(scopes)
        add_directive(name: 'tag', arguments: [name: 'scopes', values: scopes])
      end

      def tag(name:)
        add_directive(name: 'tag', arguments: [name: 'name', values: name])
      end

      def key(fields:, camelize: true)
        add_directive(
          name: 'key',
          arguments: [
            name: 'fields',
            values: ApolloFederation::FieldSetSerializer.serialize(fields, camelize: camelize),
          ],
        )
      end
    end
  end
end
