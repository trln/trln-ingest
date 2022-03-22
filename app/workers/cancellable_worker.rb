# Specialization of Sidekiq worker that supports cancelation
class CancellableWorker
  include Sidekiq::Worker

  def cancelled?
    Sidekiq.redis { |r| r.exists("cancelled-#{jid}") }.positive?
  end

  def cancel!(jid)
    Sidekiq.redis { |r| r.setex("cancelled-#{jid}", 86_400, 1) }
  end
end
