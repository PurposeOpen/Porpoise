(function($) {
  $.fn.fancyLabels = function(options) {
    options = $.extend({
      half_opacity: {
        'opacity': '0.5'
      },
      full_opacity: {
        'opacity': '1'
      }
    }, options);

    return this.each(function() {
      var label = $(this);
      var input = findInputField(label);
      if (!input) {
        console.log("Couldn't find input for label " + label.text());
        return;
      }

      positionLabelWithinInput(label, input);
      bindEvents(label, input);
    });

    function findInputField(label) {
      var forAttribute = label.attr('for');
      if (!forAttribute) return false;
      var input = $('#' + forAttribute);
      return input.size() ? input : false;
    }

    function bindEvents(label, input) {
      input.focus(function() {
        label.css(options.half_opacity);
      });
      input.blur(function() {
        label.animate(options.full_opacity, 175);
      });
      input.bind('keyup change', function() {
        if ($.trim(input.attr('value'))) {
          label.hide();
        } else {
          label.show(75);
        }
      });
      input.trigger('change');
    }

    function positionLabelWithinInput(label, input) {
      var labelPosition = calculateLabelPosition(label, input);

      label.css({
        position: 'absolute',
        top: labelPosition.top,
        left: labelPosition.left,
        visibility: 'visible',
        cursor: 'text'
      });
    }

    function calculateLabelPosition(label, input) {
      var borderTop = parseInt(input.css('border-top-width'));
      var paddingTop = parseInt(input.css('padding-top'));
      var marginTop = parseInt(input.css('margin-top'));
      var borderLeft = parseInt(input.css('border-left-width'));
      var paddingLeft = parseInt(input.css('padding-left'));
      var marginLeft = parseInt(input.css('margin-left'));

      var heightCorrection = findHeightCorrectionToCenterLabel(label, input);
      var labelMarginAndPadding = topMarginAndPaddingOf(label);

      return {
        top: borderTop + paddingTop + marginTop + heightCorrection - labelMarginAndPadding,
        left: borderLeft + paddingLeft + marginLeft + 1
      };
    }

    function findHeightCorrectionToCenterLabel(label, input) {
      if (input.is('textarea')) {
        return 0;
      }
      var labelHeight = textElementHeight(label);
      var inputHeight = textElementHeight(input);
      return (inputHeight - labelHeight) / 2;
    }

    function textElementHeight(element) {
      var height = parseInt(element.css("height"));
      if (height == 0 || isNaN(height)) {
        height = parseInt(element.css("line-height"));
      }
      if (isNaN(height)) {
        height = 0;
      }
      return height;
    }

    function topMarginAndPaddingOf(label) {
      var paddingTop = parseInt(label.css('padding-top'));
      var marginTop = parseInt(label.css('margin-top'));
      return paddingTop + marginTop;
    }

    function isZeroOrNaN(number) {
      return number === 0 || isNaN(number);
    }
  }
})(jQuery);