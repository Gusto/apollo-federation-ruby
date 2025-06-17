# frozen_string_literal: true

require 'apollo-federation/has_directives'

module ApolloFederation
  module Argument
    include HasDirectives

    VERSION_2_DIRECTIVES = %i[tags inaccessible cost].freeze

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

    def add_v2_directives(tags: [], inaccessible: nil, cost: nil, **_kwargs)
      tags.each do |tag|
        add_directive(
          name: 'tag',
          arguments: [
            name: 'name',
            values: tag[:name],
          ],
        )
      end

      add_directive(name: 'inaccessible') if inaccessible

      return unless cost

      add_directive(
        name: 'cost',
        arguments: [
          name: 'weight',
          values: cost[:weight] || 1,
        ],
      )
    end
  end
end
