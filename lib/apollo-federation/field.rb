# frozen_string_literal: true

require 'apollo-federation/field_set_serializer'
require 'apollo-federation/has_directives'

module ApolloFederation
  module Field
    include HasDirectives

    VERSION_1_DIRECTIVES = %i[external requires provides].freeze
    VERSION_2_DIRECTIVES = %i[shareable inaccessible override tag].freeze

    def initialize(*args, **kwargs, &block)
      add_v1_directives(**kwargs)
      add_v2_directives(**kwargs)

      # Remove the custom kwargs
      kwargs = kwargs.delete_if do |k, _|
        VERSION_1_DIRECTIVES.include?(k) || VERSION_2_DIRECTIVES.include?(k)
      end

      # Pass on the default args:
      super(*args, **kwargs, &block)
    end

    private

    def add_v1_directives(external: nil, requires: nil, provides: nil, **_kwargs)
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

      nil
    end

    def add_v2_directives(shareable: nil, inaccessible: nil, override: nil, tag: nil, **_kwargs)
      if shareable
        add_directive(name: 'shareable')
      end

      if inaccessible
        add_directive(name: 'inaccessible')
      end

      if override
        add_directive(
          name: 'override',
          arguments: [
            name: 'from',
            values: override[:from],
          ],
        )
      end

      if tag
        add_directive(
          name: 'tag',
          arguments: [
            name: 'name',
            values: tag[:name],
          ],
        )
      end

      nil
    end
  end
end
