module Porpoise::ApplicationHelper

  def social_links(follow_text=true)
    links = @movement.follow_links.attributes
    html = ''

    ['facebook', 'twitter', 'youtube', 'tumblr', 'flickr', 'orkut'].each do |site|
      unless links[site].blank?
        html += link_to site.titleize, links[site], {:target => '_blank', :class => site}
      end
    end

		if follow_text
      html.insert(0, t('follow_us') + ": ") unless html.blank?
    end
    html.html_safe
  end

  def fb_image
    "//#{request.host_with_port}/assets/fb_logo.jpg"
  end

  def opt_in_fields(form)
    capture do
      concat form.hidden_field :opt_in_ip_address, value: request.remote_ip 
      concat form.hidden_field :opt_in_url, value: request.original_url
    end
  end
end
