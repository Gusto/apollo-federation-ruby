# frozen_string_literal: true

require 'apollo-federation/field_set_serializer'
require 'apollo-federation/has_directives'

module ApolloFederation
  module Field
    include HasDirectives

    def initialize(*args, external: false, requires: nil, provides: nil, shareable: nil, **kwargs, &block)
      if external
        add_directive(name: 'external')
      end
      if requires
        add_directive(
          name: 'requires',
          arguments: [
            name: 'fields',
            values: ApolloFederation::FieldSetSerializer.serialize(
              requires[:fields],
              camelize: requires.fetch(:camelize, true),
            ),
          ],
        )
      end
      if provides
        add_directive(
          name: 'provides',
          arguments: [
            name: 'fields',
            values: ApolloFederation::FieldSetSerializer.serialize(
              provides[:fields],
              camelize: provides.fetch(:camelize, true),
            ),
          ],
        )
      end
      if shareable
        add_directive(name: 'shareable')
      end

      # Pass on the default args:
      super(*args, **kwargs, &block)
    end
  end
end
