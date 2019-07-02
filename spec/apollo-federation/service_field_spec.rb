# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'apollo-federation/schema'
require 'apollo-federation/field'
require 'apollo-federation/object'

RSpec.describe ApolloFederation::ServiceField do
  let(:base_schema) do
    Class.new(GraphQL::Schema) do
      include ApolloFederation::Schema
    end
  end

  let(:base_object) do
    base_field = Class.new(GraphQL::Schema::Field) do
      include ApolloFederation::Field
    end

    Class.new(GraphQL::Schema::Object) do
      include ApolloFederation::Object
      field_class base_field
    end
  end

  def execute_sdl(schema)
    schema.execute('{ _service { sdl } }')['data']['_service']['sdl']
  end

  context 'when a Query object is provided' do
    it 'adds a _service field to the Query object' do
      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :test, String, null: false
      end

      schema = Class.new(base_schema) do
        query query_obj
      end

      expect(schema.to_definition).to match_sdl(
        <<~GRAPHQL,
          type Query {
            _service: _Service!
            test: String!
          }

          type _Service {
            sdl: String
          }
        GRAPHQL
      )
    end
  end

  context 'when a Query object is not provided' do
    it 'creates a Query object with a _service field' do
      schema = Class.new(base_schema)

      expect(schema.to_definition).to match_sdl(
        <<~GRAPHQL,
          type Query {
            _service: _Service!
          }

          type _Service {
            sdl: String
          }
        GRAPHQL
      )
    end
  end

  it 'returns the federation SDL for the schema' do
    product = Class.new(base_object) do
      graphql_name 'Product'

      field :upc, String, null: false
    end

    query_obj = Class.new(base_object) do
      graphql_name 'Query'

      field :product, product, null: true
    end

    schema = Class.new(base_schema) do
      query query_obj
    end

    expect(execute_sdl(schema)).to match_sdl(
      <<~GRAPHQL,
        type Product {
          upc: String!
        }

        type Query {
          product: Product
        }
      GRAPHQL
    )
  end

  it 'returns valid SDL for type extensions' do
    product = Class.new(base_object) do
      graphql_name 'Product'
      extend_type

      field :upc, String, null: false
    end

    query_obj = Class.new(base_object) do
      graphql_name 'Query'

      field :product, product, null: true
    end

    schema = Class.new(base_schema) do
      query query_obj
    end

    expect(execute_sdl(schema)).to match_sdl(
      <<~GRAPHQL,
        type Product @extends {
          upc: String!
        }

        type Query {
          product: Product
        }
      GRAPHQL
    )
  end

  context 'when a Query object is provided' do
    it 'returns valid SDL for @key directives' do
      product = Class.new(base_object) do
        graphql_name 'Product'
        key fields: 'upc'

        field :upc, String, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :product, product, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          type Product @key(fields: "upc") {
            upc: String!
          }

          type Query {
            product: Product
          }
        GRAPHQL
      )
    end
  end

  context 'when a Query object is not provided' do
    it 'returns valid SDL for @key directives' do
      product = Class.new(base_object) do
        graphql_name 'Product'
        key fields: 'upc'

        field :upc, String, null: false
      end

      schema = Class.new(base_schema) do
        orphan_types product
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          type Product @key(fields: "upc") {
            upc: String!
          }
        GRAPHQL
      )
    end
  end

  it 'returns valid SDL for multiple @key directives' do
    product = Class.new(base_object) do
      graphql_name 'Product'
      key fields: 'upc'
      key fields: 'name'

      field :upc, String, null: false
      field :name, String, null: true
    end

    schema = Class.new(base_schema) do
      orphan_types product
    end

    expect(execute_sdl(schema)).to match_sdl(
      <<~GRAPHQL,
        type Product @key(fields: "upc") @key(fields: "name") {
          name: String
          upc: String!
        }
      GRAPHQL
    )
  end

  it 'returns valid SDL for @external directives' do
    product = Class.new(base_object) do
      graphql_name 'Product'
      extend_type
      key fields: 'upc'

      field :upc, String, null: false, external: true
      field :price, Integer, null: true
    end

    schema = Class.new(base_schema) do
      orphan_types product
    end

    expect(execute_sdl(schema)).to match_sdl(
      <<~GRAPHQL,
        type Product @extends @key(fields: "upc") {
          price: Int
          upc: String! @external
        }
      GRAPHQL
    )
  end

  it 'returns valid SDL for @provides directives' do
    product = Class.new(base_object) do
      graphql_name 'Product'
      extend_type
      key fields: 'upc'

      field :upc, String, null: false, external: true
      field :price, Integer, null: true
    end

    review = Class.new(base_object) do
      graphql_name 'Review'
      key fields: 'id'

      field :id, 'ID', null: false
      field :product, product, provides: { fields: 'upc' }, null: true
    end

    schema = Class.new(base_schema) do
      orphan_types product, review
    end

    expect(execute_sdl(schema)).to match_sdl(
      <<~GRAPHQL,
        type Product @extends @key(fields: "upc") {
          price: Int
          upc: String! @external
        }

        type Review @key(fields: "id") {
          id: ID!
          product: Product @provides(fields: "upc")
        }
      GRAPHQL
    )
  end

  it 'returns valid SDL for @requires directives' do
    product = Class.new(base_object) do
      graphql_name 'Product'
      extend_type
      key fields: 'upc'

      field :upc, String, null: false, external: true
      field :weight, Integer, null: true, external: true
      field :price, Integer, null: true, external: true
      field :shipping_estimate, Integer, null: true, requires: { fields: 'price weight' }
    end

    schema = Class.new(base_schema) do
      orphan_types product
    end

    expect(execute_sdl(schema)).to match_sdl(
      <<~GRAPHQL,
        type Product @extends @key(fields: "upc") {
          price: Int @external
          shippingEstimate: Int @requires(fields: "price weight")
          upc: String! @external
          weight: Int @external
        }
      GRAPHQL
    )
  end
end
