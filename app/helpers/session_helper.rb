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
end
