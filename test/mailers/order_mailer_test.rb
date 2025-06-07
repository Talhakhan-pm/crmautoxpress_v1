require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  test "confirmation" do
    mail = OrderMailer.confirmation
    assert_equal "Confirmation", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "shipping_notification" do
    mail = OrderMailer.shipping_notification
    assert_equal "Shipping notification", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "follow_up" do
    mail = OrderMailer.follow_up
    assert_equal "Follow up", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
