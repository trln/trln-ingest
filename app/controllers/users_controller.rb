class UsersController < ApplicationController
  protect_from_forgery unless: -> { request.format.json? }
  before_action :authenticate_user!
  before_action :set_user, except: [:index]
  before_action :confirm_admin_or_self!

  attr_reader :user, :resource, :resource_name

  def index
    @users = User.paginate(page: params[:page], per_page: 10).order('email')
    render 'devise/admin/index'
  end

  # GET
  def show
    render 'devise/admin/edit', locals: {resource: @user, resource_name: 'User'}
  end

  def set_user
    if params['id'] == 'me'
      @user = current_user
    else
      @user = User.find(params[:id])
    end
    @resource = @user
    @resource_name = 'User'
  end

  def update
    form_params = params['Users']
    logger.info "Params: #{form_params}"
    new_admin_value = form_params['admin'] == '1' ? true : false
    @user.update(admin: new_admin_value)
    key = new_admin_value ? :success : :info
    flash[key] = "#{@user.email} is #{new_admin_value ? 'now' : 'no longer'} an administrator"
    redirect_to @user
  end

  def new_token!
    token = Devise.friendly_token
    @user.update(authentication_token: token)
    render plain: token
  end

  private

  def confirm_admin_or_self!
    raise ActionController::RoutingError.new('Forbidden') unless current_user.admin? || current_user == @user
  end
end
