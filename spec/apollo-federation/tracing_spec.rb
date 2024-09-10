# frozen_string_literal: true

require 'spec_helper'
require 'apollo-federation'

RSpec.describe ApolloFederation::Tracing do
  RSpec.shared_examples 'a basic tracer' do
    let(:expected_trace_start_time) { 1_564_920_001 }

    let(:expected_end_time) do
      if Gem::Version.new(GraphQL::VERSION) > Gem::Version.new('2.3.0')
        1_564_920_003
      else
        1_564_920_002
      end
    end

    # configure clocks to increment by 1 for each call
    before do
      t = Time.new(2019, 8, 4, 12, 0, 0, '+00:00')
      allow(Time).to receive(:now) { t += 1 }

      # nanos are used for durations and offsets, so you'll never see 42, 43, ...
      # instead, you'll see the difference from the first call (the start time)
      # which will be 1, 2, 3 ...
      ns = 42
      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :nanosecond) { ns += 1 }
    end

    describe 'respecting options on context' do
      let(:schema) do
        query_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Query'

          field :test, String, null: false

          def test
            'hello world'
          end
        end

        Class.new(base_schema) do
          query query_obj
        end
      end

      it 'does not add tracing extension by default' do
        result = schema.execute('{ test }')
        expect(result[:extensions]).to be_nil
      end

      it 'adds the extensions.ftv1 when the context has tracing_enabled: true' do
        result = schema.execute('{ test }', context: { tracing_enabled: true })
        expect(result[:extensions][:ftv1]).not_to be_nil
      end

      it 'adds debugging info when the context has debug_tracing: true' do
        result = schema.execute('{ test }', context: { tracing_enabled: true, debug_tracing: true })
        expect(result[:extensions][:ftv1_debug]).not_to be_nil
      end

      context 'with a multiplex query' do
        it 'does not add tracing extension by default' do
          result = schema.multiplex(
            [
              { query: '{ test }' },
              { query: '{ test }' },
              { query: '{ test }' },
            ],
          ).first
          expect(result[:extensions]).to be_nil
        end

        it 'adds the extensions.ftv1 when the context has tracing_enabled: true' do
          result = schema.multiplex(
            [
              { query: '{ test }', context: { tracing_enabled: true } },
              { query: '{ test }', context: { tracing_enabled: true } },
              { query: '{ test }', context: { tracing_enabled: true } },
            ],
          ).first
          expect(result[:extensions][:ftv1]).not_to be_nil
        end

        it 'adds debugging info when the context has debug_tracing: true' do
          result = schema.multiplex(
            [
              { query: '{ test }', context: { tracing_enabled: true, debug_tracing: true } },
              { query: '{ test }', context: { tracing_enabled: true, debug_tracing: true } },
              { query: '{ test }', context: { tracing_enabled: true, debug_tracing: true } },
            ],
          ).first
          expect(result[:extensions][:ftv1_debug]).not_to be_nil
        end
      end
    end

    def trace(query)
      result = schema.execute(query, context: { tracing_enabled: true })

      ApolloFederation::Tracing::Trace.decode(Base64.decode64(result[:extensions][:ftv1]))
    end

    describe 'building the trace tree' do
      let(:schema) do
        grandchild_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Grandchild'

          field :id, String, null: false
        end

        child_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Child'

          field :id, String, null: false
          field :grandchild, grandchild_obj, null: false

          def grandchild
            { id: 'grandchild' }
          end
        end

        parent_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Parent'

          field :id, String, null: false
          field :child, child_obj, null: false

          def child
            { id: 'child' }
          end
        end

        query_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Query'

          field :parent, parent_obj, null: false
          field :strings, [String], null: false

          def parent
            { id: 'parent' }
          end

          def strings
            ['hello', 'goodbye']
          end
        end

        Class.new(base_schema) do
          query query_obj
        end
      end

      it 'records timing for children' do
        query = '{ parent { id, child { id, grandchild { id } } } }'

        traced_data = trace(query).to_h

        expect(traced_data).to match(
          hash_including(
            start_time: { seconds: expected_trace_start_time, nanos: 0 },
            end_time: { seconds: be > expected_trace_start_time, nanos: 0 },
            duration_ns: 13,
            root: hash_including(
              child: [
                hash_including(
                  response_name: 'parent',
                  type: 'Parent!',
                  start_time: 1,
                  end_time: be > 1,
                  parent_type: 'Query',
                  child: [
                    hash_including(
                      response_name: 'id',
                      type: 'String!',
                      start_time: 3,
                      end_time: be > 3,
                      parent_type: 'Parent',
                    ),
                    hash_including(
                      response_name: 'child',
                      type: 'Child!',
                      start_time: 5,
                      end_time: be > 5,
                      parent_type: 'Parent',
                      child: [
                        hash_including(
                          response_name: 'id',
                          type: 'String!',
                          start_time: 7,
                          end_time: be > 7,
                          parent_type: 'Child',
                        ),
                        hash_including(
                          response_name: 'grandchild',
                          type: 'Grandchild!',
                          start_time: 9,
                          end_time: be > 9,
                          parent_type: 'Child',
                          child: [
                            hash_including(
                              response_name: 'id',
                              type: 'String!',
                              start_time: 11,
                              end_time: be > 11,
                              parent_type: 'Grandchild',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      end

      it 'works for scalar arrays' do
        expect(trace('{ strings }')).to eq ApolloFederation::Tracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: expected_end_time, nanos: 0 },
          duration_ns: 3,
          root: {
            child: [{
              response_name: 'strings',
              type: '[String!]!',
              start_time: 1,
              end_time: 2,
              parent_type: 'Query',
            }],
          },
        )
      end
    end

    describe 'lazy values' do
      let(:lazy_class) do
        Class.new do
          def initialize(value = 'lazy_value')
            @value = value
          end

          attr_reader :value
        end
      end

      let(:schema) do
        item_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Item'

          field :id, String, null: false
        end

        query_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Query'

          field :lazy_scalar, String, null: false
          field :array_of_lazy_scalars, [String], null: false
          field :lazy_array_of_scalars, [String], null: false
          field :lazy_array_of_lazy_scalars, [String], null: false
          field :array_of_lazy_objects, [item_obj], null: false
          field :lazy_array_of_objects, [item_obj], null: false

          def lazy_scalar
            Lazy.new
          end

          def array_of_lazy_scalars
            [Lazy.new('hi'), Lazy.new('bye')]
          end

          def lazy_array_of_scalars
            Lazy.new(['hi', 'bye'])
          end

          def lazy_array_of_lazy_scalars
            Lazy.new([Lazy.new('hi'), Lazy.new('bye')])
          end

          def array_of_lazy_objects
            [Lazy.new(id: '123'), Lazy.new(id: '456')]
          end

          def lazy_array_of_objects
            Lazy.new([{ id: '123' }, { id: '456' }])
          end
        end

        Class.new(base_schema) do
          query query_obj
          lazy_resolve(Lazy, :value)
        end
      end

      before do
        stub_const('Lazy', lazy_class)
      end

      it 'works with lazy values' do
        expect(trace('{ lazyScalar }')).to eq ApolloFederation::Tracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: expected_end_time, nanos: 0 },
          duration_ns: 4,
          root: {
            child: [{
              response_name: 'lazyScalar',
              type: 'String!',
              start_time: 1,
              # This is the only discrepancy between a normal field and a lazy field.
              # The fake clock incremented once at the end of the `execute_field` step,
              # and again at the end of the `execute_field_lazy` step, so we record the
              # end time as being two nanoseconds after the start time instead of one.
              end_time: 3,
              parent_type: 'Query',
            }],
          },
        )
      end

      it 'works with an array of lazy scalars' do
        traced_data = trace('{ arrayOfLazyScalars }').to_h

        expect(traced_data).to match(
          hash_including(
            start_time: { seconds: expected_trace_start_time, nanos: 0 },
            end_time: { seconds: be > expected_trace_start_time, nanos: 0 },

            # The old runtime and the interpreter handle arrays of lazy objects differently.
            # The old runtime doesn't trigger the `execute_field_lazy` tracer event, so we have to
            # use the (inaccurate) end times from the `execute_field` event.
            duration_ns: be > 0,

            root: hash_including(
              child: [
                hash_including(
                  response_name: 'arrayOfLazyScalars',
                  type: '[String!]!',
                  start_time: 1,
                  end_time: be > 1,
                  parent_type: 'Query',
                ),
              ],
            ),
          ),
        )
      end

      it 'works with a lazy array of scalars' do
        expect(trace('{ lazyArrayOfScalars }')).to eq ApolloFederation::Tracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: expected_end_time, nanos: 0 },
          duration_ns: 4,
          root: {
            child: [{
              response_name: 'lazyArrayOfScalars',
              type: '[String!]!',
              start_time: 1,
              end_time: 3,
              parent_type: 'Query',
            }],
          },
        )
      end

      it 'works with a lazy array of lazy scalars' do
        traced_data = trace('{ lazyArrayOfLazyScalars }').to_h

        expect(traced_data).to match(
          hash_including(
            start_time: { seconds: 1_564_920_001, nanos: 0 },
            end_time: { seconds: expected_end_time, nanos: 0 },
            duration_ns: be > 0,
            root: hash_including(
              child: [hash_including(
                response_name: 'lazyArrayOfLazyScalars',
                type: '[String!]!',
                start_time: 1,
                end_time: be > 1,
                parent_type: 'Query',
              )],
            ),
          ),
        )
      end

      it 'works with array of lazy objects' do
        traced_data = trace('{ arrayOfLazyObjects { id } }').to_h

        expect(traced_data).to match(
          hash_including(
            start_time: { seconds: expected_trace_start_time, nanos: 0 },
            end_time: { seconds: be > expected_trace_start_time, nanos: 0 },
            duration_ns: be > 0,
            root: hash_including(
              child: [hash_including(
                response_name: 'arrayOfLazyObjects',
                type: '[Item!]!',
                start_time: 1,
                end_time: be > 0,
                parent_type: 'Query',
                child: [
                  hash_including(
                    index: 0,
                    child: [hash_including(
                      response_name: 'id',
                      type: 'String!',
                      start_time: be > 0,
                      end_time: be > 0,
                      parent_type: 'Item',
                    )],
                  ),
                  hash_including(
                    index: 1,
                    child: [hash_including(
                      response_name: 'id',
                      type: 'String!',
                      start_time: be > 0,
                      end_time: be > 0,
                      parent_type: 'Item',
                    )],
                  ),
                ],
              )],
            ),
          ),
        )
      end

      it 'works with a lazy array of objects' do
        traced_data = trace('{ lazyArrayOfObjects { id } }').to_h

        expect(traced_data).to match(
          hash_including(
            start_time: { seconds: expected_trace_start_time, nanos: 0 },
            end_time: { seconds: be > expected_trace_start_time, nanos: 0 },
            duration_ns: 8,
            root: hash_including(
              child: [
                hash_including(
                  response_name: 'lazyArrayOfObjects',
                  type: '[Item!]!',
                  start_time: 1,
                  end_time: be > 1,
                  parent_type: 'Query',
                  child: [
                    hash_including(
                      index: 0,
                      child: [hash_including(
                        response_name: 'id',
                        type: 'String!',
                        start_time: 4,
                        end_time: be > 4,
                        parent_type: 'Item',
                      )],
                    ),
                    hash_including(
                      index: 1,
                      child: [hash_including(
                        response_name: 'id',
                        type: 'String!',
                        start_time: 6,
                        end_time: be > 6,
                        parent_type: 'Item',
                      )],
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      end

      it 'works with multiple lazy fields' do
        query = '{ lazyScalar arrayOfLazyScalars lazyArrayOfScalars }'

        traced_data = trace(query).to_h

        expect(traced_data).to match(
          hash_including(
            start_time: { seconds: expected_trace_start_time, nanos: 0 },
            end_time: { seconds: be > expected_trace_start_time, nanos: 0 },
            duration_ns: be > 0,
            root: hash_including(
              child: [hash_including(
                response_name: 'lazyScalar',
                type: 'String!',
                start_time: 1,
                end_time: be > 1,
                parent_type: 'Query',
              ), hash_including(
                response_name: 'arrayOfLazyScalars',
                type: '[String!]!',
                start_time: 3,
                end_time: be > 3,
                parent_type: 'Query',
              ), hash_including(
                response_name: 'lazyArrayOfScalars',
                type: '[String!]!',
                start_time: 5,
                end_time: be > 5,
                parent_type: 'Query',
              ),],
            ),
          ),
        )
      end
    end

    describe 'indices and errors' do
      let(:schema) do
        item_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Item'

          field :id, String, null: false
          field :name, String, null: false

          def name
            raise GraphQL::ExecutionError, "Can't continue with this query" if object[:id] == '2'

            "Item #{object[:id]}"
          end
        end

        query_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Query'

          field :items, [item_obj], null: false

          def items
            [{ id: '1' }, { id: '2' }]
          end
        end

        Class.new(base_schema) do
          query query_obj
        end
      end

      it 'records index instead of response_name for objects in arrays' do
        expect(trace('{ items { id, name } }')).to eq(
          ApolloFederation::Tracing::Trace.new(
            start_time: { seconds: 1_564_920_001, nanos: 0 },
            end_time: { seconds: expected_end_time, nanos: 0 },
            duration_ns: 11,
            root: {
              child: [{
                response_name: 'items',
                type: '[Item!]!',
                start_time: 1,
                end_time: 2,
                parent_type: 'Query',
                child: [
                  {
                    index: 0,
                    child: [{
                      response_name: 'id',
                      type: 'String!',
                      start_time: 3,
                      end_time: 4,
                      parent_type: 'Item',
                    }, {
                      response_name: 'name',
                      type: 'String!',
                      start_time: 5,
                      end_time: 6,
                      parent_type: 'Item',
                    },],
                  },
                  {
                    index: 1,
                    child: [{
                      response_name: 'id',
                      type: 'String!',
                      start_time: 7,
                      end_time: 8,
                      parent_type: 'Item',
                    }, {
                      response_name: 'name',
                      type: 'String!',
                      start_time: 9,
                      end_time: 10,
                      parent_type: 'Item',
                      error: [{
                        message: "Can't continue with this query",
                        location: [{ line: 1, column: 15 }],
                        json: {
                          message: "Can't continue with this query",
                          locations: [{ line: 1, column: 15 }], path: ['items', 1, 'name'],
                        }.to_json,
                      }],
                    },],
                  },
                ],
              }],
            },
          ),
        )
      end

      context 'when there is a parsing error' do
        it 'properly captures the error' do
          traced_data = trace('{ items { id, name }').to_h

          if Gem::Version.new(GraphQL::VERSION) > Gem::Version.new('2.3.0')
            expected_captured_error = {
              message: 'Expected NAME, actual: (none) ("") at [1, 20]',
              location: [{ line: 1, column: 20 }],
              json: {
                message: 'Expected NAME, actual: (none) ("") at [1, 20]',
                locations: [{ line: 1, column: 20 }],
              }.to_json,
            }
          else
            expected_captured_error = {
              message: 'Unexpected end of document',
              location: [],
              json: {
                message: 'Unexpected end of document',
                locations: [],
              }.to_json,
            }
          end

          expect(traced_data).to match(
            hash_including(
              start_time: { seconds: expected_trace_start_time, nanos: 0 },
              end_time: { seconds: be > expected_trace_start_time, nanos: 0 },
              duration_ns: 1,
              root: hash_including(
                child: [],
                error: [hash_including(expected_captured_error)],
              ),
            ),
          )
        end
      end

      context 'when there is a validation error' do
        it 'properly captures the error' do
          expect(trace('{ nonExistant }')).to eq(
            ApolloFederation::Tracing::Trace.new(
              start_time: { seconds: 1_564_920_001, nanos: 0 },
              end_time: { seconds: expected_end_time, nanos: 0 },
              duration_ns: 1,
              root: {
                child: [],
                error: [{
                  message: "Field 'nonExistant' doesn't exist on type 'Query'",
                  location: [{ line: 1, column: 3 }],
                  json: {
                    message: "Field 'nonExistant' doesn't exist on type 'Query'",
                    locations: [{ line: 1, column: 3 }],
                    path: ['query', 'nonExistant'],
                    extensions: {
                      code: 'undefinedField',
                      typeName: 'Query',
                      fieldName: 'nonExistant',
                    },
                  }.to_json,
                }],
              },
            ),
          )
        end
      end
    end
  end

  if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('1.12.0')
    context 'with the legacy runtime' do
      let(:base_schema) do
        Class.new(GraphQL::Schema) do
          use ApolloFederation::Tracing
        end
      end

      it_behaves_like 'a basic tracer'
    end
  end

  context 'with the interpreter runtime' do
    let(:base_schema) do
      Class.new(GraphQL::Schema) do
        use ApolloFederation::Tracing
        if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('1.12.0')
          use GraphQL::Execution::Interpreter
          use GraphQL::Analysis::AST
        end
      end
    end

    it_behaves_like 'a basic tracer'

    if Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('2.3.0')
      context 'when using trace_with' do
        let(:base_schema) do
          Class.new(GraphQL::Schema) do
            trace_with ApolloFederation::Tracing::Tracer
          end
        end

        it_behaves_like 'a basic tracer'
      end
    end
  end
end
