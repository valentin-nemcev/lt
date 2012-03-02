class Lt.Models.Quote extends Backbone.Model
  paramRoot: 'quote'

  defaults:
    content: null
    source: null

class Lt.Collections.QuotesCollection extends Backbone.Collection
  model: Lt.Models.Quote
  url: '/quotes'
