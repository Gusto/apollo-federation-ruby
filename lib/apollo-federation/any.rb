# frozen_string_literal: true

require 'graphql'
require 'apollo-federation/errors'

module ApolloFederation
  class Any < GraphQL::Schema::Scalar
    graphql_name '_Any'

    def self.coerce_input(value, _ctx)
      to_traversable_value(value).each_with_object({}) do |(key, val), result|
        result[key.to_sym] = val
      end
    end

    def self.to_traversable_value(value)
      case value
      when Hash
        value
      when GraphQL::Language::Nodes::InputObject
        value.to_h
      when ActionController::Parameters
        value.permit!.to_h
      else
        raise IncoercibleAnyTypeError, value
      end
    end
  end
end
