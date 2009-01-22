$(document).ready(function(){
  $('#volume_slider').slider({
    value: $('#volume_value').val(),
    stop: function(e, ui){
      jQuery.get('/?do=set_volume&volume=' + ui.value);
    }
  });
});