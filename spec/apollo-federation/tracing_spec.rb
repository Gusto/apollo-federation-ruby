# frozen_string_literal: true

require 'spec_helper'
require 'apollo-federation'

RSpec.describe ApolloFederation::Tracing do
  RSpec.shared_examples 'a basic tracer' do
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
        described_class.attach_trace_to_result(result)
        expect(result[:extensions]).to be_nil
      end

      it 'adds the extensions.ftv1 when the context has tracing_enabled: true' do
        result = schema.execute('{ test }', context: { tracing_enabled: true })
        described_class.attach_trace_to_result(result)
        expect(result[:extensions][:ftv1]).not_to be_nil
      end

      it 'adds debugging info when the context has debug_tracing: true' do
        result = schema.execute('{ test }', context: { tracing_enabled: true, debug_tracing: true })
        described_class.attach_trace_to_result(result)
        expect(result[:extensions][:ftv1_debug]).not_to be_nil
      end
    end

    def trace(query)
      result = schema.execute(query, context: { tracing_enabled: true })
      described_class.attach_trace_to_result(result)

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
        expect(trace(query)).to eq(ApolloFederation::Tracing::Trace.new(
                                     start_time: { seconds: 1_564_920_001, nanos: 0 },
                                     end_time: { seconds: 1_564_920_002, nanos: 0 },
                                     duration_ns: 13,
                                     root: {
                                       child: [{
                                         response_name: 'parent',
                                         type: 'Parent!',
                                         start_time: 1,
                                         end_time: 2,
                                         parent_type: 'Query',
                                         child: [{
                                           response_name: 'id',
                                           type: 'String!',
                                           start_time: 3,
                                           end_time: 4,
                                           parent_type: 'Parent',
                                         }, {
                                           response_name: 'child',
                                           type: 'Child!',
                                           start_time: 5,
                                           end_time: 6,
                                           parent_type: 'Parent',
                                           child: [{
                                             response_name: 'id',
                                             type: 'String!',
                                             start_time: 7,
                                             end_time: 8,
                                             parent_type: 'Child',
                                           }, {
                                             response_name: 'grandchild',
                                             type: 'Grandchild!',
                                             start_time: 9,
                                             end_time: 10,
                                             parent_type: 'Child',
                                             child: [{
                                               response_name: 'id',
                                               type: 'String!',
                                               start_time: 11,
                                               end_time: 12,
                                               parent_type: 'Grandchild',
                                             }],
                                           },],
                                         },],
                                       }],
                                     },
                                   ))
      end

      it 'works for scalar arrays' do
        expect(trace('{ strings }')).to eq ApolloFederation::Tracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
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

    class Lazy
      def initialize(value = 'lazy_value')
        # puts "Lazy.new(#{value})"
        @value = value
      end

      def value
        puts "lazy_method: #{@value}"
        @value
      end
    end

    describe 'lazy values' do
      let(:schema) do
        item_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Item'

          field :id, String, null: false

          # def id
          #   # binding.pry
          #   Lazy.new(object[:id])
          # end
        end

        query_obj = Class.new(GraphQL::Schema::Object) do
          graphql_name 'Query'

          field :test, String, null: false
          field :array_of_lazy_scalars, [String], null: false
          field :lazy_array_of_scalars, [String], null: false
          field :array_of_objects, [item_obj], null: false

          def test
            Lazy.new
          end

          def array_of_lazy_scalars
            [Lazy.new('hi'), Lazy.new('bye')]
          end

          def lazy_array_of_scalars
            Lazy.new(['hi', 'bye'])
          end

          def array_of_objects
            [Lazy.new(id: '123'), Lazy.new(id: '456')]
          end
        end

        Class.new(base_schema) do
          query query_obj
          lazy_resolve(Lazy, :value)
        end
      end

      it 'works with lazy values' do
        expect(trace('{ test }')).to eq ApolloFederation::Tracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          duration_ns: 4,
          root: {
            child: [{
              response_name: 'test',
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

      # FIXME: Ok, so here's the issue:
      # Tracing is broken when a field resolves an array of lazy values (scalars or objects).
      # The reason it isn't broken in ZP is that the version it has (1.0.3) resolves the _entities
      # field in a way that makes it look like it isn't an array of lazy objects. So, the tracing is
      # broken, but you should still try to figure out how the _entities resolver works differently
      it 'works with array of lazy scalars' do
        expect(trace('{ arrayOfLazyScalars }')).to eq ApolloFederation::Tracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          # The old runtime and the interpreter handle arrays of lazy objects differently.
          # The old runtime doesn't trigger the `execute_field_lazy` tracer event, so we have to
          # use the (inaccurate) end times from the `execute_field` event.
          duration_ns: schema.interpreter? ? 5 : 3,
          root: {
            child: [{
              response_name: 'arrayOfLazyScalars',
              type: '[String!]!',
              start_time: 1,
              end_time: schema.interpreter? ? 4 : 2,
              parent_type: 'Query',
            }],
          },
        )
      end

      it 'works with a lazy array of scalars' do
        expect(trace('{ lazyArrayOfScalars }')).to eq ApolloFederation::Tracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
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

      it 'works with array of lazy objects' do
        expect(trace('{ arrayOfObjects { id } }')).to eq ApolloFederation::Tracing::Trace.new(
          start_time: { seconds: 1_564_920_001, nanos: 0 },
          end_time: { seconds: 1_564_920_002, nanos: 0 },
          duration_ns: schema.interpreter? ? 9 : 7,
          root: {
            child: [{
              response_name: 'arrayOfObjects',
              type: '[Item!]!',
              start_time: 1,
              end_time: schema.interpreter? ? 6 : 2,
              parent_type: 'Query',
              child: [
                {
                  index: 0,
                  child: [{
                    response_name: 'id',
                    type: 'String!',
                    start_time: schema.interpreter? ? 4 : 3,
                    end_time: schema.interpreter? ? 5 : 4,
                    parent_type: 'Item',
                  }],
                },
                {
                  index: 1,
                  child: [{
                    response_name: 'id',
                    type: 'String!',
                    start_time: schema.interpreter? ? 7 : 5,
                    end_time: schema.interpreter? ? 8 : 6,
                    parent_type: 'Item',
                  }],
                },
              ],
            }],
          },
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
            end_time: { seconds: 1_564_920_002, nanos: 0 },
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
    end
  end

  context 'with the legacy runtime' do
    let(:base_schema) do
      Class.new(GraphQL::Schema) do
        use ApolloFederation::Tracing
      end
    end

    it_behaves_like 'a basic tracer'
  end

  context 'with the new interpreter' do
    let(:base_schema) do
      Class.new(GraphQL::Schema) do
        use ApolloFederation::Tracing
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
      end
    end

    it_behaves_like 'a basic tracer'
  end
end
