# class Student
# class Course
# class Assignment

module Chalk
  class Student
    require 'base64'
    attr_accessor :username, :password, :courses

    def initialize(username, password)
      self.username = username
      self.password = password
    end
    
    def encoded_password
      Base64.encode64(self.password)
    end
  end
  
  class Course
    attr_accessor :department, :number, :season, :year, :title
    
  end

  class Assignment
    
  end

  module Blackboard
     
    def self.url=(base_url)
      @@url = base_url
    end

    def self.url
      @@url
    end

    def self.login(username, password)
      @blackboard = Blackboard::Session.new(self.url)
      @student = Student.new(username, password)
      
      @blackboard.login_as(@student)
    end

    class Session
      require 'rubygems'
      require 'nokogiri'
      require 'mechanize'
      attr_accessor :agent, :base_url, :current_page, :authenticated

      def initialize(base_url)
        self.authenticated = false
        self.base_url = base_url
        self.agent = Mechanize.new()
        self.agent.get(base_url)
      end

      def login_as(student)
        login!(student)

        get_courses_for(student)

        student
      end

      def authenticated?
        authenticated
      end

      private

        def login_url
          base_url + "/webapps/login/"
        end

        # Refactor this out so it doesn't use the tab group URL which is only valid on Eastern if you are using the defaults.
        def get_courses_for(student)
          courses_page = agent.get(base_url + "/webapps/portal/execute/tabs/tabAction?action=refreshAjaxModule&modId=_27_1&tabId=_2_1&tab_tab_group_id=_2_1")
          courses_page = Nokogiri::HTML::DocumentFragment.parse(courses_page.body)
          courses = courses_page.css('td a')
          student.courses = courses.inject([]){|array, course| array << [course.inner_text,course["href"]]}
        end

        def login!(student)

          params = {
                      "action"              =>  "login",
                      "user_id"             =>  URI.escape(student.username, Regexp.new(URI::PATTERN::RESERVED)),
                      "encoded_pw"          =>  URI.escape(student.encoded_password, Regexp.new(URI::PATTERN::RESERVED)),
                      "encoded_pw_unicode"  =>  URI.escape(student.encoded_password, Regexp.new(URI::PATTERN::RESERVED)),
                      "remote-user"         =>  "",
                      "auth_type"           =>  "",
                      "new_loc"             =>  "",
                      "one_time_token"      =>  "",
                      "password"            =>  ""
                   }

          agent.post(login_url, params)

          # TODO: Actually check if the user was actually logged in here.
          authenticated = true

          agent
        end
    end 
  end
end

