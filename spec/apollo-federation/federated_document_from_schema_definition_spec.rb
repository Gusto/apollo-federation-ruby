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
