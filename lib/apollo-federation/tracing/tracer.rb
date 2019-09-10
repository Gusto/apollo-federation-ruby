# frozen_string_literal: true

# Trace events are nested and fire in this order
# for a simple single-field query like `{ foo }`:
#
# <execute_multiplex>
#   <lex></lex>
#   <parse></parse>
#   <validate></validate>
#   <analyze_multiplex>
#     <analyze_query></analyze_query>
#   </analyze_multiplex>
#
#   <execute_query>
#     <execute_field></execute_field>
#   </execute_query>
#
#   <execute_query_lazy>
#
#     # `execute_field_lazy` fires *only* when the field is lazy
#     # (https://graphql-ruby.org/schema/lazy_execution.html)
#     # so if it fires we should overwrite the ending times recorded
#     # in `execute_field` to capture the total execution time.
#
#     <execute_field_lazy></execute_field_lazy>
#
#   </execute_query_lazy>
#
#   # `execute_query_lazy` *always* fires, so it's a
#   # safe place to capture ending times of the full query.
#
# </execute_multiplex>

module ApolloFederation
  module Tracing
    module Tracer
      # store string constants to avoid creating new strings for each call to .trace
      EXECUTE_QUERY = 'execute_query'
      EXECUTE_QUERY_LAZY = 'execute_query_lazy'
      EXECUTE_FIELD = 'execute_field'
      EXECUTE_FIELD_LAZY = 'execute_field_lazy'

      def self.trace(key, data, &block)
        case key
        when EXECUTE_QUERY
          execute_query(data, &block)
        when EXECUTE_QUERY_LAZY
          execute_query_lazy(data, &block)
        when EXECUTE_FIELD
          execute_field(data, &block)
        when EXECUTE_FIELD_LAZY
          execute_field_lazy(data, &block)
        else
          yield
        end
      end

      # Step 1:
      # Create a trace hash on the query context and record start times.
      def self.execute_query(data, &block)
        query = data.fetch(:query)
        return block.call unless query.context && query.context[:tracing_enabled]

        query.context.namespace(ApolloFederation::Tracing::KEY).merge!(
          start_time: Time.now.utc,
          start_time_nanos: Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond),
          node_map: NodeMap.new,
        )

        block.call
      end

      # Step 4:
      # Record end times and merge them into the trace hash.
      def self.execute_query_lazy(data, &block)
        result = block.call

        query = data.fetch(:query)
        return result unless query.context && query.context[:tracing_enabled]

        trace = query.context.namespace(ApolloFederation::Tracing::KEY)

        trace.merge!(
          end_time: Time.now.utc,
          end_time_nanos: Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond),
        )

        result
      end

      # Step 2:
      # * Record start and end times for the field resolver.
      # * Rescue errors so the method doesn't exit early.
      # * Create a trace "node" and attach field details.
      # * Propagate the error (if necessary) so it ends up in the top-level errors array.
      #
      # The values in `data` are different depending on the executor runtime.
      # https://graphql-ruby.org/api-doc/1.9.3/GraphQL/Tracing
      #
      # Nodes are added the NodeMap stored in the trace hash.
      #
      # Errors are added to nodes in `ApolloFederation::Tracing.attach_trace_to_result`
      # because we don't have the error `location` here.
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def self.execute_field(data, &block)
        context = data.fetch(:context) || data.fetch(:query).context
        return block.call unless context && context[:tracing_enabled]

        start_time_nanos = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)

        begin
          result = block.call
        rescue StandardError => e
          error = e
        end

        end_time_nanos = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)

        # interpreter runtime
        if data.include?(:context)
          path = context.path
          field_name = context.field.graphql_name
          field_type = context.field.type.to_s
          parent_type = context.parent_type.graphql_name
        else # legacy runtime
          path = data.fetch(:path)
          field_name = data.fetch(:field).graphql_name
          field_type = data.fetch(:field).type.unwrap.graphql_name
          parent_type = data.fetch(:owner).graphql_name
        end

        trace = context.namespace(ApolloFederation::Tracing::KEY)
        node = trace[:node_map].add(path)

        # original_field_name is set only for aliased fields
        node.original_field_name = field_name if field_name != path.last
        node.type = field_type
        node.parent_type = parent_type
        node.start_time = start_time_nanos - trace[:start_time_nanos]
        node.end_time = end_time_nanos - trace[:start_time_nanos]

        raise error if error

        result
      end

      # Optional Step 3:
      # Overwrite the end times on the trace node if the resolver was lazy.
      def self.execute_field_lazy(data, &block)
        context = data.fetch(:context) || data.fetch(:query).context
        return block.call unless context && context[:tracing_enabled]

        begin
          result = block.call
        rescue StandardError => e
          error = e
        end

        end_time_nanos = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)

        # interpreter runtime
        if data.include?(:context)
          context = data.fetch(:context)
          path = context.path
        else # legacy runtime
          context = data.fetch(:query).context
          path = data.fetch(:path)
        end

        trace = context.namespace(ApolloFederation::Tracing::KEY)

        node = trace[:node_map].node_for_path(path)
        node.end_time = end_time_nanos - trace[:start_time_nanos]

        raise error if error

        result
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end
  end
end
