#!/usr/bin/env ruby
# Grab courses-clean.json from search-and-compare-data repo
# Run './generate.rb'
require 'json'

file = File.read('courses-clean.json')
data = JSON.parse(file)
# provider = 'UCL, University College London (University of London)'
provider = 'Denbigh Teaching School Alliance'
next_cycle = true
courses = data.select {|c| c['provider'] == provider }
abort("No courses found - check the provider name exactly matches one in JSON file") if courses.length.zero?

accredited_courses = data.select {|c| c['accrediting'] == provider }
isAccreditedBody = !courses.first['route'].include?('School Direct')

all_accredited_bodies = data.map {|c| c['accrediting'] }.uniq.compact.sort

# https://stackoverflow.com/questions/164979/uk-postcode-regex-comprehensive
$postcodeRegex = /([Gg][Ii][Rr] 0[Aa]{2})|((([A-Za-z][0-9]{1,2})|(([A-Za-z][A-Ha-hJ-Yj-y][0-9]{1,2})|(([A-Za-z][0-9][A-Za-z])|([A-Za-z][A-Ha-hJ-Yj-y][0-9][A-Za-z]?))))\s?[0-9][A-Za-z]{2})/

def school_data(c)
  c['campuses'].map { |a|
    postalCode = $postcodeRegex.match(a['address'])
    address = a['address'].gsub($postcodeRegex, '')
    addressParts = address.split(', ')
    addressLine1 = addressParts[0]

    if addressParts.length == 2
      addressLevel1 = addressParts[1]
    end

    if addressParts.length == 3
      addressLevel2 = addressParts[1]
      addressLevel1 = addressParts[2]
    end

    if addressParts.length == 4
      addressLine2 = addressParts[1]
      addressLevel2 = addressParts[2]
      addressLevel1 = addressParts[3]
    end

    {
      name: a['name'],
      code: a['code'] == '' ? '-' : a['code'],
      type: a['name'] == 'Main Site' ? 'centre' : 'school',
      'address-line1': addressLine1,
      'address-line2': addressLine2,
      'address-level2': addressLevel2,
      'address-level1': addressLevel1,
      'postal-code': postalCode.to_s
    }
  }
end

def course_qualification(c)
  if c['subjects'].map {|s| s.downcase.capitalize }.include?('Further education')
    return 'PGCE'
  end

  if !c['qualifications'] || c['qualifications'].length == 0
    qual = "Unknown"
  else
    qual = (c['qualifications'].include?('Postgraduate') || c['qualifications'].include?('Professional')) ? 'PGCE with QTS' : 'QTS'
  end

  qual
end

prototype_data = {
  'rolled-over': true,
  'next-cycle': next_cycle,
  # 'allocations-window' options: open, closed, confirmed
  'about-organisation': 'Over the last five years we have trained over 800 trainees across all subjects and in Primary and Secondary phases. The majority of these colleagues are pursuing successful careers in our Trust or Alliance schools; a number of these colleagues have made rapid progress through their careers and hold positions of responsibility.',
  'school-placements': "Our placement schools are chosen for their quality, excellence in supporting teacher education and to provide comprehensive geographical coverage across a wide range of phases, subjects and specialisms.\n\nYou will take a minimum of two placements in different schools (up to 120 days in total), each with a dedicated placement co-ordinating mentor, with both schools carefully matched to your needs in terms of location, stage and subject, taking any mobility needs into account.",
  'training-with-a-disability': 'We want to enable everyone to reach their full potential. After all teaching is the profession that unlocks potential in children. If you do have and declare a disability we will do everything we reasonably can to make special arrangements. Please provide details on your application form so that we can ensure this happens. This will not affect your application.',
  'allocations-window': 'open',
  'multi-organisation': false,
  'ucas-gt12': 'Applicants must confirm their place',
  'ucas-alerts': 'Get an email for each application you receive',
  'training-provider-name': provider,
  'provider-code': courses.first['providerCode'],
  'address-line1': '1 Fake street name',
  'address-level2': 'Town name',
  'address-level1': 'London',
  'postal-code': 'LB1 1AA',
  'ucas-admin-name': 'Joe Admin',
  'email': 'admin@myorg.ac.uk',
  'website': 'https://myorg.ac.uk',
  'telephone': '01234 321456'
}

