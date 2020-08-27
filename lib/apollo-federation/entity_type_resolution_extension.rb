# frozen_string_literal: true

class EntityTypeResolutionExtension < GraphQL::Schema::FieldExtension
  def after_resolve(value:, context:, **_rest)
    value.map do |type, result|
      context.schema.after_lazy(result) do |resolved_value|
        # TODO: This isn't 100% correct: if (for some reason) 2 different resolve_reference calls
        # return the same object, it might not have the right type
        # Right now, apollo-federation just adds a __typename property to the result,
        # but I don't really like the idea of modifying the resolved object
        context[resolved_value] = type
        resolved_value
      end
    end
  end
end
