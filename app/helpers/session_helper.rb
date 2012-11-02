module SessionHelper
  def is_admin?
    user = User.load(session[:user])
    user.admin?
  end

  #return true if there is only one admin left, false otherwise
  def is_last_admin?
    count = 0
    users = User.list
    users.each do |u, url|
      user = User.load(u)
      if user.admin
        count = count + 1
        return false if count == 2
      end
    end
    true
  end

  #whether or not the user should be able to edit a user's admin status
  def can_edit_admin?(user)
    # only admins can edit flag
    if is_admin?
      # an admin can edit other users flag
      if user != session[:user]
        true
      # an admin can edit their own flag if they are not the last admin
      elsif is_last_admin?
        false
      end
    else
      false
    end
  end
end
