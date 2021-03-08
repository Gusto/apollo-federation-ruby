# frozen_string_literal: true

require 'apollo-federation/field_set_serializer'
require 'apollo-federation/has_directives'

module ApolloFederation
  module Field
    include HasDirectives

    def initialize(*args, external: false, requires: nil, provides: nil, **kwargs, &block)
      if external
        add_directive(name: 'external')
      end
      if requires
        add_directive(
          name: 'requires',
          arguments: [
            name: 'fields',
            values: ApolloFederation::FieldSetSerializer.serialize(requires[:fields]),
          ],
        )
      end
      if provides
        add_directive(
          name: 'provides',
          arguments: [
            name: 'fields',
            values: ApolloFederation::FieldSetSerializer.serialize(provides[:fields]),
          ],
        )
      end

      # Pass on the default args:
      super(*args, **kwargs, &block)
    end
  end
end
