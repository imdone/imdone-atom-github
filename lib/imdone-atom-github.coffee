ImdoneAtomGithubView = require './imdone-atom-github-view'
{$, $$, $$$} = require 'atom-space-pen-views'
{CompositeDisposable, Emitter} = require 'atom'
GitHubApi = require 'github'
async = require 'async'
issuePattern = /^.*?github\.com.*?issues.*$/
githubPattern = /^https:\/\/github\.com\/.*$/
# TODO:0 Put github in a github helper
github = new GitHubApi
    version: "3.0.0"
    headers:
      "user-agent": "imdone-atom"

class Plugin extends Emitter
  @pluginName: "imdone-atom-github"
  defaultIssueMetaKey: atom.config.get('imdone-atom-github.issueMetaKey')
  ready: false
  model:
    user: null
    task: null
    repo: null
    githubRepoUrl: null
    metaKey: null
    getIssueIds: (task) ->
      task = @task unless task
      metaData = task.getMetaData()
      metaData[@metaKey] if (@metaKey && metaData)

  constructor: (repo) ->
    super()
    @model.repo = repo
    @getIssueMetaKey()
    async.parallel [
      (cb) =>
        @getGithubRepo(cb)
      (cb) =>
        @validateToken(cb)
    ], (err, result) =>
      @view = new ImdoneAtomGithubView @model
      if !err && @model.githubRepoUrl
        @ready = true
        @emit 'ready'

  getIssueMetaKey: ->
    metaConfig  = @model.repo.getConfig().meta
    metaKeys = (key for key, val of metaConfig when issuePattern.test(val.urlTemplate)) if metaConfig
    @model.metaKey = if metaKeys && metaKeys.length>0 then metaKeys[0] else @defaultIssueMetaKey

  validateToken: (cb) ->
    @token = atom.config.get 'imdone-atom-github.accessToken'
    return false if @token == 'none'
    github.authenticate
      type: "oauth",
      token: @token
    github.user.get {}, (err, data) =>
      @lastError = err if err
      @model.user = data unless err
      cb err, data

  getGithubRepo: (cb) ->
    dirs = (dir for dir in atom.project.getDirectories() when dir.path == @model.repo.path)
    dir = dirs[0] if (dirs && dirs.length > 0)
    atom.project.repositoryForDirectory(dir).then (gitRepo) =>
      originURL = gitRepo.getOriginURL()
      @model.githubRepoUrl = originURL if gitRepo && githubPattern.test originURL
      cb(null, @model.githubRepoUrl)

  # Interface
  isReady: ->
    @ready
  getView: ->
    @view
  taskButton: (id) ->
    return unless @model.repo && @model.githubRepoUrl
    task = @model.repo.getTask(id)
    issueIds = @model.getIssueIds(task)
    getUser = => return @model.user
    title = if issueIds then "Change or add another github issue to this task" else "Show this to your team in a github issue"
    $btn = $$ ->
      @a href: '#', title: title, =>
        @span class:"icon icon-octoface"
    $btn.on 'click', (e) =>
      user = getUser()
      if user
        @model.task = task
        @emit 'view.show'
        console.log "#{user}"
        console.log "#{task.id} clicked"
        console.log "#{issueIds} clicked"

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

  deactivate: ->
    @imdoneAtomGithubView.destroy()
    @imdone.removePlugin Plugin if (@imdone && @imdone.removePlugin)

  consumeImdone: (@imdone) ->
    @imdone.addPlugin(Plugin) if (@imdone && @imdone.addPlugin)
