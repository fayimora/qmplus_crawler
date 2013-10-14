require 'mechanize'
require 'mongo'

class QmplusCrawler < Mechanize
  def process(user, pass)
    self.verify_mode = OpenSSL::SSL::VERIFY_NONE
    get 'http://qmplus.qmul.ac.uk/'
    click(page.link_with(:text => /Login/))

    # Authentication
    login('https://qmplus.qmul.ac.uk/login/index.php', user, pass)
    login('/idcheck', user, pass)

    # Crawler doesn't support javascript so this is required
    cont_form = page.forms[0]
    cont_button = cont_form.button_with(value: 'Continue')
    submit(cont_form, cont_button)

    # Head to the attempts page
    click(page.link_with(text: /ECS407U/))
    get 'http://qmplus.qmul.ac.uk/mod/quiz/report.php?id=165144&mode=overview'
    all_attempts = page.links_with(class: 'reviewlink')

    puts "Accumulating each user's data"
    @data = [] # this will hold the data for every student
    all_attempts.each do |attempt|
      user_data = {student: "", responses: []}
      transact do
        click(attempt)
        user_data[:student] = page.links_with(href: /user\/view/)[1].text
        page.search('div.qtype_essay_response').each do |response|
          user_data[:responses] << response.content
        end
      end
      @data.push user_data
    end

    puts "Done accumulating data! Time to store them in mongodb"
    # @data.each { |student| puts student[:responses][0].content }
    persist_data
    puts "Done storing data!"
  end

  def persist_data
    db = Mongo::Connection.new("localhost", 27017).db("logic_survey")
    collection = db["survey_results"]
    @data.each {|student| collection.insert(student)}
  end

  def login(post_to, user, pass)
    page.form_with(action: post_to) do |f|
      f.username = user
      f.password = pass
    end.click_button
  end
end

QmplusCrawler.new.process(ENV['QMPLUS_USER'], ENV['QMPLUS_PASS'])
