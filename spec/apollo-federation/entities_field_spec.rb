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

  # GraphQL::Execution::Next didn't exist before graphql-ruby 2.6; guarded rather than pinned to
  # this repo's own (older) Gemfile.lock version so it activates automatically once that's bumped.
  if defined?(GraphQL::Execution::Next)
    describe 'under GraphQL::Execution::Next', :next_execution do
      let(:base_field) do
        Class.new(GraphQL::Schema::Field) do
          include ApolloFederation::Field
        end
      end

      let(:base_object) do
        base_field_class = base_field
        Class.new(GraphQL::Schema::Object) do
          include ApolloFederation::Object
          field_class base_field_class
        end
      end

      let(:load_calls) { [] }

      let(:source_class) do
        calls = load_calls
        Class.new(GraphQL::Dataloader::Source) do
          define_method(:fetch) do |ids|
            calls << ids.dup
            ids.map { |id| { id: id, other_field: "loaded-#{id}" } }
          end
        end
      end

      let(:type_with_reference) do
        Class.new(base_object) do
          graphql_name 'TypeWithReference'
          key fields: :id
          field :id, 'ID', null: false, hash_key: :id
          field :other_field, 'String', null: true, hash_key: :other_field

          def self.resolve_reference(reference, _context)
            { id: reference[:id], other_field: 'resolved!' } if reference[:id] == 123
          end
        end
      end

      let(:type_with_references) do
        Class.new(base_object) do
          graphql_name 'TypeWithReferences'
          key fields: :id
          field :id, 'ID', null: false, hash_key: :id
          field :other_field, 'String', null: true, hash_key: :other_field

          def self.resolve_references(references, _context)
            references.map { |reference| { id: reference[:id], other_field: "batched-#{reference[:id]}" } }
          end
        end
      end

      let(:type_with_lazy_reference) do
        source = source_class
        Class.new(base_object) do
          graphql_name 'TypeWithLazyReference'
          key fields: :id
          field :id, 'ID', null: false, hash_key: :id
          field :other_field, 'String', null: true, hash_key: :other_field

          define_singleton_method(:resolve_reference) do |reference, context|
            context.dataloader.with(source).load(reference[:id])
          end
        end
      end

      # GraphQL::Execution::Lazy directly (not Dataloader's #load, which blocks the calling fiber
      # until resolved and so never leaves a Lazy for _entities to hold onto): this is what
      # actually reaches the per-entry sync in resolve_entities_for_next below, the same shape
      # graphql-batch's Promise takes.
      let(:type_with_plain_lazy_reference) do
        Class.new(base_object) do
          graphql_name 'TypeWithPlainLazyReference'
          key fields: :id
          field :id, 'ID', null: false, hash_key: :id
          field :other_field, 'String', null: true, hash_key: :other_field

          define_singleton_method(:resolve_reference) do |reference, _context|
            GraphQL::Execution::Lazy.new { { id: reference[:id], other_field: "lazily-loaded-#{reference[:id]}" } }
          end
        end
      end

      let(:query) do
        type_with_reference_class = type_with_reference
        type_with_references_class = type_with_references
        type_with_lazy_reference_class = type_with_lazy_reference
        type_with_plain_lazy_reference_class = type_with_plain_lazy_reference
        Class.new(base_object) do
          graphql_name 'Query'
          field :type_with_reference, type_with_reference_class, null: true
          field :type_with_references, type_with_references_class, null: true
          field :type_with_lazy_reference, type_with_lazy_reference_class, null: true
          field :type_with_plain_lazy_reference, type_with_plain_lazy_reference_class, null: true
        end
      end

      let(:schema) do
        query_class = query
        built_schema = Class.new(GraphQL::Schema) do
          include ApolloFederation::Schema
          query query_class
          use GraphQL::Dataloader
          self.dataloader_class = GraphQL::Dataloader
        end
        built_schema.extend(GraphQL::Execution::Next::SchemaExtension)
        built_schema
      end

      let(:classic_result) { schema.execute(query_string, variables: variables, root_value: nil).to_h }
      let(:next_result) { schema.execute_next(query_string, variables: variables, context: {}, root_value: nil).to_h }

      shared_examples 'matches classic' do
        it 'resolves the same as classic execution' do
          expect(next_result).to eq(classic_result)
        end

        it 'resolves the expected entities' do
          expect(next_result).to eq(expected_result)
        end
      end

      context 'with a synchronous resolve_reference' do
        let(:query_string) do
          <<~GRAPHQL
            query($representations: [_Any!]!) {
              _entities(representations: $representations) {
                ... on TypeWithReference { id otherField }
              }
            }
          GRAPHQL
        end
        let(:variables) { { representations: [{ __typename: 'TypeWithReference', id: 123 }] } }
        let(:expected_result) do
          { 'data' => { '_entities' => [{ 'id' => '123', 'otherField' => 'resolved!' }] } }
        end

        include_examples 'matches classic'
      end

      context 'with a batched resolve_references' do
        let(:query_string) do
          <<~GRAPHQL
            query($representations: [_Any!]!) {
              _entities(representations: $representations) {
                ... on TypeWithReferences { id otherField }
              }
            }
          GRAPHQL
        end
        let(:variables) do
          { representations: [
            { __typename: 'TypeWithReferences', id: 1 },
            { __typename: 'TypeWithReferences', id: 2 },
          ] }
        end
        let(:expected_result) do
          { 'data' => { '_entities' => [
            { 'id' => '1', 'otherField' => 'batched-1' },
            { 'id' => '2', 'otherField' => 'batched-2' },
          ] } }
        end

        include_examples 'matches classic'
      end

      context 'with a Dataloader-backed (lazy) resolve_reference' do
        let(:query_string) do
          <<~GRAPHQL
            query($representations: [_Any!]!) {
              _entities(representations: $representations) {
                ... on TypeWithLazyReference { id otherField }
              }
            }
          GRAPHQL
        end
        let(:variables) { { representations: [{ __typename: 'TypeWithLazyReference', id: 7 }] } }
        let(:expected_result) do
          { 'data' => { '_entities' => [{ 'id' => '7', 'otherField' => 'loaded-7' }] } }
        end

        include_examples 'matches classic'
      end

      context 'with a GraphQL::Execution::Lazy-returning resolve_reference' do
        let(:query_string) do
          <<~GRAPHQL
            query($representations: [_Any!]!) {
              _entities(representations: $representations) {
                ... on TypeWithPlainLazyReference { id otherField }
              }
            }
          GRAPHQL
        end
        let(:variables) { { representations: [{ __typename: 'TypeWithPlainLazyReference', id: 9 }] } }
        let(:expected_result) do
          { 'data' => { '_entities' => [{ 'id' => '9', 'otherField' => 'lazily-loaded-9' }] } }
        end

        include_examples 'matches classic'
      end

      context 'with multiple __typenames in one request' do
        let(:query_string) do
          <<~GRAPHQL
            query($representations: [_Any!]!) {
              _entities(representations: $representations) {
                ... on TypeWithReference { id otherField }
                ... on TypeWithReferences { id otherField }
                ... on TypeWithLazyReference { id otherField }
              }
            }
          GRAPHQL
        end
        let(:variables) do
          { representations: [
            { __typename: 'TypeWithReference', id: 123 },
            { __typename: 'TypeWithReferences', id: 1 },
            { __typename: 'TypeWithLazyReference', id: 7 },
            { __typename: 'TypeWithReferences', id: 2 },
          ] }
        end
        let(:expected_result) do
          { 'data' => { '_entities' => [
            { 'id' => '123', 'otherField' => 'resolved!' },
            { 'id' => '1', 'otherField' => 'batched-1' },
            { 'id' => '7', 'otherField' => 'loaded-7' },
            { 'id' => '2', 'otherField' => 'batched-2' },
          ] } }
        end

        include_examples 'matches classic'
      end

      context 'with an unknown __typename' do
        let(:query_string) do
          <<~GRAPHQL
            query($representations: [_Any!]!) {
              _entities(representations: $representations) {
                ... on TypeWithReference { id }
              }
            }
          GRAPHQL
        end
        let(:variables) { { representations: [{ __typename: 'NotInSchema', id: 1 }] } }
        let(:unknown_typename_error) { /The _entities resolver tried to load an entity for type "NotInSchema"/ }

        it 'raises under classic' do
          expect { classic_result }.to raise_error(unknown_typename_error)
        end

        it 'raises the same error under Next' do
          expect { next_result }.to raise_error(unknown_typename_error)
        end
      end
    end
  end

  # GraphQL::Execution::Next didn't exist before graphql-ruby 2.6; same reasoning as above -- this
  # exercises the classic-only contract that resolve_static's Next-facing method must not disturb.
  if defined?(GraphQL::Execution::Next)
    describe 'classic execution, with GraphQL::Execution::Next available', :next_execution do
      let(:base_field) do
        Class.new(GraphQL::Schema::Field) do
          include ApolloFederation::Field
        end
      end

      let(:base_object) do
        base_field_class = base_field
        Class.new(GraphQL::Schema::Object) do
          include ApolloFederation::Object
          field_class base_field_class
        end
      end

      let(:load_calls) { [] }

      let(:source_class) do
        calls = load_calls
        Class.new(GraphQL::Dataloader::Source) do
          define_method(:fetch) do |ids|
            calls << ids.dup
            ids.map { |id| { id: id, other_field: "loaded-#{id}" } }
          end
        end
      end

      let(:type_with_lazy_reference) do
        source = source_class
        Class.new(base_object) do
          graphql_name 'TypeWithLazyReference'
          key fields: :id
          field :id, 'ID', null: false, hash_key: :id
          field :other_field, 'String', null: true, hash_key: :other_field

          define_singleton_method(:resolve_reference) do |reference, context|
            context.dataloader.with(source).load(reference[:id])
          end
        end
      end

      # GraphQL::Execution::Lazy directly, rather than a real Dataloader source: .load requires a
      # running Dataloader fiber (i.e. an actual query execution), which the plain-Lazy check
      # below deliberately bypasses to inspect _entities' return value in isolation.
      let(:type_with_plain_lazy_reference) do
        Class.new(base_object) do
          graphql_name 'TypeWithPlainLazyReference'
          key fields: :id
          field :id, 'ID', null: false, hash_key: :id

          define_singleton_method(:resolve_reference) do |reference, _context|
            GraphQL::Execution::Lazy.new { { id: reference[:id] } }
          end
        end
      end

      let(:query) do
        type_with_lazy_reference_class = type_with_lazy_reference
        type_with_plain_lazy_reference_class = type_with_plain_lazy_reference
        Class.new(base_object) do
          graphql_name 'Query'
          field :type_with_lazy_reference, type_with_lazy_reference_class, null: true
          field :type_with_plain_lazy_reference, type_with_plain_lazy_reference_class, null: true
        end
      end

      let(:schema) do
        query_class = query
        Class.new(GraphQL::Schema) do
          include ApolloFederation::Schema
          query query_class
          use GraphQL::Dataloader
          self.dataloader_class = GraphQL::Dataloader
        end
      end

      let(:query_string) do
        <<~GRAPHQL
          query($r1: [_Any!]!, $r2: [_Any!]!) {
            e1: _entities(representations: $r1) { ... on TypeWithLazyReference { id otherField } }
            e2: _entities(representations: $r2) { ... on TypeWithLazyReference { id otherField } }
          }
        GRAPHQL
      end
      let(:variables) do
        {
          r1: [{ __typename: 'TypeWithLazyReference', id: 1 }],
          r2: [{ __typename: 'TypeWithLazyReference', id: 2 }],
        }
      end
      let(:result) { schema.execute(query_string, variables: variables, root_value: nil) }

      it 'resolves both aliased selections' do
        expect(result.to_h).to eq(
          'data' => {
            'e1' => [{ 'id' => '1', 'otherField' => 'loaded-1' }],
            'e2' => [{ 'id' => '2', 'otherField' => 'loaded-2' }],
          },
        )
      end

      it 'batches them into a single fetch' do
        result
        expect(load_calls.size).to eq(1)
      end

      it 'fetches both ids in that one batch' do
        result
        expect(load_calls.first).to contain_exactly(1, 2)
      end

      # Dataloader's own Fiber-yielding tolerates an early sync well enough that the batching
      # test above passes either way -- this is the test that actually distinguishes "classic
      # gets the lazy back" from "classic gets it pre-synced": a runtime-agnostic check of what
      # _entities' return value *is*, not of how one particular lazy mechanism schedules around
      # it. graphql-batch's Promise (no Fiber involved) is the mechanism an early sync visibly
      # breaks batching for.
      it 'returns the lazy value itself for classic to resolve, rather than resolving it eagerly' do
        query_object = GraphQL::Query.new(schema, '{ __typename }', root_value: nil)
        representations = [{ __typename: 'TypeWithPlainLazyReference', id: 1 }]

        result = schema.query._entities(query_object.context, representations: representations)

        expect(result).to be_a(GraphQL::Execution::Lazy)
      end
    end
  end
end
