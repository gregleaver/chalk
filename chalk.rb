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
				login_page = agent.get(login_url)

				login_form = login_page.forms[0]

				login_form.user_id = student.username
				login_form.encoded_pw = student.encoded_password
				login_form.encoded_pw_unicode = student.encoded_password
				
				dashboard = login_form.submit

				authenticated = true

				get_courses_for(student)

				student
			end

			def authenticated?
				authenticated
			end

			private
			  def login_url
				  base_url + "/webapps/portal/execute/tabs/tabAction?tab_tab_group_id=_14_1"
			  end

				def get_courses_for(student)
					courses_page = agent.get(base_url + "/webapps/portal/execute/tabs/tabAction?action=refreshAjaxModule&modId=_27_1&tabId=_2_1&tab_tab_group_id=_2_1")
					courses_page = Nokogiri::HTML::DocumentFragment.parse(courses_page.body)
					courses = courses_page.css('td a')
					student.courses = courses.inject([]){|array, course| array << [course.inner_text,course["href"]]}
				end
		end	
	end
end

