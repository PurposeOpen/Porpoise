module Porpoise
  class ContentPagesController < ApplicationController
    remote_resource_class Platform::ContentPage

    after_filter :allow_preview_from_other_domains, only: :preview

    def show
      fetch_cache(request.fullpath) do
        @page = Platform::ContentPage.find(params[:content_page])
        @member = Platform::Member.new
        possible_template = "content_pages/#{params[:content_page]}"
        @resource_type = params[:content_page]
        if(@page.type == 'ActionPage')
          redirect_to action_path(params[:content_page], :locale => params[:locale])
          return
        end

        if template_exists?(possible_template)
          render :template => possible_template
        else
          render :template => "content_pages/show"
        end
      end
    end

    def preview
      @page = Platform::ContentPage.find_preview(params['content_page'])
      possible_template = "content_pages/#{params[:content_page]}"
      @member = Platform::Member.new
      if template_exists?(possible_template)
        @template = possible_template
      end
    end
  end
end