# frozen_string_literal: true

require 'apollo-federation/field_set_serializer'
require 'apollo-federation/has_directives'

module ApolloFederation
  module Object
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      include HasDirectives

      def extend_type
        add_directive(name: 'extends')
      end

      def shareable
        add_directive(name: 'shareable')
      end

      def inaccessible
        add_directive(name: 'inaccessible')
      end

      def interface_object
        add_directive(name: 'interfaceObject')
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
