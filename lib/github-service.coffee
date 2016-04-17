GitHubApi = require 'github'
gitup = require 'git-up'

module.exports =
class GithubService
  constructor: (@model) ->
    @model.service = this
    # #DONE:0 Put github in a github helper issue:3
    @github = new GitHubApi
        version: "3.0.0"
        host: @model.hostname
        pathPrefix: @model.path
        headers:
          "user-agent": "imdone-atom"

  getGithubRepo: (cb) ->
    dirs = (dir for dir in atom.project.getDirectories() when dir.path == @model.repo.path)
    dir = dirs[0] if (dirs && dirs.length > 0)
    # #TODO:0 Save the upstream so we can access issues.  Need to use the github api. issue:1
    atom.project.repositoryForDirectory(dir).then (gitRepo) =>
      return cb(null, null) unless gitRepo
      originURL = gitRepo.getOriginURL()
      console.log "*** Found git repo with origin:%s ***", originURL
      upstream = gitRepo.getUpstreamBranch()
      if upstream
        target = gitRepo.getReferenceTarget(upstream)
        console.log "*** Found upstream branch: %s with target: %s ***", upstream, target
      parsedURL = gitup originURL
      @model.githubRepoUrl = originURL if parsedURL.resource == @model.resourceName
      if @model.githubRepoUrl
        parts = parsedURL.pathname.split '/'
        @model.githubRepoUser = parts[1]
        @model.githubRepo = parts[2].split('.')[0]
      cb(null, @model.githubRepoUrl)

  validateToken: (cb) ->
    @token = atom.config.get 'imdone-atom-github.accessToken'
    return false if @token == 'none'
    @github.authenticate
      type: "oauth",
      token: @token
    @github.user.get {}, (err, data) =>
      return cb err if err
      @model.user = data unless err
      cb err, data

  findIssues: (q, cb) ->
    q += " repo:#{@model.githubRepoUser}/#{@model.githubRepo}"
    @github.search.issues {q:q}, cb

  getIssue: (number, cb) ->
    req =
      user: @model.githubRepoUser
      repo: @model.githubRepo
      number: number
    @github.issues.getRepoIssue req, cb

  newIssue: (title, cb) ->
    req =
      user: @model.githubRepoUser
      repo: @model.githubRepo
      title: title
    @github.issues.create req, cb
