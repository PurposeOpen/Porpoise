module Porpoise
  class MembersController < ApplicationController
    remote_resource_class Platform::Member

    def index
      redirect_to root_path(:locale => I18n.locale)
    end

    def create
      @member = Platform::Member.new(params[:member_info])
      @member.save!

      session[:member_id] = @member.attributes['member_id'].to_i if @member.attributes['member_id'].present?
      redirect_to @member.attributes["next_page_identifier"].present? ?
                      action_path(I18n.locale, @member.next_page_identifier, :params => {:t => params[:t], :email => @member.email}) :
                      root_path(:locale => I18n.locale)

    rescue ActiveResource::ResourceInvalid
      redirect_to action_path(I18n.locale, 'join')
    end
  end
end