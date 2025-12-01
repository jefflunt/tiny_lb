# frozen_string_literal: true

# tiny_lb is an in-process load balancer. it works by acting as a proxy,
# forwarding method calls to one of several downstream services based
# on a user-provided strategy.
#
# use it in the following way:
#   1. define your services; they should share a common public interface
#   2. define a strategy; a strategy is any object that responds to a call to #tiny_lb, and returns 
#   3. assemble the load balancer.
#   4. use the load balancer as if it were one of your services.
#
# usage:
#   class ProdSvc
#     def do_work(payload)
#       "prod svc handled: #{payload}"
#     end
#   end
#
#   class ExpSvc
#     def do_work(payload)
#       "exp svc handled: #{payload}"
#     end
#   end
#
#   class Rollout
#     def initialize(percentage:)
#       @percentage = percentage
#     end
#
#     def tiny_lb(services)
#       # services are ordered. services[0] is the primary, services[1]
#       # is the new service being rolled out to.
#       rand(1..100) <= @percentage ? services[1] : services[0]
#     end
#   end
#
#   services = [ProdSvc.new, ExpSvc.new]
#   strategy = Rollout.new(percentage: 10) # 10% of traffic to ExpSvc
#
#   lb = TinyLb.new(services: services, strategy: strategy)
#
#   10.times do
#     puts lb.do_work("my task")
#   end
#
#   # output might look like this:
#   #
#   # prod svc handled: my task
#   # prod svc handled: my task
#   # exp svc handled: my task
#   # prod svc handled: my task
#   # prod svc handled: my task
#   # prod svc handled: my task
#   # prod svc handled: my task
#   # prod svc handled: my task
#   # prod svc handled: my task
#   # prod svc handled: my task

class TinyLb
  def initialize(services:, strategy:)
    @services = services
    @strategy = strategy
  end

  def method_missing(method_name, *args, &block)
    dest_svc = @strategy.tiny_lb(@services)
    raise NoMethodError, "undefined method `#{method_name}' for an instance of #{dest_svc.class}" unless dest_svc.respond_to?(method_name)

    dest_svc.public_send(method_name, *args, &block)
  end
end
