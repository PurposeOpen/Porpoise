$AO.content_pages = {
  show_about:function () {
    if ($.browser.mozilla) {
        $('#remote_join label.field_name').css({'left':'10px'});
    }

    AO.validations.hookValidationsTo('#remote_join');
    $AO.home.methods.common.hideRemoteEmailLabelIfFieldHasValue();

    /* about page press release accordions */
    var about_accordion = function () {
        var parent = $(this).closest('.release');
        var button = parent.find('.expand_button');
        if (button.hasClass("close")) {
            parent.find('.release_body').hide(200);
            button.removeClass('close').addClass('expand');
        } else {
            parent.find('.release_body').show(200);
            button.removeClass('expand').addClass('close');
        }
        ;
        return false;
    };
    $('#press-releases-placeholder').append($('#press_releases'));
    $('#press_releases #collection .release .accordion').click(about_accordion);
    $('#press_releases .release .title a').click(about_accordion);
  }
};

$AO.home = {
    index: function () {
        AO.validations.hookValidationsTo('#remote_join');

        var index_methods = $.extend(this.methods.common, this.methods.index);
        var common_methods = $AO.methods.common;

        index_methods.hideRemoteEmailLabelIfFieldHasValue();

        /* callouts for the carousel */
        //split into line spans around <br>, add extra spans at end for angled lines
        $('#callout_boxes .item .callout .title a').lettering('lines').find('span').prepend('<span class="start">&nbsp;</span>').append('<span class="end">&nbsp;</span>');
        $('#callout_boxes .item .callout .title a').find('span.line2').before('<br />');

        /* featured items on the home page */
        // $('#featured .action .title a').lettering('lines').find('span').append('<span class="end">&nbsp;</span>');
        // $('#featured .action .title a').find('span.line2').before('<br />');
        // $('#featured .action .image .excerpt').addClass('bg-stripe-light');

        /* carousel */
        var $timeoutId;

        $('#carousel').each(function () {

            $(this).find('.item .bg').each(function () {
                common_methods.bgStretch($(this));
            });

            common_methods.bgOverlay($(this));

            //initialize the carousel
            if ($(this).find('> .item').size() > 1) {
                index_methods.initializeCarousel($(this));
            }
        });

        /* carousel controls */
        $('#carousel_controls a').click(function () {
            return false;
        });
        $('#carousel_controls').mouseover(function () {
            index_methods.stopCarousel();
        });
        $('#carousel_controls').mouseleave(function () {
            index_methods.startCarousel();
        });
        $('#carousel_controls #previous').click(function () {
            index_methods.prevCarouselItem();
        });
        $('#carousel_controls #next').click(function () {
            index_methods.rotateCarousel();
            index_methods.stopCarousel();
        });
        $('#carousel_controls .control').click(function () {
            index_methods.jumpCarousel($(this));
        });

        /* activity feeds */
        if($('body').attr('data-enable-activity-feed') == 'true') {
            $('#recent_actions').activityFeed(5, '#recent_action_template');
        };
    },

    methods:{

        common:{

            hideRemoteEmailLabelIfFieldHasValue:function () {
                $('#remote_join_email').each(function () {
                    console.log("####################### " + $(this).val());
                    if (!$(this).val() == '') {
                        $(this).siblings('label.field_name').hide();
                    }
                });
            }

        },

        index:{

            initializeCarousel:function (el) {
                el.children('.item0').show().addClass('current');

                $('#callout_boxes').children('.item0').show().addClass('current');

                $('#carousel_controls').find('.item0').parent('.control').css('background-position', '0px 32px');

                $timeoutId = setTimeout("$AO.home.methods.index.rotateCarousel()", 8000);
            },

            stopCarousel:function () {
                clearTimeout($timeoutId);
            },

            startCarousel:function () {
                $timeoutId = setTimeout("$AO.home.methods.index.rotateCarousel()", 8000);
            },

            rotateCarousel:function () {
                var index_methods = $AO.home.methods.index;
                // slides
                var carousel = $('#carousel');
                var current_slide = carousel.children('.current');
                var next_slide = current_slide.next('.item');

                index_methods.resetSlides(carousel, current_slide);

                if (next_slide.size() > 0) {
                    next_slide.css('z-index', 0).show();
                } else {
                    next_slide = carousel.children('.item:first');
                    next_slide.css('z-index', 0).show();
                }

                current_slide.fadeOut(1000, function () {
                    $(this).removeClass('current').css('z-index', '-999999');
                    next_slide.addClass('current').css('z-index', 'auto');
                });

                // callouts
                var current_slide_class = '.' + current_slide.attr('class').split(' ')[1];

                var callouts = $('#callout_boxes');
                var current_callout = callouts.children(current_slide_class);

                index_methods.resetCallouts(callouts, current_callout);

                current_callout.fadeOut(500, function () {
                    $(this).removeClass('current').css('z-index', '-999999');

                    var next_callout = $(this).next('.item');

                    if (next_callout.size() == 0) {
                        next_callout = callouts.children('.item:first');
                    }
                    next_callout.addClass('current').css('z-index', 'auto').fadeIn(500);
                });

                // controls
                index_methods.liveCarouselControl(next_slide);

                $timeoutId = setTimeout("$AO.home.methods.index.rotateCarousel()", 8000);
            },

            jumpCarousel:function (control) {
                var index_methods = $AO.home.methods.index;
                var item_class = '.' + control.children('span').attr('class');

                // slides
                var carousel = $('#carousel');
                var current_slide = carousel.children('.current');
                var requested_slide = carousel.children(item_class);

                index_methods.resetSlides(carousel, current_slide);

                requested_slide.css('z-index', 0).show();

                current_slide.fadeOut(1000, function () {
                    $(this).removeClass('current').css('z-index', '-999999');
                    requested_slide.addClass('current').css('z-index', 'auto').show();
                });

                // callouts
                var current_slide_class = '.' + current_slide.attr('class').split(' ')[1];

                var callouts = $('#callout_boxes');
                var current_callout = callouts.children(current_slide_class);

                index_methods.resetCallouts(callouts, current_callout);

                current_callout.fadeOut(500, function () {
                    $(this).removeClass('current').css('z-index', '-999999');

                    var requested_callout = callouts.children(item_class);
                    requested_callout.addClass('current').css('z-index', 'auto').fadeIn(500);
                });

                // controls
                index_methods.liveCarouselControl(requested_slide);
            },

            prevCarouselItem:function () {
                var index_methods = $AO.home.methods.index;
                // slides
                var carousel = $('#carousel');
                var current_slide = carousel.children('.current');
                var previous_slide = current_slide.prev('.item');

                index_methods.resetSlides(carousel, current_slide);

                if (previous_slide.size() > 0) {
                    previous_slide.css('z-index', 0).show();
                } else {
                    previous_slide = carousel.children('.item:last');
                    previous_slide.css('z-index', 0).show();
                }

                current_slide.fadeOut(1000, function () {
                    $(this).removeClass('current').css('z-index', '-999999');
                    previous_slide.addClass('current').css('z-index', 'auto');
                });

                // callouts
                var current_slide_class = '.' + current_slide.attr('class').split(' ')[1];

                var callouts = $('#callout_boxes');
                var current_callout = callouts.children(current_slide_class);

                index_methods.resetCallouts(callouts, current_callout);

                current_callout.fadeOut(500, function () {
                    $(this).removeClass('current').css('z-index', '-999999');

                    var previous_callout = $(this).prev('.item');

                    if (previous_callout.size() == 0) {
                        previous_callout = callouts.children('.item:last');
                    }
                    previous_callout.addClass('current').css('z-index', 'auto').fadeIn(500);
                });

                // controls
                index_methods.liveCarouselControl(previous_slide);
            },

            liveCarouselControl:function (slide) {
                var live_slide_class = '.' + slide.attr('class').split(' ')[1];
                var carousel_controls = $('#carousel_controls .control');
                carousel_controls.css('background-position', '0px 0px');
                carousel_controls.find(live_slide_class).parent('.control').css('background-position', '0px 32px');
            },

            resetCallouts:function (callouts, current_callout) {
                callouts.children('.item').hide();
                current_callout.show();
            },

            resetSlides:function (carousel, current_slide) {
                carousel.children('.item').hide();
                current_slide.css('z-index', 1).show();
            }
        }

    }
};
