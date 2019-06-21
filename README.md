# apollo-federation

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
  extend ApolloFederation::Object

  field_class BaseField
end
```

Finally, extend your schema with the `ApolloFederation::Schema` module:

```ruby
class MySchema < GraphQL::Schema
  extend ApolloFederation::Schema
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

## Known Limitations and Issues
 - Currently only works with class-based schemas
 - Does add directives to the output of `Schema.to_definition`. Since `graphql-ruby` doesn't natively support schema directives, the directives will only be visible to the [Apollo Gateway](https://www.apollographql.com/docs/apollo-server/api/apollo-gateway/) through the `Query._service` field (see the [Apollo Federation specification](https://www.apollographql.com/docs/apollo-server/federation/federation-spec/))
