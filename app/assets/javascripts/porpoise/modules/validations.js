var AO = AO || {};

AO.validations = (function () {
  var self = {};

  self.hookValidationsTo = function (form) {
    addExtraValidationMethods();

    $.metadata.setType('html5');
    $(form).validate({
      ignore: false,
      onkeyup: false,
      errorElement: 'span',
      meta: 'validation',
      errorPlacement: function(errorMessage, element) {
        if (element.attr('id') === 'member_info_country_iso') {
          element.siblings('.selectBox-dropdown').addClass('error').parent().append(errorMessage);
          return;
        }
        element.parent().append(errorMessage);
      }
    });
  };

  function addExtraValidationMethods() {
    var patternAttribute = function(value, element) {
      var pattern = element.getAttribute('pattern');
      return !pattern || this.optional(element) || new RegExp(pattern).test(value);
    };
    $.validator.addMethod('patternAttribute', patternAttribute, 'Please check your input.');
  }

  return self;
}) ();
