class SidekiqStatusJob
	include Sidekiq::Job
	sidekiq_options retry: false
	
	def perform
		puts "========================================================="
		puts "Sidekiq is active since #{Time.now.strftime('%x || %X')}"
		puts "========================================================="
	end
end
