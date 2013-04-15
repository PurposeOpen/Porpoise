$AO.tafs = {
  show: function() {
		
	},
	
	methods: {

		recordShare: function(share_url, page_id, user_id, share_type)
		{
			$.ajax(share_url,
			 { type: "POST",
			   data: {page_id: page_id, user_id: user_id,
			    share_type: share_type}});
		},

		initializeTafSharing: function(params)
		{
			var taf_methods = $AO.tafs.methods;
			
			var share_url = params['share_url'];
			var page_id = params['page_id'];
		  var user_id = params['user_id'];
			var fb_share_link = $('#fb_share_this');
			var twitter_submit_button = $('#twitter_submit_button')
			var email_submit_link = $('#email_link')


			fb_share_link.click(function () {
				taf_methods.recordShare(share_url, page_id, user_id, "facebook");
			});

			twitter_submit_button.click(function () {
				taf_methods.recordShare(share_url, page_id, user_id, "twitter");
				return true;
			});

			email_submit_link.click(function () {
				taf_methods.recordShare(share_url, page_id, user_id, "email");
			});
		}
		
	}
}