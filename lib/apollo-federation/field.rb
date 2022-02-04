# frozen_string_literal: true

require 'apollo-federation/field_set_serializer'
require 'apollo-federation/has_directives'
require 'apollo-federation/directives/key'
require 'apollo-federation/directives/requires'
require 'apollo-federation/directives/external'
require 'apollo-federation/directives/provides'

module ApolloFederation
  module Field
    include HasDirectives

    def initialize(*args, external: false, requires: nil, provides: nil, **kwargs, &block)
      kwargs[:directives] ||= {}

      if external
        kwargs[:directives][ApolloFederation::Directives::External] = {}

        add_directive(name: 'external')
      end

      if requires
        kwargs[:directives][ApolloFederation::Directives::Requires] = { fields: requires[:fields] }

        add_directive(
          name: 'requires',
          arguments: [
            name: 'fields',
            values: ApolloFederation::FieldSetSerializer.serialize(requires[:fields]),
          ],
        )
      end
      if provides
        kwargs[:directives][ApolloFederation::Directives::Provides] = { fields: provides[:fields] }

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
