# frozen_string_literal: true

require 'spec_helper'
require 'graphql'
require 'apollo-federation/schema'
require 'apollo-federation/field'
require 'apollo-federation/object'
require 'apollo-federation/interface'

require_relative './spec_types'

RSpec.describe ApolloFederation::EntitiesField do
  shared_examples 'entities field' do
    context 'when an interface with the key directive doesn\'t exist' do
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

    context 'when an interface with the key directive exists' do
      context "when some of the types implementing the inteface don't have the key directive" do
        let(:offending_class) do
        end
        let(:query) do
          user_class = SpecTypes::User
          Class.new(SpecTypes::BaseObject) do
            graphql_name 'Query'
            field :user, user_class, null: true
          end
        end

        it 'raises an error' do
          query_class = query

          offending_class = Class.new(SpecTypes::BaseObject) do
            graphql_name 'Manager'
            implements SpecTypes::User

            field :id, 'ID', null: false
          end

          schema = Class.new(base_schema) do
            query query_class
            orphan_types SpecTypes::AdminType, offending_class
          end

          expect { schema.to_definition }.to raise_error(
            'Interface User is not valid. Types `Manager` do not have a @key directive. ' \
            'All types that implement an interface with a @key directive must also have a @key directive.',
          )
        end
      end

      context 'when a Query object is provided' do
        let(:query) do
          user_class = SpecTypes::User
          Class.new(SpecTypes::BaseObject) do
            graphql_name 'Query'
            field :user, user_class, null: true
          end
        end

        let(:schema) do
          query_class = query
          Class.new(base_schema) do
            query query_class
            orphan_types SpecTypes::AdminType, SpecTypes::EndUserType
            def self.resolve_type(_abstract_type, _obj, _ctx)
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
              type Admin implements User {
                email: String
                id: ID!
              }

              type EndUser implements User {
                email: String
                id: ID!
              }

              type Query {
                _entities(representations: [_Any!]!): [_Entity]!
                _service: _Service!
                user: User
              }

              interface User {
                email: String
                id: ID!
              }

              scalar _Any

              union _Entity = Admin | EndUser | User

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
          # creating a mutation with the User object so it gets included in the schema
          user_class = SpecTypes::User
          Class.new(SpecTypes::BaseObject) do
            graphql_name 'Mutation'
            field :user, user_class, null: true
          end
        end

        let(:schema) do
          mutation_class = mutation
          Class.new(base_schema) do
            orphan_types SpecTypes::AdminType, SpecTypes::EndUserType
            mutation mutation_class

            def self.resolve_type(_abstract_type, _obj, _ctx)
              raise(GraphQL::RequiredImplementationMissingError)
            end
          end
        end

        it 'creates a Query object and adds an _entities field to it' do
          s = schema
          expect(s.to_definition).to match_sdl(
            <<~GRAPHQL,
              type Admin implements User {
                email: String
                id: ID!
              }

              type EndUser implements User {
                email: String
                id: ID!
              }

              type Mutation {
                user: User
              }

              type Query {
                _entities(representations: [_Any!]!): [_Entity]!
                _service: _Service!
              }

              interface User {
                email: String
                id: ID!
              }

              scalar _Any

              union _Entity = Admin | EndUser | User

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
              query InterfaceEntityQuery($representations: [_Any!]!) {
                _entities(representations: $representations) {
                  ... on User {
                    id
                    email
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
            let(:id) { '10' }

            context 'when typename corresponds to an interface that does not exist in the schema' do
              let(:typename) { 'TypeNotInSchema' }

              it 'raises' do
                expect { execute_query }
                  .to raise_error(/The _entities resolver tried to load an entity for type "TypeNotInSchema"/)
              end
            end

            context 'when typename corresponds to an interface that exists in the schema' do
              let(:typename) { SpecTypes::User.graphql_name }

              # Because the Entity is an interface, not having `resolve_references` implemented
              # means that we can't know what type to return, so the `resolve_type` on the interface will be called.
              # In our test example, we are throwing an error in the `resolve_type` method, so we expect an error.
              # In reality, the expected result might differ, depending on the implementation of `resolve_type`.
              context 'when the interface does not define a resolve_reference method' do
                it 'raises' do
                  expect { execute_query }.to raise_error(GraphQL::RequiredImplementationMissingError)
                end
              end

              context 'when we define reference resolvers' do
                context 'when we resolve interface entity references' do
                  let(:typename) { SpecTypes::Product.graphql_name }
                  let(:query) do
                    <<~GRAPHQL
                      query EntitiesQuery($representations: [_Any!]!) {
                        _entities(representations: $representations) {
                          ... on Product {
                            __typename
                            id
                            title
                          }
                        }
                      }
                    GRAPHQL
                  end

                  context 'when the interface defines a resolve_references method' do
                    # Because we can't add methods to Modules the same we do with classes,
                    # (as in, we can't create subclasses of a Module), we need to add the method
                    # to the singleton metrods of the Module and then remove it after the test.
                    before do
                      resolve_method_pointer = resolve_method
                      SpecTypes::Product.define_singleton_method :resolve_references, &resolve_method_pointer
                    end

                    after do
                      SpecTypes::Product.singleton_class.remove_method :resolve_references
                    end

                    let(:resolve_method) do
                      lambda do |references, _context|
                        ids = references.map { |reference| reference[:id] }
                        products = SpecTypes::PRODUCTS.select { |product| ids.include?(product[:id]) }

                        products.map do |product|
                          if product[:type] == 'Book'
                            SpecTypes::Book.new(product)
                          elsif product[:type] == 'Movie'
                            SpecTypes::Movie.new(product)
                          end
                        end
                      end
                    end

                    let(:mutation) do
                      product_class = SpecTypes::Product
                      Class.new(SpecTypes::BaseObject) do
                        graphql_name 'Mutation'
                        field :product, product_class, null: true
                      end
                    end

                    let(:schema) do
                      mutation_class = mutation
                      Class.new(base_schema) do
                        orphan_types SpecTypes::BookType, SpecTypes::MovieType
                        mutation mutation_class

                        def self.resolve_type(_abstract_type, _obj, _ctx)
                          raise(GraphQL::RequiredImplementationMissingError)
                        end
                      end
                    end

                    let(:representations) do
                      [{ __typename: typename, id: id_1 }, { __typename: typename, id: id_2 }]
                    end
                    let(:id_1) { '10' }
                    let(:id_2) { '30' }

                    it {
                      expect(subject).to match_array [
                        { '__typename' => 'Book', 'id' => id_1.to_s, 'title' => 'Dark Matter' },
                        { '__typename' => 'Movie', 'id' => id_2.to_s, 'title' => 'The GraphQL Documentary' },
                      ]
                    }
                    it { expect(errors).to be_nil }
                  end

                  context 'when the interface defines a resolve_reference method' do
                    let(:mutation) do
                      product_class = SpecTypes::Product
                      Class.new(SpecTypes::BaseObject) do
                        graphql_name 'Mutation'
                        field :product, product_class, null: true
                      end
                    end

                    let(:schema) do
                      mutation_class = mutation
                      Class.new(base_schema) do
                        orphan_types SpecTypes::BookType, SpecTypes::MovieType
                        mutation mutation_class

                        def self.resolve_type(_abstract_type, _obj, _ctx)
                          raise(GraphQL::RequiredImplementationMissingError)
                        end
                      end
                    end

                    it { is_expected.to match_array [{ '__typename' => 'Book', 'id' => id, 'title' => 'Dark Matter' }] }
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

                      let(:resolve_method) do
                        lazy_entity_class = lazy_entity

                        lambda do |reference, _context|
                          if reference[:id] == '10'
                            lazy_entity_class.new(-> { SpecTypes::Book.new(SpecTypes::PRODUCTS[0]) })
                          end
                        end
                      end

                      let(:mutation) do
                        resolve_method_pointer = resolve_method
                        SpecTypes::Product.define_singleton_method :resolve_reference, &resolve_method_pointer

                        product_class = SpecTypes::Product
                        Class.new(SpecTypes::BaseObject) do
                          graphql_name 'Mutation'
                          field :product, product_class, null: true
                        end
                      end

                      let(:schema) do
                        lazy_entity_class = lazy_entity
                        mutation_class = mutation
                        Class.new(base_schema) do
                          orphan_types SpecTypes::BookType, SpecTypes::MovieType
                          lazy_resolve(lazy_entity_class, :load_entity)
                          mutation mutation_class

                          def self.resolve_type(_abstract_type, _obj, _ctx)
                            raise(GraphQL::RequiredImplementationMissingError)
                          end
                        end
                      end

                      it {
                        expect(subject).to match_array [
                          { '__typename' => 'Book', 'id' => id.to_s, 'title' => 'Dark Matter' },
                        ]
                      }
                      it { expect(errors).to be_nil }

                      context 'when lazy object raises an error' do
                        let(:id1) { '10' }
                        let(:id2) { '30' }
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
                            when '10'
                              lazy_entity_class.new(-> { SpecTypes::Book.new(SpecTypes::PRODUCTS[0]) })
                            when '30'
                              lazy_entity_class.new(-> { raise(GraphQL::ExecutionError, 'error') })
                            end
                          end
                        end

                        specify do
                          expect(execute_query.to_h).to match(
                            'data' => {
                              '_entities' => [
                                { '__typename' => 'Book', 'id' => id.to_s, 'title' => 'Dark Matter' },
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

                context 'when we resolve implementing types entity references' do
                  let(:typename) { SpecTypes::BookType.graphql_name }
                  let(:query) do
                    <<~GRAPHQL
                      query EntitiesQuery($representations: [_Any!]!) {
                        _entities(representations: $representations) {
                          ... on Book {
                            __typename
                            id
                            title
                          }
                        }
                      }
                    GRAPHQL
                  end

                  context 'when the type defines a resolve_reference method' do
                    let(:mutation) do
                      product_class = SpecTypes::Product
                      Class.new(SpecTypes::BaseObject) do
                        graphql_name 'Mutation'
                        field :product, product_class, null: true
                      end
                    end

                    let(:schema) do
                      mutation_class = mutation
                      Class.new(base_schema) do
                        orphan_types SpecTypes::BookType, SpecTypes::MovieType
                        mutation mutation_class

                        def self.resolve_type(_abstract_type, _obj, _ctx)
                          raise(GraphQL::RequiredImplementationMissingError)
                        end
                      end
                    end

                    it { is_expected.to match_array [{ '__typename' => 'Book', 'id' => id, 'title' => 'Dark Matter' }] }
                    it { expect(errors).to be_nil }
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
