$(document).on 'change', '[widget=user-selector] [control=current-user]', ->
    $(this).closest('form').submit()