# Map course data for the `imported from UCAS` view
prototype_data['ucasCourses'] = courses.each_with_index.map do |c, idx|
  options = []
  courseCode = c['programmeCode']
  lorem = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

  if idx < 7
    prototype_data[courseCode + '-about-this-course'] = lorem
    prototype_data[courseCode + '-interview-process'] = lorem
    prototype_data[courseCode + '-school-placements'] = lorem
    prototype_data[courseCode + '-duration'] = '1 year'
    prototype_data[courseCode + '-salary-details'] = lorem
    prototype_data[courseCode + '-fee'] = '9,000'
    prototype_data[courseCode + '-fee-international'] = '14,000'
    prototype_data[courseCode + '-fee-details'] = lorem
    prototype_data[courseCode + '-financial-support'] = lorem
    prototype_data[courseCode + '-qualifications-required'] = lorem
    prototype_data[courseCode + '-personal-qualities'] = lorem
    prototype_data[courseCode + '-other-requirements'] = lorem
  end

  if next_cycle
    prototype_data[courseCode + '-publish-state'] = 'rolled-over'
  else
    if idx == 0 || idx == 4 || idx == 5
      prototype_data[courseCode + '-publish-state'] = 'published'
      prototype_data[courseCode + '-published-before'] = true
    end

    if idx == 1 || idx == 2
      prototype_data[courseCode + '-publish-state'] = 'draft'
      prototype_data[courseCode + '-published-before'] = false
    end

    if idx == 3
      prototype_data[courseCode + '-fee'] = '10,000'
      prototype_data[courseCode + '-publish-state'] = 'published-with-changes'
      prototype_data[courseCode + '-published-before'] = true
    end

    if idx == 3
      prototype_data[courseCode + '-publish-state'] = 'withdrawn'
      prototype_data[courseCode + '-published-before'] = true
      prototype_data[courseCode + '-withdraw-reason'] = 'It was published by mistake'
    end
  end

  qual = course_qualification(c)

  partTime = c['campuses'].map {|g| g['partTime'] }.uniq.reject {|r| r == "n/a"}.count > 0
  fullTime = c['campuses'].map {|g| g['fullTime'] }.uniq.reject {|r| r == "n/a"}.count > 0
  salaried = c['route'] == "School Direct training programme (salaried)" ? ' with salary' : ''

  if fullTime && partTime
    options << "#{qual}, full time or part time#{salaried}"
    fullPart = 'Full time or part time'
  elsif partTime
    options << "#{qual} part time#{salaried}"
    fullPart = 'Part time'
  else
    options << "#{qual} full time#{salaried}"
    fullPart = 'Full time'
  end

  schools = school_data(c)
  # schools.reject! { |s| s[:code] == '-' }

  subjects = c['subjects'].map {|s| s.downcase.capitalize }

  sen = subjects.include?('Special educational needs')
  if subjects.include?('Primary')
    level = 'Primary'
  elsif subjects.include?('Further education')
    level = 'Further education'
  elsif subjects.include?('Secondary')
    level = 'Secondary'
  else
    level = 'Further education'
  end

  rejectedSubjects = [
    'Primary',
    'Secondary',
    'Further education',
    'Special educational needs',
    'Science'
  ]

  languageSubjects = [
    'French',
    'Spanish',
    'German',
    'Italian',
    'Japanese',
    'Mandarin',
    'Russian',
    'Urdu',
    'Languages',
    'Languages (asian)',
    'Languages (european)',
    'Modern languages',
    'Modern languages (other)'
  ]

  rejectedLanguageSubjects = [
    'Languages',
    'Languages (asian)',
    'Languages (european)'
  ]

  subjectsWithoutLevel = subjects - rejectedSubjects

  if subjectsWithoutLevel.length == 0
    subject = level
  elsif !(subjectsWithoutLevel & languageSubjects).empty?
    subject = 'Modern languages'
    languages = subjectsWithoutLevel - rejectedLanguageSubjects
    prototype_data[courseCode + '-languages'] = languages
  else
    subject = subjects[0]
  end

  type = c['route'] == "School Direct training programme (salaried)" ? 'Salaried' : 'Fee paying (no salary)'
  minRequirements = [
    'Mathematics',
    'English'
  ]

  if level == 'Further education'
    prototype_data[courseCode + '-outcome'] = 'PGCE only (without QTS)'
  else
    prototype_data[courseCode + '-outcome'] = qual
  end

  prototype_data[courseCode + '-no-qualifications-yet'] = 'Yes (recommended)'
  prototype_data[courseCode + '-equivalency-test'] = 'Yes (recommended)'
  prototype_data[courseCode + '-equivalency-subjects'] = level == 'Primary' ? ['English', 'Mathematics', 'Science'] : ['English', 'Mathematics']
  prototype_data[courseCode + '-generated-title'] = c['name']
  prototype_data[courseCode + '-change-title'] = 'Yes, that’s correct'
  #prototype_data[courseCode + '-title'] = c['name']
  prototype_data[courseCode + '-applications-open'] = '10 October 2020'
  prototype_data[courseCode + '-who-apply-type'] = "Option A"
  prototype_data[courseCode + '-type'] = type
  prototype_data[courseCode + '-apprenticeship'] = "No"
  prototype_data[courseCode + '-languages'] = languages
  prototype_data[courseCode + '-phase'] = level
  prototype_data[courseCode + '-age-range'] = level == 'Primary' ? '7 to 11' : '11 to 16'
  prototype_data[courseCode + '-min-requirements'] = minRequirements
  prototype_data[courseCode + '-subject'] = subject
  prototype_data[courseCode + '-full-part'] = fullPart
  prototype_data[courseCode + '-locations'] = schools.map { |s| s[:name] }
  prototype_data[courseCode + '-sen'] = 'This is a SEND course' if sen
  prototype_data[courseCode + '-has-accredited-body'] = c['accrediting'] ? 'Another organisation' : 'We are the accredited body'
  prototype_data[courseCode + '-accredited-body'] = c['accrediting'] || provider
  prototype_data[courseCode + '-vacancies-flag'] = idx == 4 ? 'No' : 'Yes'
  prototype_data[courseCode + '-vacancies-choice'] = idx == 4 ? 'There are no vacancies' : 'There are some vacancies'
  prototype_data[courseCode + '-full-time-and-part-time'] = partTime && fullTime
  prototype_data[courseCode + '-multi-location'] = c['campuses'].length > 1
  prototype_data[courseCode + '-start-date'] = 'September 2021'

  c['campuses'].each_with_index do |campus, i|
    prototype_data["#{courseCode}-vacancies-#{i + 1}"] = 'Vacancies'
  end

  {
    level: level,
    sen: sen,
    accrediting: c['accrediting'] || provider,
    languages: languages,
    subjects: subjectsWithoutLevel,
    subject: subject,
    outcome: qual,
    starts: 'September 2019',
    type: type,
    name: c['name'],
    route: c['route'],
    providerCode: c['providerCode'],
    programmeCode: courseCode,
    schools: schools,
    options: options,
    minRequirements: minRequirements,
    'full-part': fullPart
  }
