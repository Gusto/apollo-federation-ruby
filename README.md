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

Include the `ApolloFederation::Object` base object class:

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

See the `examples` folder for a Ruby implementation of Apollo's [`federation-demo`](https://github.com/apollographql/federation-demo).

## Usage

The API is designed to mimic the API of Apollo's [`@apollo/federation`](https://www.apollographql.com/docs/apollo-server/api/apollo-federation/) library. It's best to read and understand the way federation works, in general, before attempting to use this library.

### Extending a type
Call `extend_type` within your class definition:

```ruby
class User < BaseObject
  extend_type
end
```

### The `@key` directive
Call `key` within your class definition:

```ruby
class User < BaseObject
  key fields: 'id'
end
```

### The `@external` directive
Pass the `external: true` option to your field definition:

```ruby
class User < BaseObject
  field :id, ID, null: false, external: true
end
```

### The `@requires` directive
Pass the `requires:` option to your field definition:

```ruby
class User < BaseObject
  field :first_name, String, null: false
  field :last_name, String, null: false
  field :full_name, String, null: false, requires: { fields: 'firstName lastName' }
end
```

### The `@provides` directive
Pass the `provides:` option to your field definition:

```ruby
class Review < BaseObject
  field :author, 'User', null: true, provides: { fields: 'username' }
end
```

## Reference resolvers
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
 - Does not modify the output of `Schema.to_definition`. The enhanced definition (with directives) will only be visible to the [Apollo Gateway](https://www.apollographql.com/docs/apollo-server/api/apollo-gateway/) through the `Query._service` field (see the [Apollo Federation specification](https://www.apollographql.com/docs/apollo-server/federation/federation-spec/))
