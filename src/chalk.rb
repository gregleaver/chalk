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
    attr_accessor :department, :number, :season, :year, :title, :section, :assignments
    
    module Regex
      DEPARTMENT_AND_NUMBER = /^([A-Z]{3}) ([0-9]{3})/
    end

    class << self
      def parse(course_string)
        course = Course.new
        course_string.gsub!(/[,():*]/,"")
        course_array = course_string.scan(/([A-Za-z]+|[0-9]+)/).flatten
        course.department, course.number = course_array.slice!(0..1)
        season_index = course_array.rindex("Spring"||"Summer"||"Fall"||"Winter")
        course.season, course.year = course_array.slice(season_index..season_index+1)
        course_array = course_array.slice!(0..season_index-1)
        course_array = course_array.select{|string| !string.scan(/([A-Za-z]+)/).empty?}.flatten
        course.title = course_array.join(" ")
        course
      end
    end
  end

  class Assignment
    attr_accessor :title, :due_on, :graded_on, :points_attained, :points_possible, :category, :description, :comments
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

        def get_courses_for(student)
          courses_page = agent.get(base_url + "/webapps/gradebook/do/student/viewCourses")
          courses_page = Nokogiri::HTML::DocumentFragment.parse(courses_page.body)
          courses = courses_page.css('h3 a')
          student.courses = courses.inject([]){|array, course| array << [Course.parse(course.inner_text.strip!),course["href"]]}
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

