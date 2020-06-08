$(document).on('turbolinks:load', function() {

  // Handles realtime filtering of users for mapping.
  $(document).on("keydown", "#search_users", function(event) {
    // Prevent <ENTER> from submitting the parent form:
    if (13 == event.keyCode) event.preventDefault();
  }).on("keyup", "#search_users", function() {
    var regexp   = new RegExp($(this).val(), 'i'),
        $all     = $('#user_info label'),
        $counter = $('#filtered_user_count'),
        $matches;

    // Hide all choices, to reveal matches later:
    $all.hide();

    $matches = $all.filter(function() {
      var option = $(this).data('value');
      return regexp.test(option);
    })

    // Show all that matched in one operation to minimse redraws:
    $matches.show();
    $counter.text($matches.length);
  });
});
