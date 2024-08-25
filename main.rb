LIMIT_PER_WORKSHOP = 40

require 'csv'

# Load the data from CSV
participants = []
names_seen = {}

CSV.foreach('input.csv', headers: true) do |row|

  name = row['Your Full Name (Teen\'s Name)'].strip.capitalize
  email = row['Your Email']
  gender = row['Gender']

  # input.csv format:
  # Submission ID,Respondent ID,Submitted at,Your Full Name (Teen's Name),Your Email,Rank/Order Your Choices
  # PgYbzQ,l0WyWk,2024-08-11 23:25:40,Testing,test@me.com,"Eucharistic Miracles, Science & Religion, Catholic Femininity, Catholic Masculinity, How to Pray, Salvation History"

  # Order by latest submission date first to make their last preferences count vs their first

  unless names_seen[name]
    participants << {
      id: row['Respondent ID'] || '123',
      name: name,

      # random email if we don't have one
      email: email || "#{name.downcase.gsub(' ', '_')}@example.com",
      
      # if no preferences, assign them to a random workshop based on least popular
      preferences: row['Rank/Order Your Choices']&.split(', ') || ["Science & Religion", "Salvation History"],

      gender: gender
    }

    names_seen[name] = true
  end
end


# Initialize workshop slots for both days
# Order here is important to assign participants to the first available 
# workshop when their preferences are full. Order this based on the least popular first
# to fill those up first.
workshops = {
  "Catholic Femininity" => { "Sunday" => [] },
  "Catholic Masculinity" => { "Sunday" => [] },
  "Eucharistic Miracles" => { "Saturday" => [] },
  "How to Pray" => { "Saturday" => [] },
  "Salvation History" => { "Saturday" => [], "Sunday" => [] },
  "Science & Religion" => { "Saturday" => [], "Sunday" => [] },
}

# Function to allocate workshops ensuring one on each day
def allocate_workshops(participants, workshops)
  participants.each do |participant|
    saturday_assigned = false
    sunday_assigned = false

    # if they are a male, remove Catholic Femininity from their preferences
    if participant[:gender] == 'M'
      participant[:preferences].delete('Catholic Femininity')
    end

    # if they are a female, remove Catholic Masculinity from their preferences
    if participant[:gender] == 'F'
      participant[:preferences].delete('Catholic Masculinity')
    end

    # loop through each of the participant's preferences list
    participant[:preferences].each do |choice|
      if !saturday_assigned && workshops[choice]["Saturday"] && workshops[choice]["Saturday"].length < LIMIT_PER_WORKSHOP
        workshops[choice]["Saturday"] << participant
        saturday_assigned = true
      elsif !sunday_assigned && workshops[choice]["Sunday"] && workshops[choice]["Sunday"].length < LIMIT_PER_WORKSHOP
        workshops[choice]["Sunday"] << participant
        sunday_assigned = true
      end

      # Break if both days are assigned
      break if saturday_assigned && sunday_assigned
    end

    # If unable to assign one or both days, handle fallback logic here
    unless saturday_assigned
      # Assign to any available Saturday workshop
      workshops.each do |workshop, days|
        next if participant[:gender] == 'M' && workshop == 'Catholic Femininity'
        next if participant[:gender] == 'F' && workshop == 'Catholic Masculinity'

        if days["Saturday"] && days["Saturday"].length < LIMIT_PER_WORKSHOP
          days["Saturday"] << participant
          saturday_assigned = true
          break
        end
      end
    end

    unless sunday_assigned
      # Assign to any available Sunday workshop
      workshops.each do |workshop, days|
        next if participant[:gender] == 'M' && workshop == 'Catholic Femininity'
        next if participant[:gender] == 'F' && workshop == 'Catholic Masculinity'

        # skip if they have been allocated to the same workshop on Saturday
        if (days["Sunday"] && days["Sunday"].length < LIMIT_PER_WORKSHOP) && (days["Saturday"] && !days["Saturday"].include?(participant))
          days["Sunday"] << participant
          sunday_assigned = true
          break
        end
      end
    end
  end
end

# Call the allocation function
allocate_workshops(participants, workshops)

# Output the allocation results to the console (or save to a file)
workshops.each do |workshop, days|
  puts "\n\n"
  puts "Workshop: #{workshop}"
  days.each do |day, attendees|
    puts "\n"
    puts "  #{day}: #{attendees.length}"
    attendees.each do |attendee|
      puts "    #{attendee[:name]} (#{attendee[:email]})"
    end
  end
end

puts "\n\n\n"
puts "---------------------------------"
puts "\n\n\n"

# Output the allocation based on each participant
participants.each do |participant|
  puts "\n"
  puts "#{participant[:name]} (#{participant[:email]})"
  participant[:preferences].each do |choice|
    if workshops[choice]["Saturday"] && workshops[choice]["Saturday"].include?(participant)
      puts "  Saturday: #{choice}"
    end

    if workshops[choice]["Sunday"] && workshops[choice]["Sunday"].include?(participant)
      puts "  Sunday: #{choice}"
    end
  end
end


puts "\n\n\n"
puts "---------------------------------"
puts "\n\n\n"


# Write the output to a CSV files
Dir.mkdir('output') unless Dir.exist?('output')

# Write attendance lists for each workshop
workshops.each do |workshop, days|
  days.each do |day, attendees|
    filename = "output/#{workshop.gsub(' ', '_')}_#{day}_attendance.csv"
    CSV.open(filename, 'wb') do |csv|
      csv << ["#{workshop} (#{day})", "Participant Name", "Email"]
      attendees.each do |participant|
        csv << [nil, participant[:name], participant[:email]]
      end
    end

    puts "Attendance lists for #{workshop} (#{day}) created."
  end
end

# Write the participant allocation to a CSV file
CSV.open('output/participants.csv', 'wb') do |csv|
  csv << ['Participant Name', 'Email', 'Saturday Workshop', 'Sunday Workshop']

  participants.each do |participant|
    saturday_workshop = ""
    sunday_workshop = ""

    participant[:preferences].each do |choice|
      if workshops[choice]["Saturday"] && workshops[choice]["Saturday"].include?(participant)
        saturday_workshop = choice
      end

      if workshops[choice]["Sunday"] && workshops[choice]["Sunday"].include?(participant)
        sunday_workshop = choice
      end
    end

    csv << [participant[:name], participant[:email], saturday_workshop, sunday_workshop]
  end

  puts "Participant allocation list created."
end
