# frozen_string_literal: true

class EntityTypeResolutionExtension < GraphQL::Schema::FieldExtension
  def after_resolve(value:, context:, **_rest)
    synced_value =
      value.map do |type, result|
        [type, context.query.schema.sync_lazy(result)]
      end

    # TODO: This isn't 100% correct: if (for some reason) 2 different resolve_reference calls
    # return the same object, it might not have the right type
    # Right now, apollo-federation just adds a __typename property to the result,
    # but I don't really like the idea of modifying the resolved object
    synced_value.each { |type, result| context[result] = type }

    synced_value.map { |_, result| result }
  end
end
