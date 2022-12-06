# frozen_string_literal: true

require 'apollo-federation/has_directives'

module ApolloFederation
  module EnumValue
    include HasDirectives

    VERSION_2_DIRECTIVES = %i[tag].freeze

    def initialize(*args, **kwargs, &block)
      add_v2_directives(**kwargs)

      # Remove the custom kwargs
      kwargs = kwargs.delete_if do |k, _|
        VERSION_2_DIRECTIVES.include?(k)
      end

      # Pass on the default args:
      super(*args, **kwargs, &block)
    end

    private

    def add_v2_directives(tag: nil, **_kwargs)
      return unless tag

      add_directive(
        name: 'tag',
        arguments: [
          name: 'name',
          values: tag[:name],
        ],
      )
    end
  end
end
