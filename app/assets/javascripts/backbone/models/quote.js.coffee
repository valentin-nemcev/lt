class Lt.Models.Quote extends Backbone.Model
  paramRoot: 'quote'

  defaults:
    content: null
    source: null

class Lt.Models.RandomQuote extends Lt.Models.Quote
  url: '/quotes/next_random'

  fetch_next: (options = {}) ->
    @fetch _.extend({}, options, url: @url + '?after=' + @id)

class Lt.Collections.QuotesCollection extends Backbone.Collection
  model: Lt.Models.Quote
  url: '/quotes'
