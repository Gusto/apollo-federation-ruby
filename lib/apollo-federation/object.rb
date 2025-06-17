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

      def policy(policies)
        add_directive(
          name: 'policy',
          arguments: [
            name: 'policies',
            values: policies,
          ],
        )
      end

      def cost(weight: 1)
        add_directive(
          name: 'cost',
          arguments: [
            name: 'weight',
            values: weight,
          ],
        )
      end

      def key(fields:, camelize: true, resolvable: true)
        arguments = [
          name: 'fields',
          values: ApolloFederation::FieldSetSerializer.serialize(fields, camelize: camelize),
        ]
        arguments.append(name: 'resolvable', values: resolvable) unless resolvable
        add_directive(
          name: 'key',
          arguments: arguments,
        )
      end

      def underscore_reference_keys(value = nil)
        if value.nil?
          if @underscore_reference_keys.nil?
            find_inherited_value(:underscore_reference_keys, false)
          else
            @underscore_reference_keys
          end
        else
          @underscore_reference_keys = value
        end
      end
    end
  end
end
