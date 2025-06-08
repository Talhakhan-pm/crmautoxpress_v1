user = User.find_by(email: 'murtaza@autoxpress.com')
if user
  user.update!(dialpad_user_id: '5503393985740800')
  puts "✅ Updated #{user.email} with Dialpad ID: #{user.dialpad_user_id}"
else
  puts "❌ User not found: murtaza@autoxpress.com"
end

puts "\nCurrent users with Dialpad IDs:"
User.where.not(dialpad_user_id: nil).each do |u|
  puts "#{u.email}: #{u.dialpad_user_id}"
end