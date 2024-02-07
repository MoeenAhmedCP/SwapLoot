class SidekiqStatusJob
	include Sidekiq::Job
	
	def perform
		puts "*--*--*"*100
		puts "*--*--*"*100
		puts "Sidekiq is active since #{Time.now.strftime('%x || %X')}"
		puts "*--*--*"*100
		puts "*--*--*"*100
	end
end
