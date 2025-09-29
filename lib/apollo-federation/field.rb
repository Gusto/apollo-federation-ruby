# frozen_string_literal: true

require 'apollo-federation/field_set_serializer'
require 'apollo-federation/has_directives'

module ApolloFederation
  module Field
    include HasDirectives

    VERSION_1_DIRECTIVES = %i[external requires provides].freeze
    VERSION_2_DIRECTIVES = %i[shareable inaccessible override policy tags cost list_size].freeze

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

    # We expose list_size directive so that it can be used in resolvers
    def add_list_size_directive(list_size)
      return unless list_size

      arguments = []
      if list_size.key?(:assumed_size)
        arguments << { name: 'assumedSize', values: list_size[:assumed_size] }
      end
      if (slicing_args = list_size[:slicing_arguments])
        arguments << { name: 'slicingArguments', values: slicing_args }
        if list_size.key?(:require_one_slicing_argument)
          arguments << {
            name: 'requireOneSlicingArgument',
            values: list_size[:require_one_slicing_argument],
          }
        end
      end
      if list_size[:sized_fields]
        arguments << { name: 'sizedFields', values: list_size[:sized_fields] }
      end

      add_directive(name: 'listSize', arguments: arguments) unless arguments.empty?
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

    def add_v2_directives(
      shareable: nil, inaccessible: nil, override: nil, tags: [], policy: nil, cost: nil, list_size: nil, **_kwargs
    )
      [{ flag: shareable, name: 'shareable' }, { flag: inaccessible, name: 'inaccessible' }].each do |directive|
        add_directive(name: directive[:name]) if directive[:flag]
      end

      add_override_directive(override)
      add_policy_directive(policy)
      add_cost_directive(cost)
      add_list_size_directive(list_size)

      tags.each { |tag| add_tag_directive(tag) }

      nil
    end

    def add_override_directive(override)
      return unless override

      add_directive(
        name: 'override',
        arguments: [
          name: 'from',
          values: override[:from],
        ],
      )
    end

    def add_policy_directive(policy)
      return unless policy

      add_directive(
        name: 'policy',
        arguments: [
          name: 'policies',
          values: policy[:policies],
        ],
      )
    end

    def add_cost_directive(cost)
      return unless cost

      add_directive(
        name: 'cost',
        arguments: [
          name: 'weight',
          values: cost[:weight] || 1,
        ],
      )
    end

    def add_tag_directive(tag)
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
