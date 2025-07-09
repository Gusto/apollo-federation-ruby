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

    it 'returns the specified version when set to 2.6' do
      schema = Class.new(GraphQL::Schema) do
        include ApolloFederation::Schema
        federation version: '2.6'
      end

      expect(schema.federation_version).to eq('2.6')
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

  if Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.12.0')
    describe '.federation_sdl' do
      context 'when filtering custom directives from imports' do
        def create_test_schema
          custom_type = Class.new(GraphQL::Schema::Object) do
            include ApolloFederation::Object
            graphql_name 'CustomType'

            # Federation directive - should be imported in newer versions
            key fields: :id

            # Custom directive - should NOT be imported
            add_directive(name: 'version', arguments: [
                            { name: 'from', values: '1.0' },
                            { name: 'to', values: '2.0' },
                          ],)

            field :id, GraphQL::Types::ID, null: false
          end

          query_type = Class.new(GraphQL::Schema::Object) do
            graphql_name 'Query'
            field :custom, custom_type, null: false
          end

          Class.new(GraphQL::Schema) do
            include ApolloFederation::Schema
            query query_type
            federation version: '2.6'
          end
        end

        # Test that custom directives are not imported regardless of GraphQL version
        it 'does not import custom directives from federation specs' do
          sdl = create_test_schema.federation_sdl
          expect(sdl).not_to include('"@version"')
        end

        it 'includes custom directive in type definition' do
          sdl = create_test_schema.federation_sdl
          expect(sdl).to include('@version(from: "1.0", to: "2.0")')
        end

        it 'includes federation directive in type definition' do
          sdl = create_test_schema.federation_sdl
          expect(sdl).to include('@key(fields: "id")')
        end

        it 'includes @link directive with import array for federation directives' do
          sdl = create_test_schema.federation_sdl
          expect(sdl).to include('@link(url: "https://specs.apollo.dev/federation/v2.6", import: ["@key"])')
        end
      end
    end
  end
end
