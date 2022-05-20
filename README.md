# apollo-federation

[![CircleCI](https://circleci.com/gh/Gusto/apollo-federation-ruby/tree/main.svg?style=svg)](https://circleci.com/gh/Gusto/apollo-federation-ruby/tree/main)

This gem extends the [GraphQL Ruby](http://graphql-ruby.org/) gem to add support for creating an [Apollo Federation](https://www.apollographql.com/docs/apollo-server/federation/introduction/) schema.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apollo-federation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install apollo-federation

## Getting Started

Include the `ApolloFederation::Field` module in your base field class:

```ruby
require 'apollo-federation'

class BaseField < GraphQL::Schema::Field
  include ApolloFederation::Field
end
```

Include the `ApolloFederation::Object` module in your base object class:

```ruby
class BaseObject < GraphQL::Schema::Object
  include ApolloFederation::Object

  field_class BaseField
end
```

Include the `ApolloFederation::Interface` module in your base interface module:

```ruby
module BaseInterface
  include GraphQL::Schema::Interface
  include ApolloFederation::Interface

  field_class BaseField
end
```

Finally, include the `ApolloFederation::Schema` module in your schema:

```ruby
class MySchema < GraphQL::Schema
  include ApolloFederation::Schema
end
```

## Example

The [`example`](./example/) folder contains a Ruby implementation of Apollo's [`federation-demo`](https://github.com/apollographql/federation-demo). To run it locally, install the Ruby dependencies:

    $ bundle

Install the Node dependencies:

    $ yarn

Start all of the services:

    $ yarn start-services

Start the gateway:

    $ yarn start-gateway

This will start up the gateway and serve it at http://localhost:5000.

## Usage

The API is designed to mimic the API of [Apollo's federation library](https://www.apollographql.com/docs/apollo-server/federation/introduction/). It's best to read and understand the way federation works, in general, before attempting to use this library.

### Extending a type

[Apollo documentation](https://www.apollographql.com/docs/apollo-server/federation/core-concepts/#extending-external-types)

Call `extend_type` within your class definition:

```ruby
class User < BaseObject
  extend_type
end
```

### The `@key` directive

[Apollo documentation](https://www.apollographql.com/docs/apollo-server/federation/core-concepts/#entities-and-keys)

Call `key` within your class definition:

```ruby
class User < BaseObject
  key fields: :id
end
```

Compound keys are also supported:

```ruby
class User < BaseObject
  key fields: [:id, { organization: :id }]
end
```

See [field set syntax](#field-set-syntax) for more details on the format of the `fields` option.

### The `@external` directive

[Apollo documentation](https://www.apollographql.com/docs/apollo-server/federation/core-concepts/#referencing-external-types)

Pass the `external: true` option to your field definition:

```ruby
class User < BaseObject
  field :id, ID, null: false, external: true
end
```

### The `@requires` directive

[Apollo documentation](https://www.apollographql.com/docs/apollo-server/federation/advanced-features/#computed-fields)

Pass the `requires:` option to your field definition:

```ruby
class Product < BaseObject
  field :price, Int, null: true, external: true
  field :weight, Int, null: true, external: true
  field :shipping_estimate, Int, null: true, requires: { fields: [:price, :weight] }
end
```

See [field set syntax](#field-set-syntax) for more details on the format of the `fields` option.

### The `@provides` directive

[Apollo documentation](https://www.apollographql.com/docs/apollo-server/federation/advanced-features/#using-denormalized-data)

Pass the `provides:` option to your field definition:

```ruby
class Review < BaseObject
  field :author, 'User', null: true, provides: { fields: :username }
end
```
See [field set syntax](#field-set-syntax) for more details on the format of the `fields` option.

### Field set syntax

Field sets can be either strings encoded with the Apollo Field Set [syntax]((https://www.apollographql.com/docs/apollo-server/federation/federation-spec/#scalar-_fieldset)) or arrays, hashes and snake case symbols that follow the graphql-ruby conventions:

```ruby
# Equivalent to the "organizationId" field set
:organization_id

# Equivalent to the "price weight" field set
[:price, :weight]

# Equivalent to the "id organization { id }" field set
[:id, { organization: :id }]
```

### Reference resolvers

[Apollo documentation](https://www.apollographql.com/docs/apollo-server/api/apollo-federation/#__resolvereference)

Define a `resolve_reference` class method on your object. The method will be passed the reference from another service and the context for the query.

```ruby
class User < BaseObject
  def self.resolve_reference(reference, context)
    USERS.find { |user| user[:id] == reference[:id] }
  end
end
```

### Tracing

To support [federated tracing](https://www.apollographql.com/docs/apollo-server/federation/metrics/):

1. Add `use ApolloFederation::Tracing` to your schema class.
2. Change your controller to add `tracing_enabled: true` to the execution context based on the presence of the "include trace" header:
    ```ruby
    def execute
      # ...
      context = {
        tracing_enabled: ApolloFederation::Tracing.should_add_traces(request.headers)
      }
      # ...
   ```

## Exporting the Federated SDL

When using tools like [rover](https://www.apollographql.com/docs/rover/) for schema validation, etc., add a Rake task that prints the Federated SDL to a file:

```rb
namespace :graphql do
  namespace :federation do
    task :dump do
      File.write("schema.graphql", MySchema.federation_sdl)
    end
  end
end
```

Example validation check with Rover and Apollo Studio:

```sh
bin/rake graphql:federation:dump
rover subgraph check mygraph@current --name mysubgraph --schema schema.graphql
```

## Testing the federated schema

This library does not include any testing helpers currently. A federated service receives subgraph queries from the Apollo Gateway via the `_entities` field and that can be tested in a request spec.

With Apollo Gateway setup to hit your service locally or by using existing query logs, you can retrieve the generated `_entities` queries.

For example, if you have a blog service that exposes posts by a given author, the query received by the service might look like this.

```graphql
query($representations: [_Any!]!) {
  _entities(representations: $representations) {
    ... on BlogPost {
      id
      title
      body
    }
  }
}
```

Where `$representations` is an array of entity references from the gateway.

```JSON
{
  "representations": [
    {
      "__typename": "BlogPost",
      "id": 1
    },
    {
      "__typename": "BlogPost",
      "id": 2
    }
  ]
}
```

Using RSpec as an example, a request spec for this query.

```ruby
it "resolves the blog post entities" do
  blog_post = BlogPost.create!(attributes)

  query = <<~GRAPHQL
    query($representations: [_Any!]!) {
      _entities(representations: $representations) {
        ... on BlogPost {
          id
          title
          body
        }
      }
    }
  GRAPHQL

  variables = { representations: [{ __typename: "BlogPost", id: blog_post.id }] }

  result = Schema.execute(query, variables: variables)

  expect(result.dig("data", "_entities", 0, "id")).to eq(blog_post.id)
end
```

See discussion at [#74](https://github.com/Gusto/apollo-federation-ruby/issues/74) and an [internal spec that resolves \_entities](https://github.com/Gusto/apollo-federation-ruby/blob/1d3baf4f8efcd02e7bf5bc7e3fee5b4fb963cd25/spec/apollo-federation/entities_field_spec.rb#L164) for more details.

## Known Issues and Limitations

- For GraphQL older than 1.12, the interpreter runtime has to be used.
- Does not add directives to the output of `Schema.to_definition`. Since `graphql-ruby` doesn't natively support schema directives, the
  directives will only be visible to the [Apollo Gateway](https://www.apollographql.com/docs/apollo-server/api/apollo-gateway/) through the `Query._service` field (see the [Apollo Federation specification](https://www.apollographql.com/docs/apollo-server/federation/federation-spec/)) or via [`Schema#federation_sdl`](https://github.com/Gusto/apollo-federation-ruby/blob/1d3baf4f8efcd02e7bf5bc7e3fee5b4fb963cd25/lib/apollo-federation/schema.rb#L19) as explained above.

## Maintainers

- [Rylan Collins](https://github.com/rylanc)
- [Noa Elad](https://github.com/noaelad)
