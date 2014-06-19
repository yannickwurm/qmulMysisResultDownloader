#!/usr/bin/env ruby 
# -*- coding: utf-8 -*-
# 2014 - yannick wurm at insalien . org

##includes##
['pathname','fileutils', 'logger', 'capybara-webkit', 'mail', 'open-uri'].each do |lib| require lib; end

require './config.rb'

class MySisDownloader
  include Capybara::DSL
  @base_url = ''
  @download_dir = 'samples'
  @log = '' 
  @download_regex = ''
  def initialize(base_url)
    Capybara.default_driver = :webkit
    @base_url = base_url
    @download_dir = 'samples'
    @log = Logger.new(STDERR)
  end
  

  def do_your_stuff
    students        = get_student_links # 2 links: 1. email address and 2.marks
    students_marked = get_marks( students)
    send_emails(students_marked)
    @log.info 'Done...'
  end


  def get_student_links
    # log in
    visit @base_url
    puts "Warming up."
#    puts "enter password:"
#    password = gets
    fill_in 'MUA_CODE.DUMMY.MENSYS', :with => $id
    fill_in 'PASSWORD.DUMMY.MENSYS', :with => $password
    click_button 'Sign In'

    # go to data page
    click_link 'Student Course Data'
    click_link 'List tutees by Academic Advisor'
    select $advisor, :from => 'ANSWER.TTQ.MENSYS.1.'
    click_button 'Next'

    puts "I'm in."
    students = {}
    page.all('.sitstablegrid tr').each do |tr|
      next unless tr.has_selector?('a[href*="SIW_YGSL.start_url"]')
      next unless tr.text.match('UBSF-QMBIOL1') or tr.text.match('USEF-QM4BIO1')  # filtering programs. 
  
      year = tr.find("td:nth-child(5)").text
      next if year.match(/\(3\)/)   #only 1st and second year
      ## Downloaded stuff with trs that meet the href requirement
      
      puts tr.text
      ##      end
      student = { :name => tr.find("td:nth-child(2)").text,
                  :urlForEmail => tr.find("td:nth-child(1) a")[:href],
                  :urlForMarks => tr.find("td:nth-child(8) input")[:onClick]
                 }
      student[ :urlForMarks] = student[ :urlForMarks].gsub("self.location='", "").gsub("'", "")

      students[student[:name]] = student
    end
    return students
  end
  def get_marks( students)
    students.each do |id, student|
      puts "--- " + student[ :name]
      
      # get email
      useable_url = File.join(@base_url, 'urd/sits.urd/run', student[ :urlForEmail])
      visit useable_url
      
      page.all('a').each do |a|
        next unless a.text.match(/@se..\.qmul/)
        student[ :email] = a[:href].gsub('mailto:', '')
        break
      end

      # get marks
      useable_url = File.join(@base_url, 'urd/sits.urd/run', student[ :urlForMarks])
      visit useable_url
      
      page.all('table').each do |table|
        next if table.text.match(/Student Module Result Transcr/)
        next unless table.text.match(/Credit.*Mark.*Grade.*Result/)
        student[ :marks] = "Year\tModule\tGrade\tResult\tCourse Title"
        table.all('tr').each do |tr|
          mark =  [tr.find("td:nth-child(1)").text, 
                   tr.find("td:nth-child(3)").text,
                   tr.find("td:nth-child(8)").text,
                   tr.find("td:nth-child(9)").text,
                   tr.find("td:nth-child(4)").text,
                  ].join("\t") 
          student[:marks] = student[:marks] + "\n" + mark
        end
      end
    end
    return students    
  end

  def send_emails(students_marked)
    options = { 
      :address              => $smtp_server, 
      :port                 => 587,
      :user_name            => $mail_login,  
      :password             => $mail_password,
      :authentication       => 'plain',
      :enable_starttls_auto => true  }

   
    students_marked.each do |id, student|
      puts 'Mailing: ' + id
      message = ["Hello #{student[:name]},\n",
                 $mail_intro,
                 student[:marks],
                 $mail_outro
                ].join("\n")
      puts "Sending " + message
      
      mail = Mail.new do
        delivery_method :smtp, options
        to              "#{$mail_from},#{student[:email]}"
        from            $mail_from
        reply_to        $mail_from
        subject         "Marks for this year"
        body            message
      end
     
      mail.deliver!
    end

    
  end
end 


base_url = 'https://mysis.qmul.ac.uk'
markmailer = MySisDownloader.new(base_url)
markmailer.do_your_stuff

puts "Done"
