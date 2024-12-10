module UserLoginHelpers
  def login_user(user)
    expect(page).to have_field('Email')
    expect(page).to have_field('Password')
    expect(page).to have_button('Sign in')

    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password

    click_button 'Sign in'

    sleep 3
  end
end
