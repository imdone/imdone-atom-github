{Emitter} = require 'atom'
module.exports =
class Plugin extends Emitter
  @pluginName: require('../package.json').name
  ready: false
  constructor: (repo, @imdoneView) ->
    super()
    ImdoneAtomGithubView = require './imdone-atom-github-view'
    GithubService = require './github-service'
    async = require 'async'
    @model =
      user: null
      task: null
      repo: repo
      githubRepoUrl: null
      metaKey: null
      getIssueIds: (task) ->
        task = @task unless task
        return null unless task
        metaData = task.getMetaData()
        metaData[@metaKey] if (@metaKey && metaData)

    # GitHub Enterprise Support https://enterprise.github.com/help/articles/using-the-api
    if atom.config.get("imdone-atom-github.gitHubEnterpriseHost")
        @model.hostname = atom.config.get("imdone-atom-github.gitHubEnterpriseHost")
        @model.resourceName = @model.hostname
        @model.path = '/api/v3'
    else
        @model.hostname = 'api.github.com'
        @model.resourceName = 'github.com'
        @model.path = '/'

    @getIssueMetaKey()
    @githubService = new GithubService @model
    async.parallel [
      (cb) =>
        @githubService.getGithubRepo(cb)
      (cb) =>
        @githubService.validateToken(cb)
    ], (err, result) =>
      @view = new ImdoneAtomGithubView @model
      if !err && @model.githubRepoUrl
        @ready = true
        @emit 'ready'

    @imdoneView.on 'board.update', =>
      return unless @view && @view.is ':visible'
      @imdoneView.selectTask @model.task.id

  getIssueMetaKey: ->
    issuePattern = /^.*?github\.com.*?issues.*$/
    metaConfig  = @model.repo.getConfig().meta
    metaKeys = (key for key, val of metaConfig when issuePattern.test(val.urlTemplate)) if metaConfig
    @model.metaKey = if (metaKeys && metaKeys.length>0) then metaKeys[0] else
      atom.config.get('imdone-atom-github.defaultIssueMetaKey')
      # DOING:0 Add issueMeta to imdone config and save issue:2

  # Interface ---------------------------------------------------------------------------------------------------------
  isReady: ->
    @ready
  getView: ->
    @view
  taskButton: (id) ->
    {$, $$, $$$} = require 'atom-space-pen-views'
    return unless @model.repo && @model.githubRepoUrl
    task = @model.repo.getTask(id)
    issueIds = @model.getIssueIds(task)
    getUser = => return @model.user
    title = "Update linked github issues"
    $btn = $$ ->
      @a href: '#', title: title, =>
        @span class:"icon icon-octoface"
    $btn.on 'click', (e) =>
      $(e.target).find('.task')
      user = getUser()
      if user
        @model.task = task
        @imdoneView.showPlugin @
        @imdoneView.selectTask id
        @view.show issueIds
