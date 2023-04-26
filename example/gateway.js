const { ApolloServer } = require('@apollo/server');
const { ApolloGateway, IntrospectAndCompose } = require('@apollo/gateway');
const { startStandaloneServer } = require('@apollo/server/standalone');

const gateway = new ApolloGateway({
  supergraphSdl: new IntrospectAndCompose({
    subgraphs: [
      { name: 'accounts', url: 'http://localhost:5001/graphql' },
      { name: 'reviews', url: 'http://localhost:5002/graphql' },
      { name: 'products', url: 'http://localhost:5003/graphql' },
      { name: 'inventory', url: 'http://localhost:5004/graphql' },
    ],
  }),
  debug: true,
});

(async () => {
  const server = new ApolloServer({ gateway });

  const { url } = await startStandaloneServer(server, {
    listen: { port: 5000 },
  });

  console.log(`🚀  Server ready at: ${url}`);
})();
