# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  module FieldSetSerializer
    extend self

    def serialize(fields, camelize: true)
      case fields
      when Hash
        fields.map do |field, nested_selections|
          "#{camelize(field, camelize)} { #{serialize(nested_selections, camelize: camelize)} }"
        end.join(' ')
      when Array
        fields.map do |field|
          serialize(field, camelize: camelize)
        end.join(' ')
      when Symbol, String
        camelize(fields, camelize)
      else
        raise ArgumentError, "Unexpected field set type: #{fields.class}"
      end
    end

    private

    def camelize(field, camelize)
      camelize ? GraphQL::Schema::Member::BuildType.camelize(field.to_s) : field.to_s
    end
  end
end
