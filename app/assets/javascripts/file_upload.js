$(document).on('drag dragstart dragend dragover dragenter dragleave drop', function(e) {
  e.preventDefault();
  e.stopPropagation();
});

$(document).on('turbolinks:load', function(){
  var $dropzone = $('.dropzone');

  $dropzone.on('dragover dragenter', function() {
    $dropzone.addClass('is-dragover');
  });
  $dropzone.on('dragleave dragend drop', function() {
    $dropzone.removeClass('is-dragover');
  });

  // Drag to submit files...
  $('.dropzone').each(function(){
    var $dropzone = $(this);
    var $progress = $('.progress-bar', $dropzone);
    var $input    = $('input[type="file"]', $dropzone);

    $input.fileupload({
      dropZone: $dropzone,
      submit: function (e, data) {
        $dropzone.addClass('upload-in-progress');
        $progress.css('width', '0%');
      },
      always: function (e, data) {
        $dropzone.removeClass('upload-in-progress');
      },
      progressall: function (e, data) {
        var progress = parseInt(data.loaded / data.total * 100, 10);
        $progress.css('width', progress + '%');
      }
    });
  });
});
