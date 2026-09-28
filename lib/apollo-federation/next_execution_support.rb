# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  # `resolve_static:` (and GraphQL::Execution::Next generally) doesn't exist on every
  # graphql-ruby version this gem supports, so detect it via a capability the Next-era
  # GraphQL::Schema::Field always defines, rather than assuming a minimum graphql-ruby version.
  # Checking Field#initialize's own parameter list (an earlier version of this check) breaks
  # under graphql-pro, which prepends a `(*args, streamable:, **kwargs)`-shaped `initialize` onto
  # Field -- `instance_method(:initialize)` then reports *that* signature, not the one
  # underneath, so the check silently reads as unsupported. `execution_mode` is a plain
  # `attr_reader`, untouched by that prepend either way. Shared by any field this gem defines
  # directly on the Query type (currently _entities and _service), since those are resolved
  # against the wrapped Query object under classic but the (nil, by default) Query root_value
  # under Next's default :direct_send -- resolve_static is what makes them agree.
  RESOLVE_STATIC_SUPPORTED = GraphQL::Schema::Field.method_defined?(:execution_mode)
end
