(function( $ ){

  $.fn.dependsOn = function(element, value) {
    var elements = this;
    var hideOrShow = function() {
      var $this = $(this);
      var showEm;
      if ( $this.is('input[type="checkbox"]') ) {
        showEm = $this.is(':checked');
      } else if ($this.is('select')) {
        var fieldValue = $this.find('option:selected').val();
        if (typeof(value) == 'undefined') {
          showEm = fieldValue && $.trim(fieldValue) != '';
        } else if ($.isArray(value)) {
          showEm = $.inArray(fieldValue, value.map(function(v) {return v.toString()})) >= 0;
        } else {
          showEm = value.toString() == fieldValue;
        }
      }
      elements.toggle(showEm);
    }
    //add change handler to element
    $(element).change(hideOrShow);

    //hide the dependent fields
    $(element).each(hideOrShow);

    return elements;
  };

  $(document).on('turbolinks:load', function() {
    $('*[data-depends-on]').each(function() {
      var $this = $(this);
      var master = $this.data('dependsOn').toString();
      var value = $this.data('dependsOnValue');
      if (typeof(value) != 'undefined') {
        $this.dependsOn(master, value);
      } else {
        $this.dependsOn(master);
      }
    });
  });

})( jQuery );

$(document).on('turbolinks:load', function() {
  if (location.hash.substr(0,2) == "#!") {
    $("a[href='#" + location.hash.substr(2) + "']").tab("show");
  }

  $("a[data-toggle='tab']").on("shown.bs.tab", function (e) {
    var hash = $(e.target).attr("href");
    if (hash.substr(0,1) == "#" && hash.substr(1,3) != "ons") {
      location.replace("#!" + hash.substr(1));
    }
  });


  $("#search_unselected").keyup(function () {
    filter_unselected_items();
  });

  $("#search_selected").keyup(function () {
    filter_selected_items();
  });

  $('#reset_search_selected').click(function(event) {
    $("#search_selected").val('');
    $("#all_selected").prop("checked", true);
    $('#selected_data_source_items div').show();
  });

  $('#reset_search_unselected').click(function(event) {
    $("#search_unselected").val('');
    $("#all_unselected").prop("checked", true);
    $('#unselected_data_source_items div').show();
  });

  // Transfer between divs
  $('.data-select-row').click(function(event) {
    var gov_deselect = $('input[name=deselect-governance]:checked').val()
    var gov_select = $('input[name=select-governance]:checked').val()
    if (event.target.type !== 'checkbox') {
      var element_name = $(this).attr('id').replace('data_source_item_','');
      $('#checkbox_'+element_name).trigger('click');
      if ($('#checkbox_'+element_name).is(':checked') == true){
        //alert('clicked');
        document.getElementById('selected_data_source_items').appendChild(
          document.getElementById('data_source_item_'+element_name)
        );
        if ($('#unselected_data_source_items > #data_source_item_'+element_name).length > 0){
          document.getElementById('unselected_data_source_items').removeChild(
            document.getElementById('data_source_item_'+element_name)
          );
        };
      } else {
        document.getElementById('unselected_data_source_items').appendChild(
          document.getElementById('data_source_item_'+element_name)
        );
        // $('#data_source_item_'+element_name).hide();
        if ($('#selected_data_source_items > #data_source_item_'+element_name).length > 0){
          document.getElementById('selected_data_source_items').removeChild(
            document.getElementById('data_source_item_'+element_name)
          );
        }
      };
      reset_counts();
    }
  });

  $("input[name='select-governance']").change(function(e){
    filter_unselected_items();
  });

  $("input[name='deselect-governance']").change(function(e){
    var gov = $('input[name=deselect-governance]:checked').val()
    var rex = new RegExp($("#search_selected").val(), 'i');
    $('#selected_data_source_items div').hide();
    $('#selected_data_source_items div').filter(function () {
      if ( rex.test($(this).text()) &&
        (gov == 'ALL' || $(this).hasClass(gov))){
        return rex.test($(this).text());
      }
    }).show();
  });

 // // filter by dataset
  $("select[id='selected_datasets']").change(function(e){
    filter_unselected_items();
  });

  $("select[id='deselect_datasets']").change(function(e){
    var ds = $('#deselect_datasets :selected').val()
    var rex = new RegExp($("#search_selected").val(), 'i');
    $('#selected_data_source_items div').hide();
    $('#selected_data_source_items div').filter(function () {
      if ( rex.test($(this).text()) &&
        (ds == 'ALL' || $(this).hasClass(ds))){
        return rex.test($(this).text());
      }
    }).show();
  });

  $("select[id='selected_tables']").change(function(e){
    filter_unselected_items();
  });

  $("select[id='deselect_tables']").change(function(e){
    var gov = $('#deselect_tables :selected').val()
    var rex = new RegExp($("#search_selected").val(), 'i');
    $('#selected_data_source_items div').hide();
    $('#selected_data_source_items div').filter(function () {
      if ( rex.test($(this).text()) &&
        (gov == 'ALL' || $(this).hasClass(gov))){
        return rex.test($(this).text());
      }
    }).show();
  });

  var startDate = new Date('01/01/2017');
  var FromEndDate = new Date();
  var ToEndDate = new Date();
  var Today = new Date();

  $("#project_start_data_date").datepicker({
    autoclose: true,
  }).on('changeDate', function (selected) {
    var startDate = new Date(selected.date.valueOf());
    if (startDate < Today) {
      startDate = Today;
    }
    $('#project_end_data_date').datepicker('setStartDate', startDate);
  }).on('clearDate', function (selected) {
    $('#project_end_data_date').datepicker('setStartDate', null);
  });

  $("#project_team_dataset_id").change(function(e){
    var ds = document.getElementById("dataset_ids");
    var terms = ds.options[ds.selectedIndex].dataset.terms;
    document.getElementById("dataset_terms_message_div").innerHTML = terms;
  });

  $('.dataset_terms').hide();

  $('#project_dataset_ids').on('change', function() {
    $('.dataset_terms').show();
    $('#project_data_source_terms_accepted').prop('checked', false);
  });

  $("#project_end_data_date").datepicker({
    autoclose: true,
  }).on('changeDate', function (selected) {
    var endDate = new Date(selected.date.valueOf());
    $('#project_start_data_date').datepicker('setEndDate', endDate);
  }).on('clearDate', function (selected) {
    $('#project_start_data_date').datepicker('setEndDate', null);
  });

  // TODO: this no longer works with new multi select
  $('.mortality-extra').show();


  $('#project_team_dataset_id').on('change', function() {
    var mortality_sources = ['Deaths Gold Standard', 'Death Transaction'];
    var data_source = $('#project_datasets option:selected').text()

    // if ($("#multi_project_datasets").text().indexOf('Deaths Gold Standard') >= 0) {
    if (jQuery.inArray(data_source, mortality_sources) !='-1') {
      $('.mortality-extra').show('slow');
    } else {
      $('.mortality-extra').hide('slow');
    }
  });

  reset_counts();

  $('form').on('click', '.remove_record', function(event) {
    $(this).siblings('input').val('1');
    $(this).closest('li').hide();
    return event.preventDefault();
  });

  $('form').on('click', '.add_fields', function(event) {
    var regexp, time;
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');
    $('.repeatable-fields').append($(this).data('fields').replace(regexp, time));
    return event.preventDefault();
  });
});

