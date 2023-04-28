module SpecTypes
  PRODUCTS = [
    {
      type: "Book",
      id: "10",
      title: "Dark Matter",
      pages: 189
    },
    {
      type: "Book",
      id: "20",
      title: "Recursion",
      pages: 189
    },
    {
      type: "Movie",
      id: "30",
      title: "The GraphQL Documentary",
      minutes: 120
    },
    {
      type: "Movie",
      id: "40",
      title: "Arival",
      minutes: 180
    },
  ].freeze

  Book = Struct.new(:id, :type, :title, :pages, keyword_init: true)
  Movie = Struct.new(:id, :type, :title, :minutes, keyword_init: true)

  Admin = Struct.new(:id, :type, :email, keyword_init: true)
  EndUser = Struct.new(:id, :type, :email, keyword_init: true)

  class BaseField < GraphQL::Schema::Field
    include ApolloFederation::Field
  end

  class BaseObject < GraphQL::Schema::Object
    include ApolloFederation::Object
    field_class BaseField
  end

  module BaseInterface
    include GraphQL::Schema::Interface
    include ApolloFederation::Interface

    field_class BaseField
  end

  ## Product interface
  module Product
    include BaseInterface
    graphql_name 'Product'
    key fields: :id
    field :id, ID, null: false
    field :title, String, null: true

    definition_methods do
      def resolve_type(obj, _ctx)
        if obj.is_a?(Book)
          BookType
        elsif obj.is_a?(Movie)
          MovieType
        else
          raise GraphQL::RequiredImplementationMissingError
        end
      end

      def resolve_reference(reference, _context)
        product = PRODUCTS.find { |product| product[:id] == reference[:id] }

        if product[:type] == 'Book'
          book = Book.new(product)
        elsif product[:type] == 'Movie'
          movie = Movie.new(product)
        end
      end
    end
  end

  class BookType < BaseObject
    implements Product

    graphql_name 'Book'
    key fields: :id
    field :id, ID, null: false
    field :title, String, null: true
    field :pages, Integer, null: true

    def self.resolve_reference(reference, _context)
      book = PRODUCTS.find { |product| product[:id] == reference[:id] }

      Book.new(book);
    end
  end

  class MovieType < BaseObject
    implements Product

    graphql_name 'Movie'
    key fields: :id
    field :id, ID, null: false
    field :title, String, null: true
    field :minutes, Integer, null: true

    def self.resolve_reference(reference, _context)
      movie = PRODUCTS.find { |product| product[:id] == reference[:id] }

      Movie.new(movie);
    end
  end

  ## User interface
  module User
    include BaseInterface
    graphql_name 'User'
    key fields: :id
    field :id, ID, null: false
    field :email, String, null: true

    definition_methods do
      def resolve_type(obj, _ctx)
        if obj.is_a?(Admin)
          AdminType
        elsif obj.is_a?(EndUser)
          EndUserType
        else
          raise GraphQL::RequiredImplementationMissingError
        end
      end
    end
  end

  class AdminType < BaseObject
    implements User

    graphql_name 'Admin'
    key fields: :id
    field :id, ID, null: false
    field :email, String, null: true
  end

  class EndUserType < BaseObject
    implements User

    graphql_name 'EndUser'
    key fields: :id
    field :id, ID, null: false
    field :email, String, null: true
  end
end
