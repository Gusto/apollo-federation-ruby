# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  class Any < GraphQL::Schema::Scalar
    graphql_name '_Any'

    def self.coerce_input(value, _ctx)
      # TODO: Should we convert it to a Mash-like object?
      result = {}

      # `value` can be an ActionController::Parameters instance
      hash_like_value(value).each_pair do |key, val|
        result[key.to_sym] = val
      end

      result
    end

    def self.hash_like_value(value)
      case value
      when GraphQL::Language::Nodes::InputObject
        value.to_h
      else
        value
      end
    end

    private_class_method :hash_like_value
  end
end
