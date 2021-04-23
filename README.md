# apollo-federation

[![CircleCI](https://circleci.com/gh/Gusto/apollo-federation-ruby/tree/master.svg?style=svg)](https://circleci.com/gh/Gusto/apollo-federation-ruby/tree/master)

This gem extends the [GraphQL Ruby](http://graphql-ruby.org/) gem to add support for creating an [Apollo Federation](https://www.apollographql.com/docs/apollo-server/federation/introduction/) schema.

## DISCLAIMER

This gem is still in a beta stage and may have some bugs or incompatibilities. See the [Known Issues and Limitations](#known-issues-and-limitations) below. If you run into any problems, please [file an issue](https://github.com/Gusto/apollo-federation-ruby/issues).

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
  key fields: 'id'
end
```

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
  field :shipping_estimate, Int, null: true, requires: { fields: "price weight"}
end
```

### The `@provides` directive
[Apollo documentation](https://www.apollographql.com/docs/apollo-server/federation/advanced-features/#using-denormalized-data)

Pass the `provides:` option to your field definition:

```ruby
class Review < BaseObject
  field :author, 'User', null: true, provides: { fields: 'username' }
end
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
        tracing_enabled: ApolloFederation::Tracing.should_add_traces(headers)
      }
      # ...
    end
    ```

## Exporting the Federated SDL

When using tools like [rover](https://www.apollographql.com/docs/rover/) for schema validation, etc., add a Rake task that prints the Federated SDL to a file: 

```rb
namespace :graphql do
  namespace :federation do
    task :dump do
      File.open "schema.graphql", "w+" do |f|
        f << MySchema.federation_sdl
      end
    end
  end
end
```

(This task mirrors the [`graphq:schema:dump` task](https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/rake_task.rb) included in graphql-ruby.)

Example validation check with Rover and Apollo Studio:

```sh
bin/rake graphql:federation:dump
rover subgraph check mygraph@current --name mysubgraph --schema schema.graphql
```

## Known Issues and Limitations
 - Only works with class-based schemas, the legacy `.define` API will not be supported
 - Does not add directives to the output of `Schema.to_definition`. Since `graphql-ruby` doesn't natively support schema directives, the directives will only be visible to the [Apollo Gateway](https://www.apollographql.com/docs/apollo-server/api/apollo-gateway/) through the `Query._service` field (see the [Apollo Federation specification](https://www.apollographql.com/docs/apollo-server/federation/federation-spec/)) or via [`Schema#federation_sdl`](https://github.com/Gusto/apollo-federation-ruby/blob/1d3baf4f8efcd02e7bf5bc7e3fee5b4fb963cd25/lib/apollo-federation/schema.rb#L19) as explained above.

## Maintainers
 * [Rylan Collins](https://github.com/rylanc)
 * [Noa Elad](https://github.com/noaelad)
