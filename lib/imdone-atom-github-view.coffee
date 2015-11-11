{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
async = require 'async'
module.exports =
class ImdoneAtomGithubView extends View
  @defaultSearch: "is:open is:issue"
  @content: ->
    @div id:"imdone-atom-github-view", =>
      @div outlet:'findIssues', class: 'block find-issues', =>
        @div class: 'input-med', =>
          @subview 'findIssuesField', new TextEditorView(mini: true, placeholderText: @defaultSearch)
        @div class:'btn-group btn-group-find', =>
          @button click: 'doFind', class:'btn btn-primary inline-block-tight', =>
            @span class:'icon icon-mark-github', 'Find Issues'
      @div class:'issues-container', =>
        @div outlet: 'searchResult', class: 'issue-list search-result'
        @div outlet: 'relatedIssues', class: 'issue-list related-issues'

  constructor: (@model) ->
    super
    @handleEvents()

  handleEvents: ->
    @findIssuesField.on 'keyup', (e) =>
      code = e.keyCode || e.which
      @doFind() if(code == 13)
    Object.observe @model, (changes) =>
      console.log changes

  show: (@issues) ->
    @findIssuesField.focus()
    @showRelatedIssues()
    @doFind() if (@searchResult.is(':empty'))

  showRelatedIssues: () ->
    @relatedIssues.empty()
    return unless @issues
    @relatedIssues.html @$spinner()
    async.map(@issues, (number, cb) =>
      @model.service.getIssue(number, (err, issue) =>
        cb(err, issue)
      )
    , (err, results) =>
        # #TODO:0 Check error for 404/Not Found
        if err
          console.log "error:", err
        else
          @relatedIssues.html @$issueList(results)
    )

  getSearchQry: ->
    qry = @findIssuesField.getModel().getText()
    return ImdoneAtomGithubView.defaultSearch unless qry
    qry

  doFind: (e) ->
    @searchResult.html @$spinner()
    searchText = @getSearchQry()
    @model.service.findIssues searchText, (e, data) =>
      @searchResult.html @$issueList(data.items)
      console.log data

  $spinner: ->
    $$ ->
      @div class: 'spinner', =>
        @span class:'loading loading-spinner-large inline-block'

  $issueList: (issues) ->
    $$ ->
      @ol =>
        for issue in issues
          @li class:'issue well', "data-issue-id":issue.id, =>
            @div class:'issue-title', =>
              @p =>
                @span "#{issue.title} "
                @a href:issue.html_url, class:'issue-number', "##{issue.number}"
            @div class:'issue-state', =>
              @p =>
                if issue.state == "open"
                  @span class:'badge badge-success icon icon-issue-opened', 'Open'
                else
                  @span class:'badge badge-error icon icon-issue-closed', 'Closed'
