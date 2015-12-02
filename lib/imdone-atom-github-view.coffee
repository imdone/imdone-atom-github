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
          @button click: 'newIssue', class:'btn btn-success inline-block-tight', 'New Issue'
      @div class:'issues-container', =>
        @div outlet: 'searchResult', class: 'issue-list search-result'
        @div outlet: 'relatedIssues', class: 'issue-list related-issues'

  constructor: (@model) ->
    super
    @handleEvents()

  handleEvents: ->
    model = @model
    self = @
    @findIssuesField.on 'keyup', (e) =>
      code = e.keyCode || e.which
      @doFind() if(code == 13)

    Object.observe @model, (changes) =>
      console.log changes

    @on 'click', '.issue-add', (e) ->
      id = $(@).attr('data-issue-number')
      $(@).closest('li').remove();
      model.task.addMetaData model.metaKey, id
      model.repo.modifyTask model.task, true, (err, result) ->
        console.log err, result
        self.issues = model.getIssueIds()
        self.showRelatedIssues()

    @on 'click', '.issue-remove', (e) ->
      id = $(@).attr('data-issue-number')
      $(@).closest('li').remove();
      model.task.removeMetaData model.metaKey, id
      model.repo.modifyTask model.task, true, (err, result) ->
        console.log err, result
        self.issues = model.getIssueIds()
        self.doFind()

  show: (@issues) ->
    @findIssuesField.focus()
    @showRelatedIssues()
    @doFind()

  showRelatedIssues: () ->
    @relatedIssues.empty()
    return unless @issues
    @relatedIssues.html @$spinner()
    async.map(@issues, (number, cb) =>
      @model.service.getIssue(number, (err, issue) =>
        cb(err, issue)
      )
    , (err, results) =>
        # #TODO:10 Check error for 404/Not Found
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
      if data
        @searchResult.html @$issueList(data.items, true)
      else
        @searchResult.html 'No issues found'

  newIssue: ->
    # TODO Also add the task list as a label
    @model.service.newIssue @model.task.text, (e, data) =>
      @model.task.addMetaData @model.metaKey, data.number
      @model.repo.modifyTask @model.task, true
      @issues = @model.getIssueIds()
      @showRelatedIssues()

  $spinner: ->
    $$ ->
      @div class: 'spinner', =>
        @span class:'loading loading-spinner-large inline-block'

  $issueList: (issues, search) ->
    numbers = @issues
    $$ ->
      @ol =>
        for issue in issues
          unless search && numbers && numbers.indexOf(issue.number.toString()) > -1
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
                  if search
                    @a href:'#', class:'issue-add', "data-issue-number":issue.number, =>
                      @span class:'icon icon-diff-added mega-icon pull-right'
                  else
                    @a href:'#', class:'issue-remove', "data-issue-number":issue.number, =>
                      @span class:'icon icon-diff-removed mega-icon pull-right'
