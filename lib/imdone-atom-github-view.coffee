{$, $$, $$$, View} = require 'atom-space-pen-views'
module.exports =
class ImdoneAtomGithubView extends View
  @content: ->
    @div id:"imdone-atom-github-view"

  initialize: (@model) ->
    Object.observe @model, (changes) =>
      console.log changes
