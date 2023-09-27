require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def datetime(datetime)
  daytime = DateTime.strptime(datetime, '%m/%d/%y %H:%M')
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_homephone(homephone)
  homephone = homephone.delete("^0-9")

  if homephone.length == 10
    homephone = homephone
  elsif homephone.length == 11 && homephone[0] == '1'
    homephone = homephone[1..10]
  end

end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

best_day = []
best_time = []

contents.each do |row|
  
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  homephone = clean_homephone(row[:homephone]).to_s
  datetime = datetime(row[:regdate])
  time = best_time.push(datetime.hour)
  day = best_day.push(datetime.strftime("%A"))
  legislators = legislators_by_zipcode(zipcode)


  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end


def best(hash)
  max = hash.values.max
  Hash[hash.select { |k, v| v == max}]
end

day = best(best_day.tally).keys
time = best(best_time.tally).keys

puts "Best day is #{day[0]}"
puts "Best time is #{time[0]} and #{time[1]}"