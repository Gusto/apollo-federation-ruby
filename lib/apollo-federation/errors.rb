# frozen_string_literal: true

module ApolloFederation
  class UnsupportedEntityType < StandardError
    attr_reader :typename

    def initialize(typename)
      @typename = typename
    end

    def message
      "The _entities resolver tried to load an entity for type \"#{typename}\"," \
        ' but no object type of that name was found in the schema'
    end
  end

  class IncoercibleAnyTypeError < StandardError
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def message
      "Can't coerce value \"#{value}\" to type Any"
    end
  end
end
