ImdoneAtomGithubView = require './imdone-atom-github-view'
{$, $$, $$$} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
GithubService = require './github-service'
async = require 'async'
issuePattern = /^.*?github\.com.*?issues.*$/

module.exports =
class Plugin extends Emitter
  @pluginName: "imdone-atom-github"
  ready: false
  constructor: (repo) ->
    super()
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

  getIssueMetaKey: ->
    metaConfig  = @model.repo.getConfig().meta
    metaKeys = (key for key, val of metaConfig when issuePattern.test(val.urlTemplate)) if metaConfig
    @model.metaKey = if (metaKeys && metaKeys.length>0) then metaKeys[0] else
      atom.config.get('imdone-atom-github.defaultIssueMetaKey')

  # Interface ---------------------------------------------------------------------------------------------------------
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
        @view.show()
        console.log "#{user}"
        console.log "#{task.id} clicked"
        console.log "#{issueIds} clicked"
