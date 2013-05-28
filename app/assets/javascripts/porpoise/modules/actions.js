var AO = AO || {};

AO.actionsPage = (function (rootParam) {
    $(document).ready(initialize);

    var root;

    function initialize() {
        root = $(rootParam);



        restyleSelectBox([
            '#member_info_country_iso',
            '#action_info_currency',
            '#action_info_card_expiration_month',
            '#action_info_card_expiration_year'].join()
        );

        setValidatationMetadataOnMemberFields();
        addAmexValidation();
        AO.validations.hookValidationsTo(root.find('#action_form'));

        initializeDonationsForm();

        hidePostcodeFieldDependingOnUsersCountry();

        if($('input:hidden[name=t]')) {
            $('input:hidden[name=t]').val(getParameterByName('t'));
        }

    }

    /*
     Add custom Jquery Validate Rule for Amex/USD
     */
    function addAmexValidation(){
        $.validator.addMethod('amexValidation', function(value, element) {
            var card_number= $('#action_info_card_number').val();
            var card_type = getCardType(card_number);
            var currency = $('#action_info_currency').val();
            if(card_type==="American Express" && currency!="usd"){
                return false;
            }
            return true;

        });
    }



    function getParameterByName(name)
    {
        name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
        var regexS = "[\\?&]" + name + "=([^&#]*)";
        var regex = new RegExp(regexS);
        var results = regex.exec(window.location.search);
        if(results == null) {
            return "";
        } else {
            return decodeURIComponent(results[1].replace(/\+/g, " "));
        }
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
        first_name: {fieldWrapper : '#action_form .field_wrapper.first_name', memberField: 'first_name' },
        last_name: {fieldWrapper : '#action_form .field_wrapper.last_name', memberField: 'last_name' },
        country: {fieldWrapper : '#action_form .field_wrapper.country', memberField: 'country_iso' },
        postcode: {fieldWrapper : '#action_form .field_wrapper.postcode', memberField: 'postcode' },
        mobile_number: {fieldWrapper : '#action_form .field_wrapper.mobile_number', memberField: 'mobile_number' },
        home_number: {fieldWrapper : '#action_form .field_wrapper.home_number', memberField: 'home_number' },
        suburb: {fieldWrapper : '#action_form .field_wrapper.suburb', memberField: 'suburb' },
        street_address: {fieldWrapper : '#action_form .field_wrapper.street_address', memberField: 'street_address' }
    };
    function updateValidationMetadataOnMemberFields(data) {
        if (!data.member_fields.first_name && !data.member_fields.last_name)
            $.ajax({
                url: $.trim($("#url_for_member_info").text()),
                data: { email: root.find('input#member_info_email').val() },
                dataType:'jsonp',
                success: updateUserInfo
            });

        resetDefaultValidationRules();
        $.each(data.member_fields, function (key, value) {
            var fieldWrapper = $(memberFieldMap[key].fieldWrapper);
            var isRequired = value == 'required';

            showAndEnableFieldsIn(fieldWrapper, isRequired);
        });
    }

    function updateUserInfo(data) {
        $.each(data, function (key, value) {
            $(memberFieldMap[key].fieldWrapper).find(':input').val(value);
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

    function encodeData(data) {
        return Object.keys(data).map(function(key) {
            return [key, data[key]].map(encodeURIComponent).join("=");
        }).join("&");
    }

    // Credit card type functions
    function getCardType(cardnumber) {
        var cards = [
            { name: "Visa", prefixes: [4] },
            { name: "MasterCard", prefixes: [51, 52, 53, 54, 55] },
            { name: "American Express", prefixes: [34, 37] },
            { name: "Discover", prefixes: [6011, 62, 64, 65] },
            { name: "Diner's Club", prefixes: [305, 36, 38] },
            { name: "Carte Blanche", prefixes: [300, 301, 302, 303, 304, 305] },
            { name: "JCB", prefixes: [35] },
            { name: "enRoute", prefixes: [2014, 2149] },
            { name: "Maestro", prefixes: [5018, 5020, 5038, 6304, 6759, 6761, 6762, 6763] },
            { name: "Visa", prefixes: [417500, 4917, 4913, 4508, 4844] }, // Visa Electron
            { name: "Laser", prefixes: [6304, 6706, 6771, 6709] }
        ];

        for (var c = 0; c < cards.length; c++) {
            for (var p = 0; p < cards[c].prefixes.length; p++) {
                if (new RegExp("^" + cards[c].prefixes[p].toString()).test(cardnumber))
                    return cards[c].name;
            }
        }

        return 'Unknown';
    }



    function initializeDonationsForm() {
        var donationModule = root.find("#donation_module");
        if (!donationModule.length) return;

        donationModule.find("#action_info_currency").change(function () {
            var parentFieldset = $(this).closest('fieldset');
            parentFieldset.find(".suggested_amounts_wrapper").hide();
            var selectedCurrency = $(this).val();
            var isRecurring = parentFieldset.find("#donation_type > input:checked").val() === "true";
            var radioButtonsWrapper = $(parentFieldset.find(".amounts_for_currency_" + selectedCurrency + (isRecurring? '_monthly' : '_one_time')));
            var radioButtons = radioButtonsWrapper.find('input[type=radio]');
            if (radioButtons.length === 1)
                radioButtons.attr('checked', true);
            else
                radioButtonsWrapper.find('[data-default=true]').attr('checked', true);
            radioButtonsWrapper.show();
        }).change();

        donationModule.find('input, select').bind('focus blur', function() {
            $(this).closest('fieldset').toggleClass('active');
        });


        donationModule.find("input[name='action_info[is_recurring]']").change(function () {
            var isRecurring = $(this).val() === "true";
            var parentFieldset = $(this).closest('fieldset');
            parentFieldset.find(".suggested_amounts_wrapper").hide();
            var selectedCurrency = $(parentFieldset).find('#action_info_currency, #paypal_donation_currency').val();
            var radioButtonsWrapper = parentFieldset.find(".amounts_for_currency_" + selectedCurrency + (isRecurring? '_monthly' : '_one_time'));
            var radioButtons = radioButtonsWrapper.find('input[type=radio]');
            if (radioButtons.length === 1)
                radioButtons.attr('checked', true);
            else
                radioButtonsWrapper.find('[data-default=true]').attr('checked', true);
            radioButtonsWrapper.show();

            donationModule.find(".suggested_amount_other").find('input[type=number]').val("");
        });

        $('#action_form.donation').click(function() {
            var currency = $(this).find('#action_info_currency').val();
            var amount = $(this).find('[name="action_info[amount_for_' + currency + ']"]:checked').val();
            var other = $(this).find('#action_info_other_amount_for_' + currency);
            if (amount === 'other') {
                other.attr('required', true);
                other.attr('pattern', '^[0-9]+$').rules('add', 'patternAttribute');
            } else {
                other.removeAttr('required');
                other.removeAttr('pattern').rules('remove', 'patternAttribute');
            }

            var recurring_other = $(this).find('#action_info_recurring_other_amount_for_' + currency);
            if (amount === 'recurring_other') {
                recurring_other.attr('required', true);
                recurring_other.attr('pattern', '^[0-9]+$').rules('add', 'patternAttribute');
            } else {
                recurring_other.removeAttr('required');
                recurring_other.removeAttr('pattern').rules('remove', 'patternAttribute');
            }

            //rules for amex/USD
            var card_number = $('#action_info_card_number',$(this));
            card_number.rules('add',{
                amexValidation: true,
                messages: {
                    amexValidation:card_number.attr('invalid_msg')
                }
            });

            setRequiredRuleToFieldsIn($(this).find('.name_on_card'), true);
            setRequiredRuleToFieldsIn($(this).find('.card_number'), true);
            setRequiredRuleToFieldsIn($(this).find('.card_expiration_month'), true);
            setRequiredRuleToFieldsIn($(this).find('.card_expiration_year'), true);
            setRequiredRuleToFieldsIn($(this).find('.card_cvv2'), true);
            addAmexValidation();
            AO.validations.hookValidationsTo($(this));

        });

        $('#action_form.donation').submit(function() {
            addSelectedAmountToForm($(this), 'action_info', $(this));
        });

        $('#paypal_donation').click(function() {
            var form = $('#action_form.donation');
            var currency = form.find('#action_info_currency').val();
            var amount = form.find('[name="action_info[amount_for_' + currency + ']"]:checked').val();
            var other = form.find('#action_info_other_amount_for_' + currency);
            if (amount === 'other') {
                other.attr('required', true);
                other.attr('pattern', '^[0-9]+$').rules('add', 'patternAttribute');
                amount = other.val();
            } else if (other.length) {
                other.removeAttr('required');
                other.removeAttr('pattern').rules('remove', 'patternAttribute');
            }
            var recurring_other = form.find('#action_info_recurring_other_amount_for_' + currency);
            if (amount === 'recurring_other') {
                recurring_other.attr('required', true);
                recurring_other.attr('pattern', '^[0-9]+$').rules('add', 'patternAttribute');
                amount = recurring_other.val();
            } else if (recurring_other.length) {
                recurring_other.removeAttr('required');
                recurring_other.removeAttr('pattern').rules('remove', 'patternAttribute');
            }
            var name_on_card = form.find('.name_on_card');
            name_on_card.find('input').removeClass('error');
            setRequiredRuleToFieldsIn(name_on_card, false);

            var card_number = $('#action_info_card_number');
            card_number.rules('remove','amexValidation');
            setRequiredRuleToFieldsIn(form.find('.card_number'), false);
            setRequiredRuleToFieldsIn(form.find('.card_expiration_month'), false);
            setRequiredRuleToFieldsIn(form.find('.card_expiration_year'), false);
            setRequiredRuleToFieldsIn(form.find('.card_cvv2'), false);
            addAmexValidation();
            AO.validations.hookValidationsTo(form);


            if ($('#action_form.donation').valid()) {
                var plan = form.find('#action_info_is_recurring_true:checked').length ? 'monthly' : 'one_off';
                var action = $('#action_internal_id').val();
                var recurly_account = $('#recurly_account').val();
                var email_field = form.find('input#member_info_email');
                var email = email_field.val();

                paypal_donation_form = $('#paypal_donation_form');

                // Post '#action_form.donation' fields to '#paypal_donation_form'
                $('#classification', form).clone().appendTo("#hidden_paypal_donation_fields");
                $('input[name="action_info[is_recurring]"]').clone().appendTo("#hidden_paypal_donation_fields");
                $('select[name="action_info[currency]"]').clone().appendTo("#hidden_paypal_donation_fields");
                email_field.clone().appendTo("#hidden_paypal_donation_fields");
                addSelectedAmountToForm(form, 'action_info', "#hidden_paypal_donation_fields");

                var member_info = { email: email };
                $.each(memberFieldMap, function (key, value) {
                    var val = $(memberFieldMap[key].fieldWrapper).find(':input').val();
                    if (val) {
                        member_info[memberFieldMap[key].memberField] = val;
                        // Post '#action_form.donation' fields to '#paypal_donation_form'
                        $(memberFieldMap[key].fieldWrapper).find(':input').clone().appendTo("#hidden_paypal_donation_fields");
                    }
                });
                $.cookie.json = true;
                $.cookie('member_info', member_info, { expires : 1 });

                paypal_donation_form.submit();
            }
            return false;
        });

        function addSelectedAmountToForm(amount_source_form, fieldset, amount_dest_form) {
            var currency = amount_source_form.find('#'+ fieldset +'_currency').val();
            var amount = amount_source_form.find('[name="'+ fieldset +'[amount_for_' + currency + ']"]:checked').val();
            if (amount === 'other') amount = amount_source_form.find('#' + fieldset + '_other_amount_for_' + currency).val();
            if (amount === 'recurring_other') amount = amount_source_form.find('#' + fieldset + '_recurring_other_amount_for_' + currency).val();

            var amountInput = amount_source_form.find('input[type="hidden"][name="'+ fieldset +'[amount]"]');
            if (!amountInput.length) amountInput = $('<input type="hidden" name="'+ fieldset +'[amount]">').appendTo(amount_dest_form);
            amountInput.val(amount);
        }

        $('.suggested_amount_other').find('input[type="number"]').focus(function (e) {
            $(this).parents('span').find('input[type=radio]').attr('checked', 'checked').trigger('change');
        });

        var detectType = function () {
            var images = $('p.card-image img');

            images.removeClass('nomatch').removeClass('match');

            var cardType = getCardType($(this).val());

            if (cardType != 'Unknown') {
                images.filter('img[alt="' + cardType + '"]').addClass('match');
                images.filter('img[alt!="' + cardType + '"]').addClass('nomatch');

            }
            //call validation rules on card number
            $('#action_info_card_number').valid();
        }

        $('#action_info_card_number').keydown(detectType).keyup(detectType);
    }

    function hidePostcodeFieldDependingOnUsersCountry() {
        var postCodeFieldWrapper = '.field_wrapper.postcode';

        var actionForm = root.find('#action_form');

        setupCountryAndPostcodeFields(
            actionForm.find('.field_wrapper.country'),
            actionForm.find('.field_wrapper.postcode')
        );

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
