# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'apollo-federation/schema'
require 'apollo-federation/object'

RSpec.describe ApolloFederation::Schema do
  describe '.federation_version' do
    it 'returns 1.0 by default' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
      end

      expect(schema.federation_version).to eq('1.0')
    end

    it 'returns the specified version when set to 2.0' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: '2.0'
      end

      expect(schema.federation_version).to eq('2.0')
    end

    it 'returns the specified version when set to 2.3' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: '2.3'
      end

      expect(schema.federation_version).to eq('2.3')
    end
  end

  describe '.federation_2?' do
    it 'returns false when version is an integer less than 2.0' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: 1
      end

      expect(schema.federation_2?).to be(false)
    end

    it 'returns false when version is less than 2.0' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: '1.5'
      end

      expect(schema.federation_2?).to be(false)
    end

    it 'returns true when the version is an integer equal to 2' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: 2
      end

      expect(schema.federation_2?).to be(true)
    end

    it 'returns true when the version is a float equal to 2.0' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: 2.0
      end

      expect(schema.federation_2?).to be(true)
    end

    it 'returns true when the version is a float greater than 2.0' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: 2.3
      end

      expect(schema.federation_2?).to be(true)
    end

    it 'returns true when the version is a string greater than 2.0' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: '2.0.1'
      end

      expect(schema.federation_2?).to be(true)
    end

    it 'returns true when the version is a string equal to 2.3' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: '2.3'
      end

      expect(schema.federation_2?).to be(true)
    end
  end

  describe '.query' do
    it 'traverses the query type' do
      cat_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Cat'
      end
      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :cat, cat_type, null: false
      end
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        query query_type
      end

      expect(schema.get_type('Cat')).to eq(cat_type)
    end
  end

  describe 'types declared after .query' do
    let(:base_object) do
      Class.new(GraphQL::Schema::Object) do
        include ApolloFederation::Object
      end
    end
    let(:product) do
      Class.new(base_object) do
        graphql_name 'Product'
        key fields: :upc
        field :upc, String, null: false
      end
    end
    let(:review) do
      Class.new(base_object) do
        graphql_name 'Review'
        key fields: :id
        field :id, 'ID', null: false
      end
    end
    let(:query_type) do
      Class.new(base_object) do
        graphql_name 'Query'
        field :hello, String, null: true
      end
    end

    # Selects `__typename` plus the key field of every type in the representations
    def resolve_entities(schema, representations)
      fragments = {
        'Product' => '... on Product { upc }',
        'Review' => '... on Review { id }',
      }.values_at(*representations.map { |r| r['__typename'] }.uniq)
      query_string = <<~GRAPHQL
        query($representations: [_Any!]!) {
          _entities(representations: $representations) {
            __typename
            #{fragments.join("\n")}
          }
        }
      GRAPHQL
      schema.execute(query_string, variables: { 'representations' => representations }).to_h
    end

    def schema_with(*declarations)
      Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        declarations.each { |method, type| public_send(method, type) }
      end
    end

    context 'when orphan_types is declared after query' do
      let(:schema) { schema_with([:query, query_type], [:orphan_types, product]) }
      let(:orphans_first_schema) { schema_with([:orphan_types, product], [:query, query_type]) }

      it 'adds the entities to the _Entity union' do
        expect(schema.to_definition).to include('union _Entity = Product')
      end

      it 'adds Query._entities' do
        expect(schema.to_definition).to include('_entities(representations: [_Any!]!): [_Entity]!')
      end

      it 'resolves the entities' do
        expect(resolve_entities(schema, [{ '__typename' => 'Product', 'upc' => '1' }])).to eq(
          'data' => { '_entities' => [{ '__typename' => 'Product', 'upc' => '1' }] },
        )
      end

      it 'generates the same schema as declaring orphan_types first' do
        expect(schema.to_definition).to eq(orphans_first_schema.to_definition)
      end

      it 'generates the same federation SDL as declaring orphan_types first' do
        expect(schema.federation_sdl).to eq(orphans_first_schema.federation_sdl)
      end
    end

    context 'when more entities are added after the _Entity union exists' do
      let(:schema) do
        schema_with([:orphan_types, product], [:query, query_type], [:orphan_types, review])
      end

      it 'extends the existing union' do
        expect(schema.to_definition).to match(/^union _Entity = Product \| Review$/)
      end

      it 'does not define a second union' do
        expect(schema.to_definition.scan('union _Entity').size).to eq(1)
      end

      it 'resolves entities of both types' do
        representations = [{ '__typename' => 'Review', 'id' => '7' }, { '__typename' => 'Product', 'upc' => '1' }]

        expect(resolve_entities(schema, representations)).to eq(
          'data' => {
            '_entities' => [{ '__typename' => 'Review', 'id' => '7' }, { '__typename' => 'Product', 'upc' => '1' }],
          },
        )
      end
    end

    context 'when an entity is only reachable from a mutation declared after query' do
      let(:mutation_type) do
        review_type = review
        Class.new(base_object) do
          graphql_name 'Mutation'
          field :add_review, review_type, null: true
        end
      end
      let(:schema) { schema_with([:query, query_type], [:mutation, mutation_type]) }

      it 'adds it to the _Entity union' do
        expect(schema.to_definition).to include('union _Entity = Review')
      end

      it 'resolves it' do
        expect(resolve_entities(schema, [{ '__typename' => 'Review', 'id' => '7' }])).to eq(
          'data' => { '_entities' => [{ '__typename' => 'Review', 'id' => '7' }] },
        )
      end
    end

    context 'when the types declared after query are not entities' do
      let(:plain_type) do
        Class.new(base_object) do
          graphql_name 'Plain'
          field :name, String, null: true
        end
      end
      let(:schema) { schema_with([:query, query_type], [:orphan_types, plain_type]) }

      it 'does not add Query._entities or the _Entity union' do
        expect(schema.to_definition).not_to match(/_entities|_Entity/)
      end
    end
  end
end
