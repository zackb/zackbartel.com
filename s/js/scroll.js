$(document).ready(function() {
    $("a[href*='#']:not([href='#'])").click(function(e) {
      e.preventDefault();
      var hash = this.hash;
      var section = $(hash);

      if (hash) { 
        $('html, body').animate({
          scrollTop: section.offset().top
        }, 1000, 'swing', function(){
          history.replaceState({}, "", hash);
        });
      }
    });
});
