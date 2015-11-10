{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
async = require 'async'
module.exports =
class ImdoneAtomGithubView extends View
  @content: ->
    @div id:"imdone-atom-github-view", =>
      @div outlet:'findIssues', class: 'block find-issues', =>
        @div class: 'input-med', =>
          @subview 'findIssuesField', new TextEditorView(mini: true, placeholder: "is:open is:issue")
        @div class:'btn-group btn-group-find', =>
          @button click: 'doFind', class:'btn btn-primary inline-block-tight', =>
            @span class:'icon icon-mark-github', 'Find Issues'
      @div outlet:'viewSwitch', class: 'block issue-view-switch', =>
        @div class: 'btn-group', =>
          @button outlet: 'searchSwitch', click: 'showSearch', class: 'btn', "search"
          @button outlet: 'relatedSwitch', click: 'showRelatedIssues', class: 'btn', "related"
      @div class:'issues-container', =>
        @div outlet: 'searchResult', class: 'issue-list'
        @div outlet: 'relatedIssues', class: 'issue-list'
        @div outlet: 'issueDetail', class: 'issue-detail'

  constructor: (@model) ->
    super
    @handleEvents()

  handleEvents: ->
    @findIssuesField.on 'keyup', (e) =>
      code = e.keyCode || e.which
      @doFind() if(code == 13)
    Object.observe @model, (changes) =>
      console.log changes

  hideAll: ->
    @viewSwitch.find('button').removeClass 'selected'
    @findIssues.hide()
    @searchResult.hide()
    @relatedIssues.hide()

  show: (@issues) ->
    if @issues
      @showRelatedIssues()
    else
      @relatedIssues.empty()
      @showSearch()

  showSearch: ->
    @hideAll()
    @searchSwitch.addClass 'selected'
    @findIssues.show()
    @searchResult.show()
    @findIssuesField.focus()

  showRelatedIssues: () ->
    @hideAll()
    @relatedSwitch.addClass 'selected'
    @relatedIssues.show()
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

  doFind: (e) ->
    @searchResult.html @$spinner()
    searchText = @findIssuesField.getModel().getText()
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
                @span issue.title
                @span class:'issue-number', " ##{issue.number}"
            @div class:'issue-state', =>
              @p =>
                if issue.state == "open"
                  @span class:'badge badge-success icon icon-issue-opened', 'Open'
                else
                  @span class:'badge badge-error icon icon-issue-closed', 'Closed'
