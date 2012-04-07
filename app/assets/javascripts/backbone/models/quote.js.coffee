class Lt.Models.Quote extends Backbone.Model
  paramRoot: 'quote'

  defaults:
    content: null
    source: null

  toJSON: ->
    attributes = {}
    for key in ['content', 'source']
      attributes[key] = @attributes[key]
    return attributes

class Lt.Models.RandomQuote extends Lt.Models.Quote
  url: '/quotes/next_random'

  fetch_next: (options = {}) ->
    @fetch _.extend({}, options, url: @url + '?after=' + @id)

class Lt.Collections.QuotesCollection extends Backbone.Collection
  model: Lt.Models.Quote
  url: '/quotes'
