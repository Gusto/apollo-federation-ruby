require 'graphql'
require 'apollo-federation/schema'
require 'apollo-federation/field'
require 'apollo-federation/object'

describe ApolloFederation::EntitiesField do
  RSpec::Matchers.define :match_sdl do |expected|
    match do |actual|
      @actual = "#{actual}\n"
      @actual == expected
    end

    diffable
  end

  let(:base_schema) do
    Class.new(GraphQL::Schema) do
      extend ApolloFederation::Schema
    end
  end

  let(:base_object) do
    base_field = Class.new(GraphQL::Schema::Field) do
      include ApolloFederation::Field
    end

    Class.new(GraphQL::Schema::Object) do
      extend ApolloFederation::Object
      field_class base_field
    end
  end

  context 'when a type with the key directive doesn\'t exist' do
    it 'does not add the _entities field' do
      schema = Class.new(base_schema) do
      end

      expect(schema.to_definition).to match_sdl(
      <<~GRAPHQL
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

  context 'when a type with the key directive exists' do
    let(:type_with_key) do
      Class.new(base_object) do
        graphql_name 'TypeWithKey'
        key fields: 'id'
        field :id, 'ID', null: false
        field :other_field, 'String', null: false
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
        <<~GRAPHQL
          type Query {
            _entities(representations: [_Any!]!): [_Entity]!
            _service: _Service!
            typeWithKey: TypeWithKey
          }

          type TypeWithKey {
            id: ID!
            otherField: String!
          }

          scalar _Any

          union _Entity = TypeWithKey

          type _Service {
            sdl: String
          }
        GRAPHQL
        )
      end
    end

    context 'when a Query object is not provided' do
      let(:mutation) do # creating a mutation with the TypeWithKey object so it gets included in the schema
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
          <<~GRAPHQL
            type Mutation {
              typeWithKey: TypeWithKey
            }

            type Query {
              _entities(representations: [_Any!]!): [_Entity]!
              _service: _Service!
            }

            type TypeWithKey {
              id: ID!
              otherField: String!
            }

            scalar _Any

            union _Entity = TypeWithKey

            type _Service {
              sdl: String
            }
          GRAPHQL
        )
      end

      describe 'resolver for _entities' do
        let(:execute_query) do
          schema.execute(
            "{ _entities(representations: #{representations}) { ... on TypeWithKey {#{selection}} } }"
          )
        end
        let(:selection) { 'id otherField' }
        subject(:entities_result) { execute_query['data']['_entities'] }
        let(:errors) { execute_query['errors'] }

        context 'representations is empty' do
          let(:representations) {'[]'}
          it { is_expected.to match_array [] }
          it { expect(errors).to be_nil }
        end

        context 'representations is not empty' do
          let(:representations) {"[{__typename: #{typename}, id: #{id}}]"}
          let(:id) { 123 }

          context 'typename corresponds to a type that does not exist in the schema' do
            let(:typename) { 'TypeNotInSchema' }

            it 'raises' do
              expect(-> {execute_query}).to raise_error
            end
          end

          context 'typename corresponds to a type that exists in the schema' do
            let(:typename) { type_with_key.graphql_name }

            context 'the type does not define a resolve_reference method' do
              context 'selection includes fields that are not part of the reference' do
                let(:selection) { 'id otherField' }
                it { is_expected.to match_array [nil] }
                it { expect(errors).to eq ['message' => 'Cannot return null for non-nullable field TypeWithKey.otherField'] }
              end

              context 'selection only includes fields that are part of the reference' do
                let(:selection) { 'id' }
                it { is_expected.to match_array [{'id' => id.to_s}] }
                it { expect(errors).to be_nil }
              end
            end

            context 'the type defines a resolve_reference method' do
              let(:type_with_key) do
                Class.new(base_object) do
                  graphql_name 'TypeWithKey'
                  key fields: 'id'
                  field :id, 'ID', null: false
                  field :other_field, 'String', null: false

                  def self.resolve_reference(reference, _context)
                    if reference[:id] == 123
                      {id: 123, other_field: 'more data'}
                    else
                      nil
                    end
                  end
                end
              end
              it { is_expected.to match_array [{'id' => id.to_s, 'otherField' => 'more data'}] }
              it { expect(errors).to be_nil }
            end
          end
        end
      end
    end
  end
end
