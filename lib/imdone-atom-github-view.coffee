{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
module.exports =
class ImdoneAtomGithubView extends View
  @content: ->
    @div id:"imdone-atom-github-view", =>
      @div class: 'block find-issues', =>
        @div class: 'input-med', =>
          @subview 'findIssuesField', new TextEditorView(mini: true)
        @div class:'btn-group btn-group-find', =>
          @button click: 'doFind', class:'btn btn-primary inline-block-tight', 'Find Issues'

  initialize: (@model) ->
    @handleEvents()

  handleEvents: ->
    @findIssuesField.on 'keyup', (e) =>
      code = e.keyCode || e.which
      @doFind() if(code == 13)
    Object.observe @model, (changes) =>
      console.log changes

  show: ->
    @findIssuesField.focus()

  doFind: (e) ->
    searchText = @findIssuesField.getModel().getText()
    @model.githubService.github.search.issues
      q: searchText, (e, data) =>
        console.log data
