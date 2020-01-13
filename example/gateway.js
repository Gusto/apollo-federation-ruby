const { ApolloServer } = require('apollo-server');
const { ApolloGateway } = require('@apollo/gateway');

const gateway = new ApolloGateway({
  serviceList: [
    { name: 'accounts', url: 'http://localhost:50001/graphql' },
    { name: 'reviews', url: 'http://localhost:50002/graphql' },
    { name: 'products', url: 'http://localhost:50003/graphql' },
    { name: 'inventory', url: 'http://localhost:50004/graphql' },
  ],
  debug: true,
});

(async () => {
  const { schema, executor } = await gateway.load();

  const server = new ApolloServer({ schema, executor });

  server.listen({ port: 50000 }).then(({ url }) => {
    console.log(`🚀 Server ready at ${url}`);
  });
})();
