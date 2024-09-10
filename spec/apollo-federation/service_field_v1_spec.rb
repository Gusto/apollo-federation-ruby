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

      it 'returns valid SDL for @key directives' do
        product = Class.new(base_object) do
          graphql_name 'Product'
          key fields: :upc

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

      it 'returns valid SDL for @key directives' do
        product = Class.new(base_object) do
          graphql_name 'Product'
          key fields: :upc

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

    it 'sets the Query as the owner to the _service field' do
      expect(
        base_schema.query
              .fields['_service']
              .owner.graphql_name,
      ).to eq('Query')
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

    it 'returns valid SDL for multiple @key directives' do
      product = Class.new(base_object) do
        graphql_name 'Product'
        key fields: :upc
        key fields: :name

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
        key fields: :upc

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
        key fields: :upc

        field :upc, String, null: false, external: true
        field :price, Integer, null: true
      end

      review = Class.new(base_object) do
        graphql_name 'Review'
        key fields: :id

        field :id, 'ID', null: false
        field :product, product, provides: { fields: :upc }, null: true
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
        key fields: :upc

        field :upc, String, null: false, external: true
        field :weight, Integer, null: true, external: true
        field :price, Integer, null: true, external: true
        field :shipping_estimate, Integer, null: true, requires: { fields: %i[price weight] }
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

    describe 'camelize option' do
      it 'camelizes by default' do
        product = Class.new(base_object) do
          graphql_name 'Product'
          key fields: :product_id

          field :product_id, String, null: false
        end

        schema = Class.new(base_schema) do
          orphan_types product
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            type Product @key(fields: "productId") {
              productId: String!
            }
          GRAPHQL
        )
      end

      it 'serializes according to camelize option otherwise' do
        product = Class.new(base_object) do
          graphql_name 'Product'
          extend_type
          key fields: :product_id, camelize: false

          field :product_id, String, null: false, camelize: false
          field :options, [String], null: false, requires: { fields: 'my_id', camelize: false }
          field :other_options, [String], null: false, requires: { fields: 'my_id', camelize: true }
        end

        schema = Class.new(base_schema) do
          orphan_types product
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            type Product @extends @key(fields: "product_id") {
              options: [String!]! @requires(fields: "my_id")
              otherOptions: [String!]! @requires(fields: "myId")
              product_id: String!
            }
          GRAPHQL
        )
      end
    end

    it 'returns SDL that honors visibility checks' do
      product = Class.new(base_object) do
        graphql_name 'Product'
        extend_type
        key fields: 'upc'
        field :upc, String, null: false, external: true
        field :secret, String, null: false, external: true do
          def self.visible?(context)
            super && context.fetch(:show_secrets, false)
          end
        end
      end

      schema = Class.new(base_schema) do
        orphan_types product
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          type Product @extends @key(fields: "upc") {
            upc: String! @external
          }
        GRAPHQL
      )
    end

    it 'returns SDL that inherits object directives' do
      base_object_with_id = Class.new(base_object) do
        key fields: 'id'

        field :id, GraphQL::Types::ID, null: false
      end

      product = Class.new(base_object_with_id) do
        graphql_name 'Product'
      end

      schema = Class.new(base_schema) do
        orphan_types product
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          type Product @key(fields: "id") {
            id: ID!
          }
        GRAPHQL
      )
    end

    it 'returns SDL that inherits the query type' do
      product = Class.new(base_object) do
        graphql_name 'Product'
        extend_type

        field :upc, String, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :product, product, null: true
      end

      new_base_schema = Class.new(base_schema) do
        query query_obj
      end

      schema = Class.new(new_base_schema)

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

    context 'with context in schema generation' do
      let(:schema) do
        product = Class.new(base_object) do
          graphql_name 'Product'

          field :upc, String, null: false

          def self.visible?(context)
            context[:show_product_type] == true
          end
        end

        query_obj = Class.new(base_object) do
          graphql_name 'Query'

          field :hello, String, null: false
          field :product, product, null: true

          def hello
            'world. What were you expecting?'
          end
        end

        Class.new(base_schema) do
          query query_obj
        end
      end

      it 'uses the context in SDL generation' do
        # Indirectly tests that the context is passed to the field
        # to run hooks such as .visible? in schema generation
        results = schema.execute('{ _service { sdl } }', context: { show_product_type: true })

        expect(results.dig('data', '_service', 'sdl')).to match_sdl(
          <<~GRAPHQL,
            type Product {
              upc: String!
            }

            type Query {
              hello: String!
              product: Product
            }
          GRAPHQL
        )
      end

      it 'generates the SDL when a context is not given' do
        # Product should not be visible without settng show_product_type: true on the context.
        results = schema.execute('{ _service { sdl } }')

        expect(results.dig('data', '_service', 'sdl')).to match_sdl(
          <<~GRAPHQL,
            type Query {
              hello: String!
            }
          GRAPHQL
        )
      end
    end
  end

  if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('1.12.0')
    context 'with older versions of GraphQL and the interpreter runtime' do
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

  if Gem::Version.new(GraphQL::VERSION) > Gem::Version.new('1.12.0')
    it_behaves_like 'service field' do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          include ApolloFederation::Schema
        end
      end
    end
  end
end
