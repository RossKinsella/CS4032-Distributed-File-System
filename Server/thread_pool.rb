require 'thread'

# Taken from:
# http://www.burgestrand.se/code/ruby-thread-pool/  
class ThreadPool
  def initialize(size)
    @size = size
    @jobs = Queue.new
    @pool = Array.new(@size) do |i|
      Thread.new do
        Thread.current[:id] = i
        puts "Thread #{i} has been initialized"
        catch(:exit) do
          loop do
            job, args = @jobs.pop
            job.call(*args)
          end
        end
      end
    end
  end

  def schedule(*args, &block)
    @jobs << [block,args]
  end

  def shutdown
    puts "shutdown: started"
    @size.times do
      schedule {throw :exit}
    end
    puts "shutdown: awaiting workers to finish"
    @pool.each { |thr| thr.join }
    puts "shutdown: complete"
  end
end
