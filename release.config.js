module.exports = {
  plugins: [
    '@semantic-release/commit-analyzer',
    // '@semantic-release/release-notes-generator',
    [
      '@semantic-release/exec',
      {
        // verifyConditionsCmd: './verify.sh',
        // eslint-disable-next-line no-template-curly-in-string
        prepareCmd: 'ruby bin/prepare.rb ${nextRelease.version}',
        publishCmd:
          // eslint-disable-next-line no-template-curly-in-string
          'ruby bin/publish.rb ${nextRelease.version}',
      },
    ],
    // '@semantic-release/github',
  ],
};
