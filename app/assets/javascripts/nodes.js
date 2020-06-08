$(document).on('turbolinks:load', function() {
  $(document).on("keydown", "#search_ddes", function(event) {
    // Prevent <ENTER> from submitting the parent form:
    if (13 == event.keyCode) event.preventDefault();
  }).on("keyup", "#search_ddes", function() {
    var regexp   = new RegExp($(this).val(), 'i'),
        $all     = $('#dde_items label'),
        $counter = $('#filtered_dde_count'),
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

  toggle_node_form_element('data-dictionary-element', 'add-dde')
  toggle_node_form_element('governance', 'add-governance')
  toggle_node_form_element('existing-node', 'add-existing-node')

  $(document).on('cocoon:after-insert', function () {
    toggle_node_form_element('governance', 'add-governance')
    toggle_node_form_element('data-dictionary-element', 'add-dde')
  });

// TODO: Dry up - same as searching data dictionary elements
  $(document).on("keydown", "#search_existing_nodes", function(event) {
    // Prevent <ENTER> from submitting the parent form:
    if (13 == event.keyCode) event.preventDefault();
  }).on("keyup", "#search_existing_nodes", function() {
    var regexp   = new RegExp($(this).val(), 'i'),
        $all     = $('#existing_nodes label'),
        $counter = $('#filtered_existing_node_count'),
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
  
  $(".table-child-nodes-sortable").sortable({
    update: function(e, ui) {
      $(ui.item).addClass("table-update-sort");
      $.ajax({
        type: 'PATCH',
        url: $(this).data("url"),
        data: { child_nodes: $(this).sortable('toArray') },
        complete: function() {
          $(ui.item).removeClass("table-update-sort");
        }
      });
    }
  });
});

function toggle_node_form_element(node_form_element, div_class) {
  $('.' + node_form_element).hide();
  var checkbox = document.getElementById('#' + div_class);
  $('#' + div_class).on('click', function() {
    $('.' + node_form_element).toggle();
  });
};

//initialization 
// $( ".table" ).sortable();
// Setter
// $( ".table" ).sortable( "option", "items", ".sortable-tbody" );