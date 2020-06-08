$(document).on('turbolinks:load', function() {
  $('.more_or_less').click(function(){
    $(this).text(function(i,old){
        return old=='more' ?  'less' : 'more';
    });
  });
});
