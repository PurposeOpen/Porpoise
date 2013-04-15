var $AO = $AO || {};

$AO.navbar = {
  init: function (links) {
    $(links).each(function() {
      if ($(this).attr("href") === window.location.pathname) {
        $(this).addClass("active");
      }
    });    
  }
};

$(document).ready(function() {
  $AO.navbar.init("header nav li a");
});
