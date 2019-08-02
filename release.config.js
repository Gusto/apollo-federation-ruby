module.exports = {
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    '@semantic-release/changelog',
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
    [
      '@semantic-release/git',
      {
        // eslint-disable-next-line no-template-curly-in-string
        message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}',
        assets: ['CHANGELOG.md', 'Gemfile.lock', 'lib/apollo-federation/version.rb'],
      },
    ],
    // '@semantic-release/github',
  ],
};
