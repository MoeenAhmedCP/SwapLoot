module DeleteEnqueuedJobsConcern
	extend ActiveSupport::Concern
  
	def delete_enqueued_job(job_id)
		queue = Sidekiq::Queue.new # For jobs in the queue
		scheduled = Sidekiq::ScheduledSet.new # For scheduled jobs
		retries = Sidekiq::RetrySet.new # For jobs in retry

		# Check in the queue
		job = queue.find_job(job_id)
		job.delete if job

		# Check in scheduled jobs
		job = scheduled.find_job(job_id)
		job.delete if job

		# Check in retry set
		job = retries.find_job(job_id)
		job.delete if job
	end
end
  