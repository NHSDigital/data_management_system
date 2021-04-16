$(document).on('turbolinks:load', function() {
  $('.other_addresses_hide').click(function(){
    $(this).text(function(i,old){
        return old=='other addresses' ?  'hide' : 'other addresses';
    });
  });
});
