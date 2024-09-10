# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'apollo-federation/schema'
require 'apollo-federation/field'
require 'apollo-federation/object'

RSpec.describe ApolloFederation::EntitiesField do
  shared_examples 'entities field' do
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
          key fields: :id
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

            def self.resolve_type(_abstract_type, _obj, _ctx)
              # to return the correct object type for `obj`
              raise(GraphQL::RequiredImplementationMissingError)
            end
          end
        end

        it 'sets the Query as the owner to the _entities field' do
          expect(
            schema.query
              .fields['_entities']
              .owner.graphql_name,
          ).to eq('Query')
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

      context 'when a Query object is inherited' do
        let(:query) do
          type_with_key_class = type_with_key
          Class.new(base_object) do
            graphql_name 'Query'
            field :type_with_key, type_with_key_class, null: true
          end
        end

        let(:schema) do
          query_class = query
          parent_schema = Class.new(base_schema) do
            query query_class
          end
          Class.new(parent_schema)
        end

        it 'generates an _Entity union with the correct members' do
          entity_type = schema.query.fields.fetch('_entities').type.unwrap
          expect(entity_type.type_memberships.map(&:object_type)).to eq([type_with_key])
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
          s = schema
          expect(s.to_definition).to match_sdl(
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
              let(:lazy_resolver) do
                Class.new do
                  def initialize(&callable)
                    @callable = callable
                  end

                  def resolve
                    @callable.call
                  end
                end
              end
              let(:lazy_schema) do
                lazy_resolver_class = lazy_resolver
                type_with_key_class = type_with_key
                Class.new(base_schema) do
                  lazy_resolve(lazy_resolver_class, :resolve)

                  orphan_types type_with_key_class
                end
              end

              context 'when the type does not define a resolve_reference method' do
                it { is_expected.to match_array [{ 'id' => id.to_s, 'otherField' => nil }] }
                it { expect(errors).to be_nil }
              end

              context 'when the type defines a resolve_references method' do
                let(:representations) do
                  [{ __typename: typename, id: id_1 }, { __typename: typename, id: id_2 }]
                end
                let(:id_1) { 123 }
                let(:id_2) { 456 }

                let(:type_with_key) do
                  Class.new(base_object) do
                    graphql_name 'TypeWithKey'
                    key fields: :id
                    field :id, 'ID', null: false
                    field :other_field, 'String', null: false

                    def self.resolve_references(_references, _context)
                      [{ id: 123, other_field: 'data!' }, { id: 456, other_field: 'data2!' }]
                    end
                  end
                end

                it {
                  expect(subject).to match_array [
                    { 'id' => id_1.to_s, 'otherField' => 'data!' },
                    { 'id' => id_2.to_s, 'otherField' => 'data2!' },
                  ]
                }

                it { expect(errors).to be_nil }

                context 'when resolve_references returns a lazy object' do
                  let(:schema) { lazy_schema }

                  let(:resolve_method) do
                    lazy_resolver_class = lazy_resolver

                    lambda do |_references, _context|
                      lazy_resolver_class.new do
                        [{ id: 123, other_field: 'data!' }, { id: 456, other_field: 'data2!' }]
                      end
                    end
                  end

                  let(:type_with_key) do
                    resolve_method_pointer = resolve_method
                    Class.new(base_object) do
                      graphql_name 'TypeWithKey'
                      key fields: :id
                      field :id, 'ID', null: false
                      field :other_field, 'String', null: false

                      define_singleton_method :resolve_references, &resolve_method_pointer
                    end
                  end

                  it {
                    expect(subject).to match_array [
                      { 'id' => id_1.to_s, 'otherField' => 'data!' },
                      { 'id' => id_2.to_s, 'otherField' => 'data2!' },
                    ]
                  }

                  it { expect(errors).to be_nil }
                end

                context 'when there are multiple, interleaved __typenames being requested' do
                  let(:another_type_with_key) do
                    Class.new(base_object) do
                      graphql_name 'AnotherTypeWithKey'
                      key fields: :id
                      field :id, 'ID', null: false
                      field :other_field, 'String', null: true
                      def self.resolve_references(references, _context)
                        references.map do |reference|
                          { id: reference[:id], other_field: ('a'.ord - 1 + reference[:id]).chr }
                        end
                      end
                    end
                  end
                  let(:type_with_key) do
                    Class.new(base_object) do
                      graphql_name 'TypeWithKey'
                      key fields: :id
                      field :id, 'ID', null: false
                      field :other_field, 'String', null: false
                      def self.resolve_references(references, _context)
                        references.map do |reference|
                          { id: reference[:id], other_field: ('a'.ord - 1 + reference[:id]).chr }
                        end
                      end
                    end
                  end
                  let(:mutation) do
                    another_type_with_key_class = another_type_with_key
                    type_with_key_class = type_with_key
                    Class.new(base_object) do
                      graphql_name 'Mutation'
                      field :another_type_with_key, another_type_with_key_class, null: true
                      field :type_with_key, type_with_key_class, null: true
                    end
                  end
                  let(:another_typename) { another_type_with_key.graphql_name }
                  let(:query) do
                    <<~GRAPHQL
                      query EntitiesQuery($representations: [_Any!]!) {
                        _entities(representations: $representations) {
                          __typename
                          ... on AnotherTypeWithKey {
                            id
                            otherField
                          }
                          ... on TypeWithKey {
                            id
                            otherField
                          }
                        }
                      }
                    GRAPHQL
                  end
                  let(:representations) do
                    [
                      { __typename: typename, id: 1 },
                      { __typename: typename, id: 2 },
                      { __typename: another_typename, id: 3 },
                      { __typename: another_typename, id: 4 },
                      { __typename: typename, id: 5 },
                      { __typename: typename, id: 6 },
                      { __typename: typename, id: 7 },
                      { __typename: another_typename, id: 8 },
                      { __typename: another_typename, id: 9 },
                      { __typename: typename, id: 10 },
                    ]
                  end

                  it 'returns the list of entities in the same order as they were requested' do
                    expect(subject).to eql(
                      [
                        { 'id' => '1', 'otherField' => 'a', '__typename' => 'TypeWithKey' },
                        { 'id' => '2', 'otherField' => 'b', '__typename' => 'TypeWithKey' },
                        { 'id' => '3', 'otherField' => 'c', '__typename' => 'AnotherTypeWithKey' },
                        { 'id' => '4', 'otherField' => 'd', '__typename' => 'AnotherTypeWithKey' },
                        { 'id' => '5', 'otherField' => 'e', '__typename' => 'TypeWithKey' },
                        { 'id' => '6', 'otherField' => 'f', '__typename' => 'TypeWithKey' },
                        { 'id' => '7', 'otherField' => 'g', '__typename' => 'TypeWithKey' },
                        { 'id' => '8', 'otherField' => 'h', '__typename' => 'AnotherTypeWithKey' },
                        { 'id' => '9', 'otherField' => 'i', '__typename' => 'AnotherTypeWithKey' },
                        { 'id' => '10', 'otherField' => 'j', '__typename' => 'TypeWithKey' },
                      ],
                    )
                  end

                  it 'calls resolve_references once per __typename' do
                    allow(type_with_key).to receive(:resolve_references).and_call_original
                    allow(another_type_with_key).to receive(:resolve_references).and_call_original
                    subject
                    expect([type_with_key, another_type_with_key]).to all have_received(:resolve_references).once
                  end
                end
              end

              context 'when the type defines a resolve_reference method' do
                let(:type_with_key) do
                  Class.new(base_object) do
                    graphql_name 'TypeWithKey'
                    key fields: :id
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
                  let(:schema) { lazy_schema }

                  let(:resolve_method) do
                    lazy_resolver_class = lazy_resolver

                    lambda do |reference, _context|
                      if reference[:id] == 123
                        lazy_resolver_class.new { { id: 123, other_field: 'data!' } }
                      end
                    end
                  end

                  let(:type_with_key) do
                    resolve_method_pointer = resolve_method

                    Class.new(base_object) do
                      graphql_name 'TypeWithKey'
                      key fields: :id
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
                      lazy_resolver_class = lazy_resolver

                      lambda do |reference, _context|
                        case reference[:id]
                        when 123
                          lazy_resolver_class.new { { id: 123, other_field: 'more data' } }
                        when 321
                          lazy_resolver_class.new { raise(GraphQL::ExecutionError, 'error') }
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

              context 'when reference keys have multiple words' do
                let(:representations) { [{ __typename: typename, myId: id }] }
                let(:query) do
                  <<~GRAPHQL
                    query EntitiesQuery($representations: [_Any!]!) {
                      _entities(representations: $representations) {
                        ... on TypeWithKey {
                          myId
                          otherField
                        }
                      }
                    }
                  GRAPHQL
                end

                context 'when the type does not underscore reference keys' do
                  let(:type_with_key) do
                    Class.new(base_object) do
                      graphql_name 'TypeWithKey'
                      key fields: :my_id
                      field :my_id, 'ID', null: false
                      field :other_field, 'String', null: false

                      def self.resolve_reference(reference, _context)
                        { my_id: 123, other_field: 'data!' } if reference[:myId] == 123
                      end
                    end
                  end

                  it { is_expected.to match_array [{ 'myId' => id.to_s, 'otherField' => 'data!' }] }
                  it { expect(errors).to be_nil }
                end

                context 'when the type underscores reference keys' do
                  let(:type_with_key) do
                    Class.new(base_object) do
                      graphql_name 'TypeWithKey'
                      key fields: :my_id
                      underscore_reference_keys true
                      field :my_id, 'ID', null: false
                      field :other_field, 'String', null: false

                      def self.resolve_reference(reference, _context)
                        { my_id: 123, other_field: 'data!' } if reference[:my_id] == 123
                      end
                    end
                  end

                  it { is_expected.to match_array [{ 'myId' => id.to_s, 'otherField' => 'data!' }] }
                  it { expect(errors).to be_nil }
                end

                context 'when the type\'s superclass underscores reference keys' do
                  let(:type_with_key) do
                    parent = Class.new(base_object) do
                      underscore_reference_keys true
                    end

                    Class.new(parent) do
                      graphql_name 'TypeWithKey'
                      key fields: :my_id
                      field :my_id, 'ID', null: false
                      field :other_field, 'String', null: false

                      def self.resolve_reference(reference, _context)
                        { my_id: 123, other_field: 'data!' } if reference[:my_id] == 123
                      end
                    end
                  end

                  it { is_expected.to match_array [{ 'myId' => id.to_s, 'otherField' => 'data!' }] }
                  it { expect(errors).to be_nil }
                end
              end
            end
          end
        end
      end
    end
  end

  if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('1.12.0')
    context 'with older versions of GraphQL and the interpreter runtime' do
      it_behaves_like 'entities field' do
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
    it_behaves_like 'entities field' do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          include ApolloFederation::Schema
        end
      end
    end
  end
end