function reset_counts(){
  $('#unselected_count').text(''+$('#unselected_data_source_items > div').length);
  $('#selected_count').text(''+$('#selected_data_source_items > div').length);
};

function set_labels(){
  $('#all_approvals_answered').html("<%= escape_javascript approval_button_message(@project.can_submit_approvals) %>");
  $('#all_approvals_answered').removeClass().addClass('label label-<%= approval_button_style(@project.can_submit_approvals) %>');
}

function can_submit_to_odr(data_items_to_justify){
  if ( //$('#ons_data_count').text() == '0' ||
    //$('#ons_use_count').text() == '0'  ||
    //$('#ons_list_count').text() == '0'  ||
    $('.project_data_items_table').length == 0 ||
    $('.project_members_table').length == 0 ||
    ($('.project_data_items_table').length != 0 && data_items_to_justify > 0)) {
    $('#submit_for_odr_approval_button').removeClass().addClass('btn btn-default disabled');
  } else {
    $('#submit_for_odr_approval_button').removeClass().addClass('btn btn-default');
  }
}

function toggle_checkboxes(field_class){
  $('.' + field_class).each(function(){
    this.click();
  });
}

function show_rows(field_class){
  $('.tr_' + field_class).toggle();
}

function filter_unselected_items(){
  var gov = $('input[name=select-governance]:checked').val()
  var rex = new RegExp($("#search_unselected").val(), 'i');
  var ds = $('#selected_datasets :selected').val();
  var tab_node = $('#selected_tables :selected').val();
  $('#unselected_data_source_items div').hide();
  $('#unselected_data_source_items div').filter(function () {
    if ( rex.test($(this).text()) &&
      (tab_node == 'ALL' || $(this).hasClass(tab_node)) &&
      (ds == 'ALL' || $(this).hasClass(ds)) &&
      (gov == 'ALL' || $(this).hasClass(gov))){
      return rex.test($(this).text());
    }
  }).show();
}

function filter_selected_items(){
  var gov = $('input[name=deselect-governance]:checked').val()
  var rex = new RegExp($("#search_selected").val(), 'i');
  var ds = $('#deselect_datasets :selected').val();
  var tab_node = $('#deselect_tables :selected').val();
  $('#selected_data_source_items div').hide();
  $('#selected_data_source_items div').filter(function () {
    if ( rex.test($(this).text()) &&
      (tab_node == 'ALL' || $(this).hasClass(tab_node)) &&
      (ds == 'ALL' || $(this).hasClass(ds)) &&
      (gov == 'ALL' || $(this).hasClass(gov))){
      return rex.test($(this).text());
    }
  }).show();
}
