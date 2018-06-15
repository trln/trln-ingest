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

    approved = { previous: @user.approved }
    institution = { new: form_params['primary_institution'], previous: @user.primary_institution }
    admin = { previous: @user.admin }
    approved[:new] = form_params['approved'] == '1'
    admin[:new] = form_params['admin'] == '1'

    flashes = { success: [], info: [] }

    if approved[:new]
      flashes[:success] << 'Account has been approved' unless approved[:previous]
    else
      flashes[:info] << 'Account has been disapproved' if approved[:previous]
    end

    flashes[:info] << 'Institution changed' if institution[:new] != institution[:previous]

    if admin[:new]
      flashes[:success] << "#{@user.email} is now an administrator" unless admin[:previous]
    else
      flashes[:info] << "#{@user.email} is no longer an administrator" if admin[:previous]
    end
    flashes.each { |k, msgs| flash[k] = msgs.join('<br>') unless msgs.empty? }

    changed = admin[:previous] != admin[:new] || approved[:previous] != approved[:new] || institution[:prevous] != institution[:new]
    unless changed
      flash[:info] = 'No changes were made'
      return redirect_to @user
    end

    @user.update(
      admin: admin[:new],
      approved: approved[:new],
      primary_institution: institution[:new]
    )
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
