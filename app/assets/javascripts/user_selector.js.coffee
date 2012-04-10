$(document).on 'change', '#user_selector select', ->
    $(this).closest('form').submit()