end

prototype_data['ucasCourses'].sort_by! { |k| k[:name] }

if isAccreditedBody
  prototype_data['accreditedCourses'] = accredited_courses.each_with_index.map do |c, idx|
    options = []
    courseCode = c['programmeCode']
    prototype_data[courseCode + '-publish-state'] = 'published'
    prototype_data[courseCode + '-vacancies-flag'] = idx % 4 == 0 ? 'No' : 'Yes'

    # if next_cycle
    #   prototype_data[courseCode + '-publish-state'] = 'rolled-over'
    # else
    #   if idx == 0 || idx == 4 || idx == 5
    #     prototype_data[courseCode + '-publish-state'] = 'published'
    #     prototype_data[courseCode + '-published-before'] = true
    #   end
    #
    #   if idx == 1 || idx == 2
    #     prototype_data[courseCode + '-publish-state'] = 'draft'
    #     prototype_data[courseCode + '-published-before'] = false
    #   end
    #
    #   if idx == 3
    #     prototype_data[courseCode + '-fee'] = '10,000'
    #     prototype_data[courseCode + '-publish-state'] = 'published-with-changes'
    #     prototype_data[courseCode + '-published-before'] = true
    #   end
    #
    #   if idx == 3
    #     prototype_data[courseCode + '-publish-state'] = 'withdrawn'
    #     prototype_data[courseCode + '-published-before'] = true
    #     prototype_data[courseCode + '-withdraw-reason'] = 'It was published by mistake'
    #   end
    # end

    qual = course_qualification(c)
    partTime = c['campuses'].map {|g| g['partTime'] }.uniq.reject {|r| r == "n/a"}.count > 0
    fullTime = c['campuses'].map {|g| g['fullTime'] }.uniq.reject {|r| r == "n/a"}.count > 0
    salaried = c['route'] == "School Direct training programme (salaried)" ? ' with salary' : ''

    if fullTime && partTime
      options << "#{qual}, full time or part time#{salaried}"
    elsif partTime
      options << "#{qual} part time#{salaried}"
    else
      options << "#{qual} full time#{salaried}"
    end

    {
      provider: c['provider'],
      name: c['name'],
      providerCode: c['providerCode'],
      programmeCode: courseCode,
      options: options
    }
  end

  prototype_data['accreditedCourses'].sort_by! { |k| k[:name] }
