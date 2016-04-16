Plugin = require './plugin'
module.exports = ImdoneAtomGithub =
  config:
    gitHubEnterpriseHost:
      description: 'If you want to use imdone-atom with GitHub Enterprise, enter the hostname here.'
      type: 'string'
      default: ''
    defaultIssueMetaKey:
      description: 'The default meta key for github issues'
      type: 'string'
      default: 'issue'
    accessToken:
      description: 'Github personal access token. [Get one](https://github.com/settings/tokens/new?description=imdone-atom)'
      type: 'string'
      default: 'none'

  deactivate: ->
    @imdone.removePlugin Plugin if (@imdone && @imdone.removePlugin)

  consumeImdone: (@imdone) ->
    @imdone.addPlugin(Plugin) if (@imdone && @imdone.addPlugin)
