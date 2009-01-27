$(document).ready(function(){
  $('#volume_slider').slider({
    value: $('#volume_value').val(),
    stop: function(e, ui){
      jQuery.get('/?do=set_volume&volume=' + ui.value);
    }
  });
  
  $('a.artist').click(function(e){
    target = $(e.target);
    jQuery.get(target.attr('href'),
      function(data) {
        $('#albums').html(data);
        $('.selected').removeClass('selected');
        target.addClass('selected');
        target.parent().addClass('selected');
      }
    );
    return false;
  });
});