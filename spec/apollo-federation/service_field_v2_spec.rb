# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'apollo-federation/schema'
require 'apollo-federation/field'
require 'apollo-federation/object'
require 'apollo-federation/interface'
require 'apollo-federation/union'
require 'apollo-federation/enum'
require 'apollo-federation/enum_value'
require 'apollo-federation/scalar'
require 'apollo-federation/input_object'
require 'apollo-federation/argument'

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
          federation version: '2.0'
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

            type Product @federation__key(fields: "upc") {
              upc: String!
            }

            type Query {
              product: Product
            }
          GRAPHQL
        )
      end

      it 'adds a _service field to the Query object' do
        query_obj = Class.new(base_object) do
          graphql_name 'Query'

          field :test, String, null: false
        end

        schema = Class.new(base_schema) do
          query query_obj
          federation version: '2.0'
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

      it 'returns valid SDL for @key directives' do
        product = Class.new(base_object) do
          graphql_name 'Product'
          key fields: :upc

          field :upc, String, null: false
        end

        schema = Class.new(base_schema) do
          orphan_types product
          federation version: '2.0'
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

            type Product @federation__key(fields: "upc") {
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
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

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
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__extends {
            upc: String!
          }

          type Query {
            product: Product
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for shareable types' do
      position = Class.new(base_object) do
        graphql_name 'Position'
        shareable

        field :x, Integer, null: false
        field :y, Integer, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :position, position, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Position @federation__shareable {
            x: Int!
            y: Int!
          }

          type Query {
            position: Position
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for inaccessible types' do
      position = Class.new(base_object) do
        graphql_name 'Position'
        inaccessible

        field :x, Integer, null: false
        field :y, Integer, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :position, position, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Position @inaccessible {
            x: Int!
            y: Int!
          }

          type Query {
            position: Position
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for tagged types' do
      position = Class.new(base_object) do
        graphql_name 'Position'
        tag name: 'private'

        field :x, Integer, null: false
        field :y, Integer, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :position, position, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Position @tag(name: "private") {
            x: Int!
            y: Int!
          }

          type Query {
            position: Position
          }
        GRAPHQL
      )
    end

    context 'with a custom link namespace provided' do
      it 'returns valid SDL for type extensions with custom namespace' do
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
          federation version: '2.0', link: { as: 'fed2' }
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", as: "fed2", import: ["@inaccessible", "@tag"])

            type Product @fed2__extends {
              upc: String!
            }

            type Query {
              product: Product
            }
          GRAPHQL
        )
      end

      it 'returns valid SDL for shareable types with custom namespace' do
        position = Class.new(base_object) do
          graphql_name 'Position'
          shareable

          field :x, Integer, null: false
          field :y, Integer, null: false
        end

        query_obj = Class.new(base_object) do
          graphql_name 'Query'

          field :position, position, null: true
        end

        schema = Class.new(base_schema) do
          query query_obj
          federation version: '2.0', link: { as: 'fed2' }
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", as: "fed2", import: ["@inaccessible", "@tag"])

            type Position @fed2__shareable {
              x: Int!
              y: Int!
            }

            type Query {
              position: Position
            }
          GRAPHQL
        )
      end

      it 'returns valid SDL for inaccessible types with custom namespace' do
        position = Class.new(base_object) do
          graphql_name 'Position'
          inaccessible

          field :x, Integer, null: false
          field :y, Integer, null: false
        end

        query_obj = Class.new(base_object) do
          graphql_name 'Query'

          field :position, position, null: true
        end

        schema = Class.new(base_schema) do
          query query_obj
          federation version: '2.0', link: { as: 'fed2' }
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", as: "fed2", import: ["@inaccessible", "@tag"])

            type Position @inaccessible {
              x: Int!
              y: Int!
            }

            type Query {
              position: Position
            }
          GRAPHQL
        )
      end

      it 'returns valid SDL for tagged types with custom namespace' do
        position = Class.new(base_object) do
          graphql_name 'Position'
          tag name: 'private'

          field :x, Integer, null: false
          field :y, Integer, null: false
        end

        query_obj = Class.new(base_object) do
          graphql_name 'Query'

          field :position, position, null: true
        end

        schema = Class.new(base_schema) do
          query query_obj
          federation version: '2.0', link: { as: 'fed2' }
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", as: "fed2", import: ["@inaccessible", "@tag"])

            type Position @tag(name: "private") {
              x: Int!
              y: Int!
            }

            type Query {
              position: Position
            }
          GRAPHQL
        )
      end

      it 'returns valid SDL for @key directives with custom namespace' do
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
          federation version: '2.0', link: { as: 'fed2' }
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", as: "fed2", import: ["@inaccessible", "@tag"])

            type Product @fed2__key(fields: "upc") {
              upc: String!
            }

            type Query {
              product: Product
            }
          GRAPHQL
        )
      end

      it 'returns valid SDL for @external directives with custom namespace' do
        product = Class.new(base_object) do
          graphql_name 'Product'
          extend_type
          key fields: :upc

          field :upc, String, null: false, external: true
          field :price, Integer, null: true
        end

        schema = Class.new(base_schema) do
          orphan_types product
          federation version: '2.0', link: { as: 'fed2' }
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", as: "fed2", import: ["@inaccessible", "@tag"])

            type Product @fed2__extends @fed2__key(fields: "upc") {
              price: Int
              upc: String! @fed2__external
            }
          GRAPHQL
        )
      end

      it 'returns valid SDL for @interfaceObject directives with custom namespace' do
        product = Class.new(base_object) do
          graphql_name 'Product'
          interface_object
          key fields: :id

          field :id, 'ID', null: false
        end

        schema = Class.new(base_schema) do
          orphan_types product
          federation version: '2.3', link: { as: 'fed2' }
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", as: "fed2", import: ["@inaccessible", "@tag"])

            type Product @fed2__interfaceObject @fed2__key(fields: "id") {
              id: ID!
            }
          GRAPHQL
        )
      end
    end

    it 'returns valid SDL for inaccessible interface types' do
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

        inaccessible

        field :upc, String, null: false
      end

      book = Class.new(base_object) do
        implements product

        graphql_name 'Book'

        field :upc, String, null: false
      end

      schema = Class.new(base_schema) do
        if Gem::Version.new(GraphQL::VERSION) > Gem::Version.new('2.3.0')
          extra_types book, product
        else
          orphan_types book, product
        end

        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Book implements Product {
            upc: String!
          }

          interface Product @inaccessible {
            upc: String!
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for tagged interface types' do
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

        tag name: 'private'

        field :upc, String, null: false
      end

      book = Class.new(base_object) do
        implements product

        graphql_name 'Book'

        field :upc, String, null: false
      end

      schema = Class.new(base_schema) do
        if Gem::Version.new(GraphQL::VERSION) > Gem::Version.new('2.3.0')
          extra_types book, product
        else
          orphan_types book
        end

        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Book implements Product {
            upc: String!
          }

          interface Product @tag(name: "private") {
            upc: String!
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
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Book implements Product @federation__extends @federation__key(fields: "upc") {
            upc: String! @federation__external
          }

          type Pen implements Product @federation__key(fields: "upc") {
            upc: String!
          }

          interface Product @federation__key(fields: "upc") {
            upc: String!
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for tagged union types' do
      base_union = Class.new(GraphQL::Schema::Union) do
        include ApolloFederation::Union
      end

      book = Class.new(base_object) do
        graphql_name 'Book'

        field :upc, String, null: false
      end

      store = Class.new(base_object) do
        graphql_name 'Store'

        field :book, book, null: true
      end

      product = Class.new(base_union) do
        graphql_name 'Product'

        tag name: 'private'

        possible_types book
      end

      schema = Class.new(base_schema) do
        if Gem::Version.new(GraphQL::VERSION) > Gem::Version.new('2.3.0')
          orphan_types store, book
          extra_types product
        else
          orphan_types book, product
        end

        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Book {
            upc: String!
          }

          union Product @tag(name: "private") = Book
        GRAPHQL
      )
    end

    it 'returns valid SDL for inaccessible union types' do
      base_union = Class.new(GraphQL::Schema::Union) do
        include ApolloFederation::Union
      end

      book = Class.new(base_object) do
        graphql_name 'Book'

        field :upc, String, null: false
      end

      store = Class.new(base_object) do
        graphql_name 'Store'

        field :book, book, null: true
      end

      product = Class.new(base_union) do
        graphql_name 'Product'

        inaccessible

        possible_types book
      end

      schema = Class.new(base_schema) do
        if Gem::Version.new(GraphQL::VERSION) > Gem::Version.new('2.3.0')
          orphan_types store
          extra_types book, product
        else
          orphan_types book, product
        end
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Book {
            upc: String!
          }

          union Product @inaccessible = Book
        GRAPHQL
      )
    end

    it 'returns valid SDL for tagged enum types' do
      base_enum = Class.new(GraphQL::Schema::Enum) do
        include ApolloFederation::Enum
      end

      product_type = Class.new(base_enum) do
        graphql_name 'ProductType'
        tag name: 'private'

        value 'BOOK'
        value 'PEN'
      end

      product = Class.new(base_object) do
        graphql_name 'Product'

        field :type, product_type, null: false
      end

      schema = Class.new(base_schema) do
        if Gem::Version.new(GraphQL::VERSION) > Gem::Version.new('2.3.0')
          extra_types product_type
        else
          orphan_types product_type, product
        end

        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          enum ProductType @tag(name: "private") {
            BOOK
            PEN
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for inaccessible enum types' do
      base_enum = Class.new(GraphQL::Schema::Enum) do
        include ApolloFederation::Enum
      end

      product_type = Class.new(base_enum) do
        graphql_name 'ProductType'
        inaccessible

        value 'BOOK'
        value 'PEN'
      end

      product = Class.new(base_object) do
        graphql_name 'Product'

        field :type, product_type, null: false
      end

      schema = Class.new(base_schema) do
        if Gem::Version.new(GraphQL::VERSION) > Gem::Version.new('2.3.0')
          extra_types product_type
        else
          orphan_types product_type, product
        end

        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          enum ProductType @inaccessible {
            BOOK
            PEN
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for tagged scalar types' do
      base_scalar = Class.new(GraphQL::Schema::Scalar) do
        include ApolloFederation::Scalar
      end

      upc = Class.new(base_scalar) do
        graphql_name 'UPC'

        tag name: 'private'
      end

      product = Class.new(base_object) do
        graphql_name 'Product'

        field :upc, upc, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :product, product, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product {
            upc: UPC!
          }

          type Query {
            product: Product
          }

          scalar UPC @tag(name: "private")
        GRAPHQL
      )
    end

    it 'returns valid SDL for inaccessible scalar types' do
      base_scalar = Class.new(GraphQL::Schema::Scalar) do
        include ApolloFederation::Scalar
      end

      upc = Class.new(base_scalar) do
        graphql_name 'UPC'

        inaccessible
      end

      product = Class.new(base_object) do
        graphql_name 'Product'

        field :upc, upc, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :product, product, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product {
            upc: UPC!
          }

          type Query {
            product: Product
          }

          scalar UPC @inaccessible
        GRAPHQL
      )
    end

    it 'returns valid SDL for tagged input object types' do
      base_input_object = Class.new(GraphQL::Schema::InputObject) do
        include ApolloFederation::InputObject
      end

      product_attributes = Class.new(base_input_object) do
        graphql_name 'ProductAttributes'

        tag name: 'private'

        argument :upc, String, required: false
      end

      create_product = Class.new(GraphQL::Schema::Mutation) do
        graphql_name 'CreateProduct'

        argument :attributes, product_attributes, required: true

        field :success, GraphQL::Types::Boolean, null: false
      end

      mutations = Class.new(base_object) do
        graphql_name 'Mutation'

        field :create_product, mutation: create_product
      end

      schema = Class.new(base_schema) do
        mutation mutations
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          """
          Autogenerated return type of CreateProduct.
          """
          type CreateProductPayload {
            success: Boolean!
          }

          type Mutation {
            createProduct(attributes: ProductAttributes!): CreateProductPayload
          }

          input ProductAttributes @tag(name: "private") {
            upc: String
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for inaccessible input object types' do
      base_input_object = Class.new(GraphQL::Schema::InputObject) do
        include ApolloFederation::InputObject
      end

      product_attributes = Class.new(base_input_object) do
        graphql_name 'ProductAttributes'

        inaccessible

        argument :upc, String, required: false
      end

      create_product = Class.new(GraphQL::Schema::Mutation) do
        graphql_name 'CreateProduct'

        argument :attributes, product_attributes, required: true

        field :success, GraphQL::Types::Boolean, null: false
      end

      mutations = Class.new(base_object) do
        graphql_name 'Mutation'

        field :create_product, mutation: create_product
      end

      schema = Class.new(base_schema) do
        mutation mutations
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          """
          Autogenerated return type of CreateProduct.
          """
          type CreateProductPayload {
            success: Boolean!
          }

          type Mutation {
            createProduct(attributes: ProductAttributes!): CreateProductPayload
          }

          input ProductAttributes @inaccessible {
            upc: String
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for tagged input field types' do
      base_argument = Class.new(GraphQL::Schema::Argument) do
        include ApolloFederation::Argument
      end

      product_attributes = Class.new(GraphQL::Schema::InputObject) do
        graphql_name 'ProductAttributes'

        argument_class base_argument

        argument :upc, String, required: false, tags: [{ name: 'private' }]
      end

      create_product = Class.new(GraphQL::Schema::Mutation) do
        graphql_name 'CreateProduct'

        argument :attributes, product_attributes, required: true

        field :success, GraphQL::Types::Boolean, null: false
      end

      mutations = Class.new(base_object) do
        graphql_name 'Mutation'

        field :create_product, mutation: create_product
      end

      schema = Class.new(base_schema) do
        mutation mutations
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          """
          Autogenerated return type of CreateProduct.
          """
          type CreateProductPayload {
            success: Boolean!
          }

          type Mutation {
            createProduct(attributes: ProductAttributes!): CreateProductPayload
          }

          input ProductAttributes {
            upc: String @tag(name: "private")
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for inaccessible input field types' do
      base_argument = Class.new(GraphQL::Schema::Argument) do
        include ApolloFederation::Argument
      end

      product_attributes = Class.new(GraphQL::Schema::InputObject) do
        graphql_name 'ProductAttributes'

        argument_class base_argument

        argument :upc, String, required: false, inaccessible: true
      end

      create_product = Class.new(GraphQL::Schema::Mutation) do
        graphql_name 'CreateProduct'

        argument :attributes, product_attributes, required: true

        field :success, GraphQL::Types::Boolean, null: false
      end

      mutations = Class.new(base_object) do
        graphql_name 'Mutation'

        field :create_product, mutation: create_product
      end

      schema = Class.new(base_schema) do
        mutation mutations
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          """
          Autogenerated return type of CreateProduct.
          """
          type CreateProductPayload {
            success: Boolean!
          }

          type Mutation {
            createProduct(attributes: ProductAttributes!): CreateProductPayload
          }

          input ProductAttributes {
            upc: String @inaccessible
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for tagged argument types' do
      base_argument = Class.new(GraphQL::Schema::Argument) do
        include ApolloFederation::Argument
      end

      create_product = Class.new(GraphQL::Schema::Mutation) do
        graphql_name 'CreateProduct'

        argument_class base_argument

        argument :upc, String, required: true, tags: [{ name: 'private' }]

        field :success, GraphQL::Types::Boolean, null: false
      end

      mutations = Class.new(base_object) do
        graphql_name 'Mutation'

        field :create_product, mutation: create_product
      end

      schema = Class.new(base_schema) do
        mutation mutations
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          """
          Autogenerated return type of CreateProduct.
          """
          type CreateProductPayload {
            success: Boolean!
          }

          type Mutation {
            createProduct(upc: String! @tag(name: "private")): CreateProductPayload
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for inaccessible argument types' do
      base_argument = Class.new(GraphQL::Schema::Argument) do
        include ApolloFederation::Argument
      end

      create_product = Class.new(GraphQL::Schema::Mutation) do
        graphql_name 'CreateProduct'

        argument_class base_argument

        argument :upc, String, required: true, inaccessible: true

        field :success, GraphQL::Types::Boolean, null: false
      end

      mutations = Class.new(base_object) do
        graphql_name 'Mutation'

        field :create_product, mutation: create_product
      end

      schema = Class.new(base_schema) do
        mutation mutations
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          """
          Autogenerated return type of CreateProduct.
          """
          type CreateProductPayload {
            success: Boolean!
          }

          type Mutation {
            createProduct(upc: String! @inaccessible): CreateProductPayload
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
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__key(fields: "upc") @federation__key(fields: "name") {
            name: String
            upc: String!
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for unresolvable @key directives' do
      product = Class.new(base_object) do
        graphql_name 'Product'
        key fields: :upc, resolvable: false

        field :upc, String, null: false
      end

      schema = Class.new(base_schema) do
        orphan_types product
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__key(fields: "upc", resolvable: false) {
            upc: String!
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for resolvable @key directives' do
      product = Class.new(base_object) do
        graphql_name 'Product'
        key fields: :upc, resolvable: true

        field :upc, String, null: false
      end

      schema = Class.new(base_schema) do
        orphan_types product
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__key(fields: "upc") {
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
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__extends @federation__key(fields: "upc") {
            price: Int
            upc: String! @federation__external
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for @interfaceObject directives' do
      product = Class.new(base_object) do
        graphql_name 'Product'
        interface_object
        key fields: :id

        field :id, 'ID', null: false
      end

      schema = Class.new(base_schema) do
        orphan_types product
        federation version: '2.3'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__interfaceObject @federation__key(fields: "id") {
            id: ID!
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for @shareable directives' do
      position = Class.new(base_object) do
        graphql_name 'Position'

        field :x, Integer, null: false, shareable: true
        field :y, Integer, null: false, shareable: true
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :position, position, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Position {
            x: Int! @federation__shareable
            y: Int! @federation__shareable
          }

          type Query {
            position: Position
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for @inaccessible directives' do
      position = Class.new(base_object) do
        graphql_name 'Position'

        field :x, Integer, null: false, inaccessible: true
        field :y, Integer, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :position, position, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Position {
            x: Int! @inaccessible
            y: Int!
          }

          type Query {
            position: Position
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for @tag directives' do
      position = Class.new(base_object) do
        graphql_name 'Position'

        field :x, Integer, null: false, tags: [{ name: 'private' }]
        field :y, Integer, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :position, position, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Position {
            x: Int! @tag(name: "private")
            y: Int!
          }

          type Query {
            position: Position
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for multiple @tag directives' do
      position = Class.new(base_object) do
        graphql_name 'Position'

        field :x, Integer, null: false, tags: [{ name: 'private' }, { name: 'protected' }]
        field :y, Integer, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :position, position, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Position {
            x: Int! @tag(name: "private") @tag(name: "protected")
            y: Int!
          }

          type Query {
            position: Position
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for @tag enum value directives' do
      base_enum_value = Class.new(GraphQL::Schema::EnumValue) do
        include ApolloFederation::EnumValue
      end

      base_enum = Class.new(GraphQL::Schema::Enum) do
        include ApolloFederation::Enum

        enum_value_class base_enum_value
      end

      product_type = Class.new(base_enum) do
        graphql_name 'ProductType'

        value 'BOOK'
        value 'PEN', tags: [{ name: 'private' }]
      end

      product = Class.new(base_object) do
        graphql_name 'Product'

        field :type, product_type, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :product, product, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product {
            type: ProductType!
          }

          enum ProductType {
            BOOK
            PEN @tag(name: "private")
          }

          type Query {
            product: Product
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for multiple @tag enum value directives' do
      base_enum_value = Class.new(GraphQL::Schema::EnumValue) do
        include ApolloFederation::EnumValue
      end

      base_enum = Class.new(GraphQL::Schema::Enum) do
        include ApolloFederation::Enum

        enum_value_class base_enum_value
      end

      product_type = Class.new(base_enum) do
        graphql_name 'ProductType'

        value 'BOOK'
        value 'PEN', tags: [{ name: 'private' }, { name: 'protected' }]
      end

      product = Class.new(base_object) do
        graphql_name 'Product'

        field :type, product_type, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :product, product, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product {
            type: ProductType!
          }

          enum ProductType {
            BOOK
            PEN @tag(name: "private") @tag(name: "protected")
          }

          type Query {
            product: Product
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for multiple @inaccessible enum value directives' do
      base_enum_value = Class.new(GraphQL::Schema::EnumValue) do
        include ApolloFederation::EnumValue
      end

      base_enum = Class.new(GraphQL::Schema::Enum) do
        include ApolloFederation::Enum

        enum_value_class base_enum_value
      end

      product_type = Class.new(base_enum) do
        graphql_name 'ProductType'

        value 'BOOK'
        value 'PEN', inaccessible: true
      end

      product = Class.new(base_object) do
        graphql_name 'Product'

        field :type, product_type, null: false
      end

      query_obj = Class.new(base_object) do
        graphql_name 'Query'

        field :product, product, null: true
      end

      schema = Class.new(base_schema) do
        query query_obj
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product {
            type: ProductType!
          }

          enum ProductType {
            BOOK
            PEN @inaccessible
          }

          type Query {
            product: Product
          }
        GRAPHQL
      )
    end

    it 'returns valid SDL for @override directives' do
      product = Class.new(base_object) do
        graphql_name 'Product'
        extend_type
        key fields: :id

        field :id, 'ID', null: false
        field :isStock, 'Boolean', null: false, override: { from: 'Products' }
      end

      schema = Class.new(base_schema) do
        orphan_types product
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__extends @federation__key(fields: "id") {
            id: ID!
            isStock: Boolean! @federation__override(from: "Products")
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
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__extends @federation__key(fields: "upc") {
            price: Int
            upc: String! @federation__external
          }

          type Review @federation__key(fields: "id") {
            id: ID!
            product: Product @federation__provides(fields: "upc")
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
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__extends @federation__key(fields: "upc") {
            price: Int @federation__external
            shippingEstimate: Int @federation__requires(fields: "price weight")
            upc: String! @federation__external
            weight: Int @federation__external
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
          federation version: '2.0'
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

            type Product @federation__key(fields: "productId") {
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
          federation version: '2.0'
        end

        expect(execute_sdl(schema)).to match_sdl(
          <<~GRAPHQL,
            extend schema
              @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

            type Product @federation__extends @federation__key(fields: "product_id") {
              options: [String!]! @federation__requires(fields: "my_id")
              otherOptions: [String!]! @federation__requires(fields: "myId")
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
        federation version: '2.0'
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__extends @federation__key(fields: "upc") {
            upc: String! @federation__external
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
        federation version: '2.0'
        orphan_types product
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", import: ["@inaccessible", "@tag"])

          type Product @federation__key(fields: "id") {
            id: ID!
          }
        GRAPHQL
      )
    end

    it 'returns SDL that inherits schema directives' do
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
        federation version: '2.0', link: { as: 'fed2' }
      end

      schema = Class.new(new_base_schema) do
        query query_obj
      end

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", as: "fed2", import: ["@inaccessible", "@tag"])

          type Product @fed2__extends {
            upc: String!
          }

          type Query {
            product: Product
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
        federation version: '2.0', link: { as: 'fed2' }
        query query_obj
      end

      schema = Class.new(new_base_schema)

      expect(execute_sdl(schema)).to match_sdl(
        <<~GRAPHQL,
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3", as: "fed2", import: ["@inaccessible", "@tag"])

          type Product @fed2__extends {
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

    if Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.13.0')
      context 'with visibility checks on types and fields with duplicate names' do
        let(:schema) do
          regular_product = Class.new(base_object) do
            graphql_name 'Product'
            key fields: :upc

            field :upc, String, null: false
            field :regular_field, String, null: true

            def self.visible?(context)
              context[:graph_type] == :regular
            end
          end

          admin_product = Class.new(base_object) do
            graphql_name 'Product'
            key fields: :upc

            field :upc, String, null: false
            field :admin_field, String, null: true

            def self.visible?(context)
              context[:graph_type] == :admin
            end
          end

          query_obj = Class.new(base_object) do
            graphql_name 'Query'

            field :hello, String, null: false

            field :product, regular_product, null: true do
              def visible?(context)
                context[:graph_type] == :regular
              end
            end

            field :product, admin_product, null: true do
              def visible?(context)
                context[:graph_type] == :admin
              end
            end
          end

          Class.new(base_schema) do
            query query_obj
          end
        end

        it 'applies visibility checks during SDL generation to expose schema members' do
          results = schema.execute('{ _service { sdl } }', context: { graph_type: :regular })

          expect(results.dig('data', '_service', 'sdl')).to match_sdl(
            <<~GRAPHQL,
              type Product @key(fields: "upc") {
                regularField: String
                upc: String!
              }

              type Query {
                hello: String!
                product: Product
              }
            GRAPHQL
          )
        end

        it 'applies visibility checks during SDL generation to expose alternate schema members' do
          results = schema.execute('{ _service { sdl } }', context: { graph_type: :admin })

          expect(results.dig('data', '_service', 'sdl')).to match_sdl(
            <<~GRAPHQL,
              type Product @key(fields: "upc") {
                adminField: String
                upc: String!
              }

              type Query {
                hello: String!
                product: Product
              }
            GRAPHQL
          )
        end
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
