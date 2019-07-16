# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'apollo-federation/schema'
require 'apollo-federation/field'
require 'apollo-federation/object'

RSpec.describe ApolloFederation::EntitiesField do
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

  context 'when a type with the key directive doesn\'t exist' do
    it 'does not add the _entities field' do
      schema = Class.new(base_schema) do
      end

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

  context 'when a type with the key directive exists' do
    let(:type_with_key) do
      Class.new(base_object) do
        graphql_name 'TypeWithKey'
        key fields: 'id'
        field :id, 'ID', null: false
        field :other_field, 'String', null: true
      end
    end

    context 'when a Query object is provided' do
      let(:query) do
        type_with_key_class = type_with_key
        Class.new(base_object) do
          graphql_name 'Query'
          field :type_with_key, type_with_key_class, null: true
        end
      end

      let(:schema) do
        query_class = query
        Class.new(base_schema) do
          query query_class
        end
      end

      it 'adds an _entities field to the Query object' do
        expect(schema.to_definition).to match_sdl(
          <<~GRAPHQL,
            type Query {
              _entities(representations: [_Any!]!): [_Entity]!
              _service: _Service!
              typeWithKey: TypeWithKey
            }

            type TypeWithKey {
              id: ID!
              otherField: String
            }

            scalar _Any

            union _Entity = TypeWithKey

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
      let(:mutation) do
        # creating a mutation with the TypeWithKey object so it gets included in the schema
        type_with_key_class = type_with_key
        Class.new(base_object) do
          graphql_name 'Mutation'
          field :type_with_key, type_with_key_class, null: true
        end
      end

      let(:schema) do
        mutation_class = mutation
        Class.new(base_schema) do
          mutation mutation_class
        end
      end

      it 'creates a Query object and adds an _entities field to it' do
        expect(schema.to_definition).to match_sdl(
          <<~GRAPHQL,
            type Mutation {
              typeWithKey: TypeWithKey
            }

            type Query {
              _entities(representations: [_Any!]!): [_Entity]!
              _service: _Service!
            }

            type TypeWithKey {
              id: ID!
              otherField: String
            }

            scalar _Any

            union _Entity = TypeWithKey

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

      describe 'resolver for _entities' do
        subject(:entities_result) { execute_query['data']['_entities'] }

        let(:query) do
          <<~GRAPHQL
            query EntitiesQuery($representations: [_Any!]!) {
              _entities(representations: $representations) {
                ... on TypeWithKey {
                  id
                  otherField
                }
              }
            }
          GRAPHQL
        end

        let(:execute_query) do
          schema.execute(query, variables: { representations: representations })
        end
        let(:errors) { execute_query['errors'] }

        context 'when representations is empty' do
          let(:representations) { [] }

          it { is_expected.to match_array [] }
          it { expect(errors).to be_nil }
        end

        context 'when representations is not empty' do
          let(:representations) { [{ __typename: typename, id: id }] }
          let(:id) { 123 }

          context 'when typename corresponds to a type that does not exist in the schema' do
            let(:typename) { 'TypeNotInSchema' }

            it 'raises' do
              expect(-> { execute_query }).to raise_error(
                /The _entities resolver tried to load an entity for type "TypeNotInSchema"/,
              )
            end
          end

          context 'when typename corresponds to a type that exists in the schema' do
            let(:typename) { type_with_key.graphql_name }

            context 'when the type does not define a resolve_reference method' do
              it { is_expected.to match_array [{ 'id' => id.to_s, 'otherField' => nil }] }
              it { expect(errors).to be_nil }
            end

            context 'when the type defines a resolve_reference method' do
              let(:type_with_key) do
                Class.new(base_object) do
                  graphql_name 'TypeWithKey'
                  key fields: 'id'
                  field :id, 'ID', null: false
                  field :other_field, 'String', null: false

                  def self.resolve_reference(reference, _context)
                    { id: 123, other_field: 'more data' } if reference[:id] == 123
                  end
                end
              end

              it { is_expected.to match_array [{ 'id' => id.to_s, 'otherField' => 'more data' }] }
              it { expect(errors).to be_nil }
            end
          end
        end
      end
    end
  end
end
