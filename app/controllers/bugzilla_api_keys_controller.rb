class BugzillaApiKeysController < ApplicationController
  def edit
    @user = User.find( params['user_id'] )
  end

  def update
    @user = User.find( params['user_id'] )
    if @user.update(bugzilla_api_key_params)
      redirect_to escalations_user_path(@user)
    else
      render :edit
    end
  end

  private

  def bugzilla_api_key_params
    params.require('bugzilla_api_key').permit('bugzilla_api_key')
  end
end
