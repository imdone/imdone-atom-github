ImdoneAtomGithubView = require './imdone-atom-github-view'
{$, $$, $$$} = require 'atom-space-pen-views'
{CompositeDisposable, Emitter} = require 'atom'
GitHubApi = require 'github'
async = require 'async'
issuePattern = /^.*?github\.com.*?issues.*$/
githubPattern = /^https:\/\/github\.com\/.*$/
github = new GitHubApi
    version: "3.0.0"
    headers:
      "user-agent": "imdone-atom"

class Plugin extends Emitter
  @pluginName: "imdone-atom-github"
  @defaultIssueMetaKey: atom.config.get('imdone-atom-github.issueMetaKey')

  constructor: (@repo) ->
    super()
    @getIssueMetaKey()
    async.parallel [
      (cb) =>
        @getGithubRepo(cb)
      (cb) =>
        @validateToken(cb)
    ], (err, result) =>
      @view = new ImdoneAtomGithubView
      @emit('ready') if !err && @githubRepoUrl

  getIssueMetaKey: ->
    metaConfig  = @repo.getConfig().meta
    metaKeys = (key for key, val of metaConfig when issuePattern.test(val.urlTemplate)) if metaConfig
    @metaKey = if metaKeys && metaKeys.length>0 then metaKeys[0] else @defaultIssueMetaKey

  validateToken: (cb) ->
    @token = atom.config.get 'imdone-atom-github.accessToken'
    return false if @token == 'none'
    github.authenticate
      type: "oauth",
      token: @token
    github.user.get {}, (err, data) =>
      @lastError = err if err
      @user = data unless err
      cb err, data

  getIssueId: (task) ->
    metaData = task.getMetaData()
    metaData[@metaKey] if (@metaKey && metaData)

  getGithubRepo: (cb) ->
    dirs = (dir for dir in atom.project.getDirectories() when dir.path == @repo.path)
    dir = dirs[0] if (dirs && dirs.length > 0)
    atom.project.repositoryForDirectory(dir).then (gitRepo) =>
      originURL = gitRepo.getOriginURL()
      @githubRepoUrl = originURL if gitRepo && githubPattern.test originURL
      cb null, @githubRepoUrl

  # Interface
  getView: ->
    @view
  taskButton: (id) ->
    return unless @repo && @githubRepoUrl
    task = @repo.getTask(id)
    issueId = @getIssueId task
    getUser = => return @user
    title = if issueId then "Change or add another github issue to this task" else "Show this to your team in a github issue"
    $btn = $$ ->
      @a href: '#', title: title, =>
        @span class:"icon icon-octoface"
    $btn.on 'click', (e) =>
      user = getUser()
      if user
        console.log "#{user}"
        console.log "#{task.id} clicked"
        console.log "#{issueId} clicked"

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
