# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'apollo-federation/schema'
require 'apollo-federation/field'
require 'apollo-federation/object'

RSpec.describe ApolloFederation::EntitiesField do
  shared_examples 'entities field' do |make_final_schema|
    let(:base_object) do
      base_field = Class.new(GraphQL::Schema::Field) do
        include ApolloFederation::Field
      end

      Class.new(GraphQL::Schema::Object) do
        include ApolloFederation::Object
        field_class base_field
      end
    end

    let(:fed_schema) { make_final_schema&.call(schema) || schema }

    context 'when a type with the key directive doesn\'t exist' do
      let(:schema) { base_schema }

      it 'does not add the _entities field' do
        expect(fed_schema.to_definition).to match_sdl(
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
          base_schema.class_eval do
            query query_class
          end
          base_schema
        end

        it 'sets the Query as the owner to the _entities field' do
          expect(
            fed_schema.graphql_definition
              .types['Query']
              .fields['_entities']
              .metadata[:type_class]
              .owner.graphql_name,
          ).to eq('Query')
        end

        it 'adds an _entities field to the Query object' do
          expect(fed_schema.to_definition).to match_sdl(
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
          base_schema.class_eval do
            mutation mutation_class
          end
          base_schema
        end

        it 'creates a Query object and adds an _entities field to it' do
          expect(fed_schema.to_definition).to match_sdl(
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
            fed_schema.execute(query, variables: { representations: representations })
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
                      { id: 123, other_field: 'data!' } if reference[:id] == 123
                    end
                  end
                end

                it { is_expected.to match_array [{ 'id' => id.to_s, 'otherField' => 'data!' }] }
                it { expect(errors).to be_nil }

                context 'when resolve_reference returns a lazy object' do
                  let(:lazy_entity) do
                    Class.new do
                      def initialize(callable)
                        @callable = callable
                      end

                      def load_entity
                        @callable.call
                      end
                    end
                  end

                  let(:schema) do
                    lazy_entity_class = lazy_entity
                    type_with_key_class = type_with_key
                    base_schema.class_eval do
                      lazy_resolve(lazy_entity_class, :load_entity)

                      orphan_types type_with_key_class
                    end
                    base_schema
                  end

                  let(:resolve_method) do
                    lazy_entity_class = lazy_entity

                    lambda do |reference, _context|
                      if reference[:id] == 123
                        lazy_entity_class.new(-> { { id: 123, other_field: 'data!' } })
                      end
                    end
                  end

                  let(:type_with_key) do
                    resolve_method_pointer = resolve_method

                    Class.new(base_object) do
                      graphql_name 'TypeWithKey'
                      key fields: 'id'
                      field :id, 'ID', null: false
                      field :other_field, 'String', null: false

                      define_singleton_method :resolve_reference, &resolve_method_pointer
                    end
                  end

                  it { is_expected.to match_array [{ 'id' => id.to_s, 'otherField' => 'data!' }] }
                  it { expect(errors).to be_nil }

                  context 'when lazy object raises an error' do
                    let(:base_schema) do
                      Class.new(GraphQL::Schema) do
                        include ApolloFederation::Schema
                      end
                    end

                    let(:id1) { 123 }
                    let(:id2) { 321 }
                    let(:representations) do
                      [
                        { __typename: typename, id: id1 },
                        { __typename: typename, id: id2 },
                      ]
                    end

                    let(:resolve_method) do
                      lazy_entity_class = lazy_entity

                      lambda do |reference, _context|
                        case reference[:id]
                        when 123
                          lazy_entity_class.new(-> { { id: 123, other_field: 'more data' } })
                        when 321
                          lazy_entity_class.new(-> { raise(GraphQL::ExecutionError, 'error') })
                        end
                      end
                    end

                    specify do
                      expect(execute_query.to_h).to match(
                        'data' => {
                          '_entities' => [
                            { 'id' => id.to_s, 'otherField' => 'more data' },
                            nil,
                          ],
                        },
                        'errors' => [
                          {
                            'locations' => [{ 'column' => 3, 'line' => 2 }],
                            'message' => 'error',
                            'path' => ['_entities', 1],
                          },
                        ],
                      )
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('1.12.0')
    context 'with the original runtime' do
      it_behaves_like 'entities field' do
        let(:base_schema) do
          Class.new(GraphQL::Schema) do
            include ApolloFederation::Schema
          end
        end
      end
    end
  end

  context 'with the interpreter runtime' do
    it_behaves_like 'entities field' do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('1.12.0')
            use GraphQL::Execution::Interpreter
            use GraphQL::Analysis::AST
          end

          include ApolloFederation::Schema
        end
      end
    end
  end

  context 'when the federation schema is a subclass of the base schema' do
    final_schema = lambda do |schema|
      Class.new(schema) do
        include ApolloFederation::Schema
      end
    end

    it_behaves_like 'entities field', final_schema do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('1.12.0')
            use GraphQL::Execution::Interpreter
            use GraphQL::Analysis::AST
          end
        end
      end
    end
  end
end
