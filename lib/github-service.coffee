GitHubApi = require 'github'
url = require 'url'
githubPattern = /^https:\/\/github\.com\/.*$/

module.exports =
class GithubService
  # #DONE:0 Put github in a github helper
  github: new GitHubApi
      version: "3.0.0"
      headers:
        "user-agent": "imdone-atom"
  constructor: (@model) ->
    @model.service = this

  getGithubRepo: (cb) ->
    dirs = (dir for dir in atom.project.getDirectories() when dir.path == @model.repo.path)
    dir = dirs[0] if (dirs && dirs.length > 0)
    # #TODO:0 Save the upstream so we can access issues issue:1
    atom.project.repositoryForDirectory(dir).then (gitRepo) =>
      originURL = gitRepo.getOriginURL()
      @model.githubRepoUrl = originURL if gitRepo && githubPattern.test originURL
      if @model.githubRepoUrl
        parts = url.parse(@model.githubRepoUrl).path.split '/'
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
