class SidekiqStatusJob
	include Sidekiq::Job
	
	def perform
		puts "========================================================="
		puts "Sidekiq is active since #{Time.now.strftime('%x || %X')}"
		puts "========================================================="
	end
end
