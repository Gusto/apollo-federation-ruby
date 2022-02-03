# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  module FieldSetSerializer
    extend self

    def serialize(fields)
      case fields
      when Hash
        fields.map do |field, nested_selections|
          "#{camelize(field)} { #{serialize(nested_selections)} }"
        end.join(' ')
      when Array
        fields.map do |field|
          serialize(field)
        end.join(' ')
      when String
        fields
      when Symbol
        camelize(fields)
      else
        raise ArgumentError, "Unexpected field set type: #{fields.class}"
      end
    end

    private

    def camelize(field)
      GraphQL::Schema::Member::BuildType.camelize(field.to_s)
    end
  end
end
