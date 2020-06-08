namespace :users do
  desc 'Create a new user'
  task create: :environment do
    cli = HighLine.new

    cli.say 'Please complete the wizard to create a new MBIS user...'

    begin
      email = cli.ask 'Email address:'
      p1    = cli.ask('Password:') { |q| q.echo = false }
      p2    = cli.ask('Confirm:')  { |q| q.echo = false }

      user = User.new(email: email, password: p1, password_confirmation: p2)
      user.save!
    rescue ActiveRecord::RecordInvalid
      cli.say 'User was invalid:'
      user.errors.full_messages.each { |msg| cli.say ' -' << msg }

      retry if cli.ask('Try again? (y/n)', lambda { |str| str =~ /^y/i })
    end
  end

  desc 'Unlocks an existing user'
  task unlock: :environment do
    cli = HighLine.new

    begin
      email = cli.ask 'Email address of user to unlock:'

      user = User.where(email: email).first!
      user.unlock_access!

      cli.say 'User unlocked!'
    rescue ActiveRecord::RecordNotFound
      cli.say "Could not find user with email: #{email}"
      retry if cli.ask('Search again? (y/n)', lambda { |str| str =~ /^y/i })
    end
  end

  # Migrate has_one team delegate user to has_many delegate users
  desc 'Add existing delegate user to has many model'
  task migrate_delegate_user: :environment do
    counter = 0
    Team.all.each do |team|
      next if team.delegate_approver.nil?
      puts team.name
      counter += 1
      team.delegate_users << User.find(team.delegate_approver)
      team.save!
    end
    puts "#{counter} delegate approvers migrated"
  end
end
