ImdoneAtomGithubView = require './imdone-atom-github-view'
{$, $$, $$$, ScrollView} = require 'atom-space-pen-views'
{CompositeDisposable, Emitter} = require 'atom'
issuePattern = /^.*?github\.com.*?issues.*$/
githubPattern = /^https:\/\/github\.com\/.*$/

class Plugin extends Emitter
  @pluginName: "imdone-atom-github"

  constructor: (@repo) ->
    super()
    metaConfig  = @repo.getConfig().meta
    metaKeys = (key for key, val of metaConfig when issuePattern.test(val.urlTemplate)) if metaConfig
    @metaKey = if metaKeys && metaKeys.length>0 then metaKeys[0] else atom.config.get('issueMetaKey')
    @getGithubRepo()

  taskButton: (id) ->
    return unless @repo && @githubRepoUrl
    task = @repo.getTask(id)
    issueId = @getIssueId task
    title = if issueId then "Change or add another github issue to this task" else "Show this to your team in a github issue"
    $btn = $$ ->
      @a href: '#', title: title, =>
        @span class:"icon icon-octoface"
    $btn.on 'click', (e) =>
      console.log "#{task.id} clicked"
      console.log "#{issueId} clicked"

  getIssueId: (task) ->
    metaData = task.getMetaData()
    metaData[@metaKey] if (@metaKey && metaData)

  getGithubRepo: ->
    dirs = (dir for dir in atom.project.getDirectories() when dir.path == @repo.path)
    dir = dirs[0] if (dirs && dirs.length > 0)
    atom.project.repositoryForDirectory(dir).then (gitRepo) =>
      originURL = gitRepo.getOriginURL()
      @githubRepoUrl = originURL if gitRepo && githubPattern.test originURL
      @emit('ready') if @githubRepoUrl

module.exports = ImdoneAtomGithub =
  imdoneAtomGithubView: null
  config:
    defaultIssueMetaKey:
      description: 'The meta key for github issues'
      type: 'string'
      default: 'ghiss'
    accessToken:
      description: 'Github personal access token. [Get one](https://github.com/settings/tokens/new?description=imdone-atom)'
      type: 'string'
      default: 'none'

  subscriptions: null
  activate: (state) ->
    @imdoneAtomGithubView = new ImdoneAtomGithubView(state.imdoneAtomGithubViewState)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

  deactivate: ->
    @subscriptions.dispose()
    @imdoneAtomGithubView.destroy()
    @imdone.removePlugin Plugin if (@imdone && @imdone.removePlugin)

  serialize: ->
    imdoneAtomGithubViewState: @imdoneAtomGithubView.serialize()

  consumeImdone: (@imdone) ->
    @imdone.addPlugin(Plugin) if (@imdone && @imdone.addPlugin)
