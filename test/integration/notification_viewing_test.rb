require 'test_helper'

class NotificationViewingTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @odr = users(:odr_user)
    @standard = users(:standard_user)
  end

  test 'admin can see notifications sent to admin group' do
    login_and_accept_terms(@admin)
    create_notification(title: 'new admin notification', admin_users: true)
    visit notifications_path
    assert page.has_content?('new admin notification')
    assert page.has_content?('more')

    expected = 'unread_notification'
    actual   = page.find('#notifications_table').
               find('tr', text: 'new admin notification')[:class]
    assert_equal expected, actual

    assert_equal 1, @admin.user_notifications.unread.count
  end

  test 'notifications get flagged as read when more is clicked' do
    login_and_accept_terms(@admin)
    create_notification(title: 'new admin notification number 2', admin_users: true)
    visit notifications_path
    assert_equal 1, @admin.user_notifications.inbox.count
    assert_equal 1, @admin.user_notifications.unread.count
    row_two = page.find('#notifications_table').find('tr', text: 'new admin notification number 2')
    read_notification(row_two)
    assert_equal 0, @admin.user_notifications.unread.count
    assert_equal 1, @admin.user_notifications.inbox.count
  end

  test 'deleted notifications are hidden' do
    login_and_accept_terms(@admin)
    create_notification(title: 'new admin notification number 3', admin_users: true)
    visit notifications_path
    assert_equal 1, @admin.user_notifications.inbox.count
    assert_equal 1, @admin.user_notifications.unread.count
    assert_equal 0, @admin.user_notifications.deleted.count
    row = page.find('#notifications_table').find('tr', text: 'new admin notification number 3')

    accept_prompt do
      row.click_link('delete_notification')
    end
    
    assert has_content?('Notification deleted')
    assert_equal 0, @admin.user_notifications.inbox.count
    assert_equal 1, @admin.user_notifications.deleted.count
  end

  test 'standard user can see notifications sent to only them' do
    create_notification(title: 'new single user notification', user_id: @standard.id)
    login_and_accept_terms(@standard)
    assert_equal 1, @standard.user_notifications.inbox.count
    visit notifications_path
    new_row = page.find('#notifications_table').find('tr', text: 'new single user notification')
    read_notification(new_row)
    assert_equal 0, @standard.user_notifications.unread.count
  end

  test 'multiple users have independent read status on notifications' do
    login_and_accept_terms(@admin)
    notification = create_notification(title: 'multi admin notification', admin_users: true)
    assert_equal 2, User.administrators.count
    assert_equal 2, notification.user_notifications.unread.count
    visit notifications_path
    multi_row = page.find('#notifications_table').find('tr', text: 'multi admin notification')
    read_notification(multi_row)
    assert_equal 1, notification.user_notifications.unread.count
  end

  test 'odr users can see notifications sent to odr group' do
    notification = create_notification(title: 'multi odr notification', odr_users: true)
    login_and_accept_terms(@odr)
    assert_equal 1, @odr.user_notifications.unread.count
    assert_equal 2, notification.user_notifications.unread.count
    visit notifications_path
    odr_row = page.find('#notifications_table').find('tr', text: 'multi odr notification')
    read_notification(odr_row)
    assert_equal 0, @odr.user_notifications.unread.count
  end

  private

  # Trigger the AJAX call to flag a notification as read, and wait
  # for UI confirmation that this has been done.
  def read_notification(row)
    assert has_css?("##{row['id']}.unread_notification")

    row.click_link('more', match: :first)
    row.click_link('less', match: :first)

    assert has_no_css?("##{row['id']}.unread_notification")
  end
end
