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

        def to_s
            self.department + self.number + " " + self.title
        end

        class << self
            def parse(course_string)
                course_array = course_string.split(/ - /)
                if course_array.length == 3
                    if course_array[0].match(/[A-Z]{3}\d{3}/)
                        course_code = course_array[0].strip
                        course_title = course_array[1].strip
                        course_sem = course_array[2].strip
                        course = Course.new
                        course.department = course_code[0,3]
                        course.number = course_code[3,3]
                        course.season = course_sem[0,1]
                        course.year = course_sem[1,4]
                        course.title = course_title
                        course
                    end
                end
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
                student.courses = courses.inject([]){|array, course| array << [Course.parse(course.inner_text),course["href"]] }
                student.courses.reject!{|item| item[0].nil?}
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

