var AO = AO || {};

AO.actionsPage = (function (rootParam) {
  $(document).ready(initialize);

  var root;

  function initialize() {
    root = $(rootParam);



    restyleSelectBox([
      '#member_info_country_iso',
      '#action_info_currency',
      '#action_info_card_type',
      '#action_info_card_expiration_month',
      '#action_info_card_expiration_year',
      '#paypal_donation_country_iso',
      '#paypal_donation_currency'].join()
    );

    setValidatationMetadataOnMemberFields();

    AO.validations.hookValidationsTo(root.find('#action_form'));
    AO.validations.hookValidationsTo(root.find('#paypal_donation_form'));

    initializeDonationsForm();

    hidePostcodeFieldDependingOnUsersCountry();
  }

  function restyleSelectBox(selector) {
    var element = root.find(selector)
    if (element.length) {
      var originalDropdown = element.selectBox();
      var newSelectBox = originalDropdown.siblings('.selectBox-dropdown');
      newSelectBox.bind('blur', function() {
        originalDropdown.hasClass('valid') && newSelectBox.removeClass('error');
      });
      originalDropdown.bind('change', function (event) {
        if (!MOVEMENT.utils.isSelectLabelSelected(event.target)) {
          newSelectBox.find(".selectBox-label").addClass("content-selected");
        }
      });
    }
    element.trigger('change');
  }

  function setValidatationMetadataOnMemberFields() {
    var lastRequestedEmail;
    root.find('input#member_info_email').bind('keyup blur change', function (e) {
      var email = $(e.target).val();
      if (!isValidEmail(email) || lastRequestedEmail === email) return;

      lastRequestedEmail = email;
      $.ajax({
        url: $.trim($("#url_for_member_fields").text()),
        data: { email: email },
        dataType:'jsonp',
        success: updateValidationMetadataOnMemberFields
      });
    });
  }

  var memberFieldMap = {
    first_name: '#action_form .field_wrapper.first_name',
    last_name: '#action_form .field_wrapper.last_name',
    country: '#action_form .field_wrapper.country',
    postcode: '#action_form .field_wrapper.postcode',
    mobile: '#action_form .field_wrapper.mobile_number'
  };
  function updateValidationMetadataOnMemberFields(data) {
    resetDefaultValidationRules();
    $.each(data.member_fields, function (key, value) {
      var fieldWrapper = $(memberFieldMap[key]);
      var isRequired = value == 'required';

      showAndEnableFieldsIn(fieldWrapper, isRequired);
    });
  }

  function showAndEnableFieldsIn(fieldWrapperParam, fieldIsRequired) {
    var fieldWrapper = $(fieldWrapperParam);
    fieldWrapper.removeClass('hidden');
    fieldWrapper.removeClass('invisible');
    fieldWrapper.find('input, select').removeAttr('disabled');
    fieldWrapper.find('select').selectBox('enable');
    setRequiredRuleToFieldsIn(fieldWrapper, fieldIsRequired);
  }

  function hideAndDisableFieldsIn(fieldWrapper) {
    root.find(fieldWrapper).addClass('invisible');
    disableFieldsIn(fieldWrapper);
  }

  function removeAndDisableFieldsIn(fieldWrapper) {
    root.find(fieldWrapper).addClass('hidden');
    disableFieldsIn(fieldWrapper);
  }

  function disableFieldsIn(fieldWrapper) {
    root.find(fieldWrapper)
        .find('input')
            .attr('disabled', true)
            .removeClass('error')
        .end()
        .find('select')
            .removeAttr('required')
            .selectBox('disable');
  }

  function setRequiredRuleToFieldsIn(fieldWrapper, fieldIsRequired) {
    var elements = fieldWrapper.find('input, select');
    if (fieldIsRequired) {
      elements.attr('required', true);
    } else {
      elements.removeAttr('required');
    }
  }

  function resetDefaultValidationRules() {
    removeAndDisableFieldsIn('.toggleable_field');
  }

  function isValidEmail(value) {
    return /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i.test(value);
  }

  function initializeDonationsForm() {
    var donationModule = root.find("#donation_module");
    if (!donationModule.length) return;

    donationModule.find("#action_info_currency, #paypal_donation_currency").change(function () {
      var parentFieldset = $(this).closest('fieldset');
      parentFieldset.find(".suggested_amounts_wrapper").hide();
      var selectedCurrency = $(this).val();
      parentFieldset.find(".amounts_for_currency_" + selectedCurrency).show();
      $.colorbox.resize();
    }).change();

    donationModule.find('input, select').bind('focus blur', function() {
      $(this).closest('fieldset').toggleClass('active');
    });

    $('#action_form.donation').submit(function() {
      addSelectedAmountToForm($(this), 'action_info');
    });
    $('#paypal_donation_form').submit(function() {
      addSelectedAmountToForm($(this), 'paypal_donation');
    });
    
    function addSelectedAmountToForm(form, fieldset) {
      var currency = form.find('#'+ fieldset +'_currency').val();
      var amount = form.find('[name="'+ fieldset +'[amount_for_' + currency + ']"]:checked').val();
      if (amount === 'other') amount = form.find('#' + fieldset + '_other_amount_for_' + currency).val();

      var amountInput = form.find('input[type="hidden"][name="'+ fieldset +'[amount]"]');
      if (!amountInput.length) amountInput = $('<input type="hidden" name="'+ fieldset +'[amount]">').appendTo(form);
      amountInput.val(amount);
    }

    $('.suggested_amount_other').find('input[type="number"]').focus(function (e) {
      $(this).parents('span').find('input[type=radio]').attr('checked', 'checked').trigger('change');
    });

         /**
    $("#paypal_donation").colorbox({inline: true, href: '#paypal_donation_popup', initialWidth: 100, initialHeight: 30, scrolling: false})
      .bind('cbox_load', function(event) {
        var currency = $('#action_info_currency').val();
        $('#paypal_donation_currency').selectBox('value', currency).change();
        var amount = $('[name="action_info[amount_for_' + currency + ']"]:checked').val();
        $('[name="paypal_donation[amount_for_' + currency + ']"][value='+ amount +']').attr('checked', true);
      });
    $('#paypal_donation_popup .cancel').click(function() {
      $.colorbox.close();
      return false;
    });
       **/
  }

  function hidePostcodeFieldDependingOnUsersCountry() {
    var postCodeFieldWrapper = '.field_wrapper.postcode';

    var actionForm = root.find('#action_form');
    var paypalForm = root.find('#paypal_donation_form');

    setupCountryAndPostcodeFields(
      actionForm.find('.field_wrapper.country'),
      actionForm.find('.field_wrapper.postcode')
    );

    if (paypalForm.length) {
      setupCountryAndPostcodeFields(
        paypalForm.find('.field_wrapper.country_iso'),
        paypalForm.find('.field_wrapper.postcode')
      );
    }

    function setupCountryAndPostcodeFields(countryWrapper, postcodeWrapper) {
      var countryField = countryWrapper.find('select');
      var postcodeField = postcodeWrapper.find('input');

      function isPostcodeRequired() {
        return postcodeField.attr('required') != undefined;
      }

      countryField.change(function (event) {
        if (MOVEMENT.utils.isSelectLabelSelected(event.target)) {
          return;
        }

        var selectedOption = $(event.target).find('option:selected');
        var usesPostcode = selectedOption.attr('data-uses-postcode') === "true";
        if (usesPostcode) {
          showAndEnableFieldsIn(postcodeWrapper, isPostcodeRequired());
        } else {
          hideAndDisableFieldsIn(postcodeWrapper);
        }
      });
    }
  }
}) ('.section_actions');


$AO.actions = {
  show: function() {
    
    var commentArea = $('#action_info_comment');
    var maxlength = commentArea.attr('maxlength');
    commentArea.charCount({allowed: maxlength});

    if($('body').attr('data-enable-activity-feed') == 'true') {
      $('#comments').commentsFeed(5, '#recent_comment_template');
    };

    var $selectbox_ie_styles = {
      height: '26px',
      border: '1px solid #BBB'
    };
    $AO.methods.actionCounter();

    $('#taf_options').each(function() {
      var share_url = $(this).attr('data-share-url');
      var page_id = $(this).attr('data-page-id');
      var user_id = $(this).attr('data-user-id');


      $AO.tafs.methods.initializeTafSharing({share_url: share_url, page_id: page_id, user_id: user_id});
    });
  }
};
