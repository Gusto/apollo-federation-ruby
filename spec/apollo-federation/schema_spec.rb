# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'apollo-federation/schema'

RSpec.describe ApolloFederation::Schema do
  describe '.federation_version' do
    it 'returns 1.0 by default' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
      end

      expect(schema.federation_version).to eq(1.0)
    end

    it 'returns the specified version when set' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: 2.0
      end

      expect(schema.federation_version).to eq(2.0)
    end
  end
end
