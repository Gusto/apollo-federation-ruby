# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'apollo-federation/schema'
require 'apollo-federation/field'
require 'apollo-federation/object'

RSpec.describe ApolloFederation::FederatedDocumentFromSchemaDefinition do

  shared_examples 'federated document from schema' do
    let(:base_object) do
      base_field = Class.new(GraphQL::Schema::Field) do
        include ApolloFederation::Field
      end

      Class.new(GraphQL::Schema::Object) do
        include ApolloFederation::Object
        field_class base_field
      end
    end

    describe '#federation_2?' do
      it 'returns true when a schema object uses a federation 2 directive' do
        product = Class.new(base_object) do
          graphql_name 'Product'
          shareable

          field :upc2, String, null: false
        end

        query_obj = Class.new(base_object) do
          graphql_name 'Query'

          field :product, product, null: true
        end

        schema = Class.new(base_schema) do
          query query_obj
        end

        document_from_schema = ApolloFederation::FederatedDocumentFromSchemaDefinition.new(schema)
        expect(document_from_schema).to be_federation_2
      end

      it 'returns true when a schema field uses a federation 2 directive' do
        product = Class.new(base_object) do
          graphql_name 'Product'

          field :upc2, String, null: false, shareable: true
        end

        query_obj = Class.new(base_object) do
          graphql_name 'Query'

          field :product, product, null: true
        end

        schema = Class.new(base_schema) do
          query query_obj
        end

        document_from_schema = ApolloFederation::FederatedDocumentFromSchemaDefinition.new(schema)
        expect(document_from_schema).to be_federation_2
      end

      it 'returns false when no federation 2 directive are used' do
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

        document_from_schema = ApolloFederation::FederatedDocumentFromSchemaDefinition.new(schema)
        expect(document_from_schema).not_to be_federation_2
      end
    end
  end

  if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('1.12.0')
    context 'with older versions of GraphQL and the interpreter runtime' do
      it_behaves_like 'federated document from schema' do
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
    it_behaves_like 'federated document from schema' do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          include ApolloFederation::Schema
        end
      end
    end
  end
end
