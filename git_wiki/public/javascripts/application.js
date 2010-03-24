(function($) {
  
  var flash_timeout;
  function flash(message){
    clearTimeout(flash_timeout);
    $('#flash .message').html(message).show('highlight');
    flash_timeout = setTimeout(function(){
      $('#flash .message').hide();
    },5000);
  }

  function initaliseShowPage(){
    function edit(){
      window.location.search = '?edit=1';
    }
    $(window)
      .bind("dblclick", edit)
      .keydown(function(event){
        if (event.keyCode == 69 && event.metaKey){
          edit();
          return false;
        }
      });
  }

  function initaliseEditPage(){
    var save_button = $('form#edit .save');
    var textarea    = $('#editor textarea');
    var preview     = $('#preview');
    var saved_value = textarea.val();

    textarea.focus();

    function updatePreview(){
      $.post("/preview", { 'body': textarea.val() }, function(a,b){
        a = a.replace(/<script.*\/script>/g,'<img src="/images/script_icon.gif"/>');
        preview.html(a);
      });
    }

    updatePreview();

    function pageHasChanges(){
      return saved_value !== textarea.val();
    }

    function save(){
      $.post($('form#edit').attr('action'), {body:textarea.val()});
      saved_value = textarea.val();
      save_button.attr('disabled',true);
      flash('SAVED');
    }

    function saveAndClose(){
      save_button.removeAttr('disabled');
      save_button.click();
    }

    textarea.keyup(function(){
      if (pageHasChanges()){
        save_button.removeAttr('disabled');
        updatePreview();
      }else{
        save_button.attr('disabled',true);
      }
    });

    $(window)
      .keydown(function(event){
        if (event.keyCode == 83 && event.metaKey){
          if (event.shiftKey){
            save();
          }else{
            saveAndClose();
          }
          return false;
        }
      });

    var saving = false;
    save_button.click(function(){
      saving = true;
    });
    window.onbeforeunload = function(){
      return (!saving && pageHasChanges()) ? "You have unsaved changes." : undefined;
    };
  }


  $(document).ready(function(){
    var page = $('#page');
    if (page.hasClass('show')) initaliseShowPage();
    if (page.hasClass('edit')) initaliseEditPage();
  });

})(jQuery);