$(function() { 
            var url = window.location.href;
            var results = new RegExp("[\\?&]video=([^&#]*)").exec(url);

			var breakpointWidth = 600;
            var mobileApplied = 0;
            $(window).bind('enterBreakpoint600',function() {
                if (mobileApplied == 1) {
				unmobilizeTAF();
                hideTinyNav();
                }
			});
			$(window).bind('exitBreakpoint600',function() {
				mobilizeTAF();
                showTinyNav();
                mobileApplied = 1;
			});
			
			$(window).setBreakpoints({breakpoints: [ 600 ]});
			
			var width = $(window).width();
			if (width < 600) {
				mobilizeTAF();
                showTinyNav();
                mobileApplied = 1;
			}
		});

function mobilizeTAF() {
    $("#logo a").attr("href", "#");
    if ($("#goal_ask")) {
        $("#goal_ask").insertAfter("#taf #taf_options h2");
        $goal_ask_bottom_border = $("<div id='goal_ask_bottom_border'></div>");
        $($goal_ask_bottom_border).insertAfter("#goal_ask");
    }
    $("#email_holder #email_link").wrap("<div id='email_button_holder'></div>");
	$("#fb_share_button_text").html("Facebook");
    $("input#twitter_submit_button").attr("value", "Twitter");
    $("#taf_options #email_holder #email_share_button_text").html("Email");	

    $(".section_actions .grid_12 #header_container").hide();
    $(".alpha").hide();
}


function unmobilizeTAF() {
    $("#fb_share_button_text").html("Share");
    $("input#twitter_submit_button").attr("value", "Tweet it");
    $("#taf_options #email_holder #email_share_button_text").html("Email your friends");
    $("#email_holder #email_link").unwrap();
    if ($("#goal_ask")) {
        $("#goal_ask").insertAfter("#petition_counter+.clear");
        $("#goal_ask_bottom_border").remove();
    }

    $(".section_actions .grid_12 #header_container").show();
    $(".alpha").show();
}

function showTinyNav() {
    $("header > #languages > ul").tinyNav({ active: 'selected', header: true });
}

function hideTinyNav() {
    $("header > #languages > select.tinynav").css("display", "none");
}