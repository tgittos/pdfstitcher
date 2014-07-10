(function($){

  // validate file type
  function validate() {
    return this.type == "application/pdf";
  }

  function beforeSend() {
    $('.dragon-drop-feedback').removeClass('hidden');
    $('.dragon-drop-feedback img').removeClass('hidden');
    $('.dragon-drop-feedback span').html('Compiling your PDF, this may take some time...');
  };

  // encode file as a dataURL
  // return a promise to avoid global mutable state
  function toDataURL() {
    var reader = new FileReader(),
        deferred = $.Deferred(),
        file = this;
    reader.onload = function(e){
      deferred.resolve({ filename: file.name, data: e.target.result });
    }
    reader.readAsDataURL(file);
    return deferred.promise();
  }

  $(document).ready(function(){

    // set up the holder to call a function on drop
    var holder = $('.dragon-drop'),
        filesList = $('.files-list');
    if (holder) {
      holder.on('dragover', function(){ $(this).addClass('hover'); return false; });
      holder.on('dragend', function () { $(this).removeClass('hover'); return false; });

      // yuck mutable state
      var dataFiles = [];

      var dropStream = Rx.Observable.fromEvent(holder, 'drop');
      dropStream.subscribe(function(e) {
        $(e.target).removeClass('hover');
        e.preventDefault();
        if (e.originalEvent.dataTransfer) {
          var validFiles = $(e.originalEvent.dataTransfer.files).filter(validate);
          $(validFiles).map(toDataURL).map(function(){ this.done(function(data){
            dataFiles.push(data);
            filesList.show().html($.map(dataFiles, function(f){ return f.filename }).join(", "));
          })});
        }
      });

      $('.dragon-drop-submit').on('click', function(e){
        e.preventDefault();
        $.ajax({
          type: 'POST',
          url: "/stitch_files",
          data: {
            files: dataFiles
          },
          dataType: 'json',
          beforeSend: beforeSend
        }).success(function(result){
          console.log(result);
          $('.dragon-drop-feedback img').addClass('hidden');
          if (result.success) {
            $('.dragon-drop-feedback span').html('All done! <a href="' + result.pdf + '">Download your PDF now.</a>');
            $('.files-list').html('').addClass('hidden');
            dataFiles = [];
          } else {
            $('.dragon-drop-feedback span').html(result.message);
          }
        });
      });
    };

  });

})(window.jQuery);
