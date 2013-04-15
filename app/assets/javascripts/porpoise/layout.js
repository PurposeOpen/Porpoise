$(function() { 
			var breakpointWidth = 600;
            var mobileApplied = 0;
            $(window).bind('enterBreakpoint600',function() {
                if (mobileApplied == 1) {
				removeMobile();	
                hideTinyNav();
                }
			});
			$(window).bind('exitBreakpoint600',function() {
				addMobile();
                showTinyNav();
                mobileApplied = 1;
			});
			
			$(window).setBreakpoints({breakpoints: [ 600 ]});
			
			var width = $(window).width();
			if (width < 600) {
				addMobile();
                showTinyNav();
                mobileApplied = 1;
			}			
		});

function addMobile() {
    if ($("#disabled_content").length ) {
        $("#disabled_content").insertAfter("#goal_ask");
    }
    else {
        $("#logo a").attr("href", "#");
    	$(".grid_6.omega").css("display", "none");
        $button = $("<div class='action-button-container'><button class='action-button'>" + $('input#action_submit').val() + "</button></div>");
    	$button.on("click", showForm);
        $button2 = $("<div style='margin-bottom:10px;' class='action-button-container'><button class='action-button'>" + $('input#action_submit').val() + "</button></div>");
    	$button2.on("click", showForm);
    	$($button).insertBefore(".media_wrapper:nth-of-type(2)");	
        $($button2).insertAfter(".media_wrapper:last-of-type");
        if ($("#explanatory_text")) {
            $("#explanatory_text").insertBefore("#petition_counter");
        }
    }
};

function removeMobile() {
    if ($("#disabled_content").length ) {
        $("#disabled_content").prependTo(".grid_6.omega");
    }
    if ($("#explanatory_text")) {
        $("#explanatory_text").append("#side_container");
    }

    $(".grid_6.alpha").css("display", "inline");
	$(".grid_6.omega").css("display", "inline");
	$(".action-button-container").remove();
    $(".dark-stripe-thin.action-more-border").remove();
    $(".action-read-more").remove();
    $(".action-more-border").remove();
    $(".action-back-button").remove();
}

function showForm() {
	$(".grid_6.alpha").css("display", "none");
	$(".grid_6.omega").css("display", "block");
	$(".action").css("display", "block");
	$(".form_wrapper").css("display", "block");
    $("body").animate({ scrollTop : 0 });
	
    var introText;
    var moreText;
    var showMoreTextLink = false;
	var $actionBox = $("#side_container .action");
	var actionHtml = $actionBox.html();
    var splitActionHtml = actionHtml.split(/<br\\?>\s*<br\\?>/im);
    if (splitActionHtml && splitActionHtml.length >= 2) {
        introText = splitActionHtml[0];
        moreText = '';
        for (i = 1; i < splitActionHtml.length; i++) {
            moreText = moreText + '<br/><br/>' + splitActionHtml[1];
        }
        showMoreTextLink = true;
    }	

    if (showMoreTextLink) {
    	var $wrappedMoreText = $("<span class='action-more'>" + moreText + "</span>");
    	$actionBox.html(introText);
        if ($("body.locale_en").length) {
            var $readMore = $("<div class='action-read-more'><div class='action-read-more-button'>Read more</div></div>");
        }
        else if ($("body.locale_es").length) {
            var $readMore = $("<div class='action-read-more'><div class='action-read-more-button'>Más información</div></div>");
        }
        else if ($("body.locale_fr").length) {
            var $readMore = $("<div class='action-read-more'><div class='action-read-more-button'>En savoir plus</div></div>");
        }
        else if ($("body.locale_pt").length) {
            var $readMore = $("<div class='action-read-more'><div class='action-read-more-button'>Mais informações</div></div>");
        }
    	$readMore.on("click", function() { 
    		$wrappedMoreText.show(); 
    		$readMore.hide();
    	});
    	
    	$actionBox.append($readMore);
    	$actionBox.append($wrappedMoreText);
    }

    $(".grid_6.omega section.action").append("<div style='margin-top:10px;' class='dark-stripe-thin action-more-border'></div>");
	$("#action_submit").wrap("<div id='member_action_submit_wrap' style='text-align: center; clear: both;'>");
    $(".section_petitions #new_member_action #optin").insertAfter('#member_action_submit_wrap');
    
    
	if ($("body.locale_en").length) {
        var $backButton = $("<div style='margin-bottom:10px;' class='action-back-button'>< Back</div>");
    }
    else if ($("body.locale_es").length) {
        var $backButton = $("<div style='margin-bottom:10px;' class='action-back-button'>< Atrás</div>");
    }
    else if ($("body.locale_fr").length) {
        var $backButton = $("<div style='margin-bottom:10px;' class='action-back-button'>< Retour</div>");
    }
    else if ($("body.locale_pt").length) {
        var $backButton = $("<div style='margin-bottom:10px;' class='action-back-button'>< Atrás</div>");
    }
    $($backButton).insertAfter(".grid_6.omega");
    $backButton.on("click", function() { 
		removeForm();
	});
}

function removeForm() {
    $(".grid_6.alpha").css("display", "inline");
	$(".grid_6.omega").css("display", "none");
    $(".action-read-more").remove();
    $(".action-more-border").remove();
    $(".action-back-button").remove();
}