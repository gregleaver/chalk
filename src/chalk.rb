# class Blackboard
# class Student
# class Course
# class Assignment

module Chalk

  class Student
    require 'base64'
    attr_accessor :username, :password, :courses

    def initialize(username, password)
      @username = username
      @password = Base64.encode64(password)
    end

    def to_s
      "Student[#@username]"
    end
  end

  class Course
    attr_accessor :department, :number, :season, :year, :title, :section, :assignments, :url

    def to_s
      "#{department}#{number} #{title}: #{average}%"
    end

    def average
      attained = assignments.inject(0){|sum,assignment| sum += assignment.points_attained}
      possible = assignments.inject(0){|sum,assignment| sum += assignment.points_possible}
      if possible > 0
        (attained / possible * 10000).round / 100.0
      else
        0.0
      end
    end
  end

  class Assignment
    attr_accessor :title, :due_on, :last_updated, :category, :description, :comments
    attr_reader :points_attained, :points_possible

    def initialize
      @points_attained = 0.0
      @points_possible = 0.0
    end

    def points_attained=(points)
      @points_attained = points.to_f
    end

    def points_possible=(points)
      @points_possible = points.to_f
    end

    def percentage
      if @points_possible > 0
        (@points_attained / @points_possible * 10000).round / 100.0
      else
        0.0
      end
    end

    def to_s
      if @last_updated != ''
        "#@title: #@points_attained/#@points_possible, #{percentage}%  - as of #{@last_updated}"
      else
        "#@title: #@points_attained/#@points_possible, #{percentage}%"
      end
    end
  end

  class Blackboard
    attr_accessor :url

    def initialize(url)
      @url = url
    end

    def login(username, password)
      blackboard = Blackboard::Session.new(@url)
      student = Student.new(username, password)

      blackboard.login_as(student)
    end

    class Session
      require 'rubygems'
      require 'nokogiri'
      require 'mechanize'
      attr_accessor :agent, :base_url, :current_page, :authenticated

      def initialize(base_url)
        @authenticated = false
        @base_url = base_url
        @agent = Mechanize.new()
        @agent.get(base_url)
      end

      def login_as(student)
        login!(student)
        get_courses_for(student)
        student
      end

      def authenticated?
        @authenticated
      end

      private

      def login_url
        @base_url + "/webapps/login/"
      end

      def parse_course(data)
        course_string = data.text()
        course_array = course_string.split(/ - /)
        if course_array.length == 3
          if course_array[0].match(/[A-Z]{3}\d{3}/)
            course = Course.new
            course.url = data['href']
            course_code = course_array[0].strip
            course_title = course_array[1].strip
            course_sem = course_array[2].strip
            course.department = course_code[0,3]
            course.number = course_code[3,3]
            course.season = course_sem[0,1]
            course.year = course_sem[1,4]
            course.title = course_title
            course
          end
        end
      end

      def parse_assignment(data)
        assignment = Assignment.new
        assignment.title = data.at_xpath('./th').text()
        data = data.xpath('./td')
        assignment.due_on = data[1].text()
        assignment.last_updated = data[2].text()
        assignment.points_attained = data[3].text()
        assignment.points_possible = data[4].text()
        assignment
      end

      def get_courses_for(student)
        courses_page = agent.get(@base_url + "/webapps/gradebook/do/student/viewCourses")
        courses_page = Nokogiri::HTML(courses_page.body,'UTF-8')
        courses = courses_page.xpath('//h3/a')
        student.courses = courses.inject([]) do |courses, course| 
          c = parse_course(course)
          if c
            courses << c # Add Course
            # Get Assignments
            assignments_page = agent.get(c.url)
            assignments_page = Nokogiri::HTML(assignments_page.body,'UTF-8')
            assignments = assignments_page.xpath('//*[@class=\'attachments mygrades\']/tbody/tr')
            assignments.shift
            c.assignments = assignments.inject([]) do |assignments, assignment|
              a = parse_assignment(assignment)
              if a
                assignments << a
              end
              assignments
            end
          end
          courses
        end
      end

      def login!(student)

        params = {
          "action"              =>  "login",
          "user_id"             =>  URI.escape(student.username, Regexp.new(URI::PATTERN::RESERVED)),
          "encoded_pw"          =>  URI.escape(student.password, Regexp.new(URI::PATTERN::RESERVED)),
          "encoded_pw_unicode"  =>  URI.escape(student.password, Regexp.new(URI::PATTERN::RESERVED)),
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

