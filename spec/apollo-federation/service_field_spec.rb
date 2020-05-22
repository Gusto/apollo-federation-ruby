# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'apollo-federation/schema'
require 'apollo-federation/field'
require 'apollo-federation/object'
require 'apollo-federation/interface'

RSpec.describe ApolloFederation::ServiceField do
  shared_examples 'service field' do
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

            """
            The sdl representing the federated service capabilities. Includes federation
            directives, removes federation types, and includes rest of full schema after
            schema directives have been applied
            """
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

            """
            The sdl representing the federated service capabilities. Includes federation
            directives, removes federation types, and includes rest of full schema after
            schema directives have been applied
            """
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

    it 'returns valid SDL for interface types' do
      base_field = Class.new(GraphQL::Schema::Field) do
        include ApolloFederation::Field
      end

      base_interface = Module.new do
        include GraphQL::Schema::Interface
        include ApolloFederation::Interface

        # graphql_name 'Interface'
        field_class base_field
      end

      product = Module.new do
        include base_interface

        graphql_name 'Product'

        key fields: :upc
        field :upc, String, null: false
      end

      book = Class.new(base_object) do
        implements product

        graphql_name 'Book'

        extend_type

        key fields: :upc
        field :upc, String, null: false, external: true
      end

      pen = Class.new(base_object) do
        implements product

        graphql_name 'Pen'

        key fields: :upc
        field :upc, String, null: false
      end

      schema = Class.new(base_schema) do
        orphan_types book, pen
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          type Book implements Product @extends @key(fields: "upc") {
            upc: String! @external
          }

          type Pen implements Product @key(fields: "upc") {
            upc: String!
          }

          interface Product @key(fields: "upc") {
            upc: String!
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

    context 'with a filter' do
      let(:schema) do
        product = Class.new(base_object) do
          graphql_name 'Product'

          field :upc, String, null: false
        end

        query_obj = Class.new(base_object) do
          graphql_name 'Query'

          field :product, product, null: true
        end

        Class.new(base_schema) do
          query query_obj
        end
      end
      let(:filter) do
        class PermissionWhitelist
          def call(_schema_member, context)
            context[:user_role] == :admin
          end
        end

        PermissionWhitelist.new
      end
      let(:context) { { user_role: :admin } }
      let(:executed_with_context) do
        schema.execute('{ _service { sdl } }', only: filter, context: context)
      end
      let(:executed_without_context) { schema.execute('{ _service { sdl } }', only: filter) }

      it 'passes context to filters' do
        expect(executed_with_context['data']['_service']['sdl']).to match_sdl(
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

      it 'works without context' do
        expect(executed_without_context['errors']).to(
          match_array(
            [
              include('message' => "Field '_service' doesn't exist on type 'Query'"),
            ],
          ),
        )
      end

      context 'when not authorized' do
        let(:context) { { user_role: :foo } }

        it 'returns an error message' do
          expect(executed_with_context['errors']).to(
            match_array(
              [
                include('message' => "Field '_service' doesn't exist on type 'Query'"),
              ],
            ),
          )
        end
      end
    end
  end

  context 'with the original runtime' do
    it_behaves_like 'service field' do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          include ApolloFederation::Schema
        end
      end
    end
  end

  context 'with the interpreter runtime' do
    it_behaves_like 'service field' do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          use GraphQL::Execution::Interpreter
          use GraphQL::Analysis::AST

          include ApolloFederation::Schema
        end
      end
    end
  end
end