end

# Temporarily empty
# prototype_data['ucasCourses'] = []

# Find all schools across all courses and flatten into array of schools
prototype_data['schools'] = courses.map { |c| school_data(c) }.flatten.uniq
prototype_data['schools'].sort_by! { |k| k[:name] }

prototype_data['schools'].each do |school|
  school[:urn] = rand(100000..199999).to_s

  prototype_data["#{school[:code]}-location-picked"] = "#{school[:name]} (#{school[:urn]}, #{school[:'address-level1']}, #{school[:'postal-code']})"
end

# Create a list of accreditors
prototype_data['accreditors'] = courses.uniq {|c| c['accrediting'] }.map  do |c|
  accrediting = c['accrediting']

  if accrediting.nil?
    accrediting = provider
  end

  {
    name: accrediting,
    slug: accrediting.downcase.gsub(/[^a-zA-Z0-9]/, '-').gsub(/--*/, '-').gsub(/-$/,''),
    subjects: []
  }
end

# Create a list of providers
prototype_data['providers'] = accredited_courses.uniq {|c| c['provider'] }.map  do |c|
  {
    name: c['provider'],
    code: c['providerCode'],
    count: accredited_courses.select {|a| a['provider'] == c['provider'] }.length
  }
end

prototype_data['accreditors'].sort_by! { |k| k[:name] }
prototype_data['providers'].sort_by! { |k| k[:name] }
prototype_data['self_accrediting'] = (prototype_data['accreditors'].length == 1 && prototype_data['accreditors'][0][:name] == provider)

# Create a list of subjects
prototype_data['subjects'] = courses.uniq {|c| c['name'] }.map  do |c|
  {
    name: c['name'],
    slug: c['name'].downcase.gsub(/[^a-zA-Z0-9]/, '-').gsub(/--*/, '-').gsub(/-$/,''),
  }
end

prototype_data['subjects'].sort_by! { |k| k[:name] }

# Group courses by accrediting provider
courses_by_accrediting = {}
prototype_data['accreditors'].each { |c| courses_by_accrediting[c[:name]] = [] }
courses.each do |c|
  courses_by_accrediting[c['accrediting'] || provider] << c
end

# Group courses by subject
courses_by_subject = {}
prototype_data['subjects'].each { |c| courses_by_subject[c[:name]] = [] }
courses.each { |c| courses_by_subject[c['name']] << c }

courses_by_accreditor_and_subject = {}
prototype_data['accreditors'].each do |accrediting|
  courses_by_accreditor_and_subject[accrediting[:name]] = {}
  prototype_data['subjects'].each { |subject| courses_by_accreditor_and_subject[accrediting[:name]][subject[:name]] = [] }
end

courses.each do |course|
  courses_by_accreditor_and_subject[course['accrediting'] || provider][course['name']] << course

  subject = prototype_data['subjects'].find {|s| s[:name] == course['name']}
  prototype_data['accreditors'].find { |a| a[:name] == (course['accrediting'] || provider)}[:subjects] << subject
end

prototype_data['new-course'] = {
  'include-accredited': !isAccreditedBody,
  'include-fee-or-salary': courses.first['route'].include?('School Direct')
}

prototype_data['is-accredited-body'] = isAccreditedBody
prototype_data['accreditors'].each {|a| a[:subjects].sort_by! { |k| k[:name] }.uniq! }
prototype_data['accredited-bodies-choices'] = all_accredited_bodies.map { |k| { name: k } }

# Output to prototype
File.open('app/data/prototype-data.json', 'w') { |file| file.write(JSON.pretty_generate(prototype_data) + "\n") }
