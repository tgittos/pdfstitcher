(function($){

  function beforeSend() {
    $('.feedback').removeClass('hidden');
    $('.feedback img').removeClass('hidden');
    $('.feedback span').html('Compiling your PDF, this may take some time...');
  };
  
  function success(result) {
    $('.feedback img').addClass('hidden');
    if (result.success) {
      $('.feedback span').html('All done! <a href="' + result.pdf + '">Download your PDF now.</a>');
    } else {
      $('.feedback span').html(result.message);
    }
  };

  $(document).ready(function(){
    $('button').click(function(){
      var url = $('input').val();
      $.ajax({
        type: 'POST',
        url: '/stitch', 
        data: { 
          url: url 
        },
        dataType: 'json',
        beforeSend: beforeSend, 
        success: success
      });
    });
  });

})(window.jQuery);
