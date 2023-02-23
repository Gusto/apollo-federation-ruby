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

      expect(schema.federation_version).to eq('1.0')
    end

    it 'returns the specified version when set' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: '2.0'
      end

      expect(schema.federation_version).to eq('2.0')
    end
  end

  describe '.federation_2?' do
    it 'returns false when version is an integer less than 2.0' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: 1
      end

      expect(schema.federation_2?).to be(false)
    end

    it 'returns false when version is less than 2.0' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: '1.5'
      end

      expect(schema.federation_2?).to be(false)
    end

    it 'returns true when the version is an integer equal to 2' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: 2
      end

      expect(schema.federation_2?).to be(true)
    end

    it 'returns true when the version is a float equal to 2.0' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: 2.0
      end

      expect(schema.federation_2?).to be(true)
    end

    it 'returns true when the version is a string greater than 2.0' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: '2.0.1'
      end

      expect(schema.federation_2?).to be(true)
    end
  end

  describe '.federation_sdl' do
    let(:base_object) do
      base_field = Class.new(GraphQL::Schema::Field) do
        include ApolloFederation::Field
      end

      Class.new(GraphQL::Schema::Object) do
        include ApolloFederation::Object
        field_class base_field
      end
    end

    let(:query_type) do
      Class.new(base_object) do
        graphql_name 'Query'

        field :test, String, null: false
      end
    end

    it 'returns a federation 1 schema by default' do
      # can't use a let-defined identifier inside the below class definition?
      qt = query_type
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        query qt
      end

      expect(schema.federation_sdl).to match_sdl(
        <<~GRAPHQL,
          type Query {
            test: String!
          }
        GRAPHQL
      )
    end

    it 'returns a schema directive with the given federation version if specified' do
      qt = query_type
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        query qt
        federation version: '2.1'
      end

      expect(schema.federation_sdl).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.1", as: "federation")

          type Query {
            test: String!
          }
        GRAPHQL
      )
    end
  end
end
