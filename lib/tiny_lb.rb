# frozen_string_literal: true

# tiny_lb is an in-process load balancer. it works by acting as a proxy,
# forwarding method calls to one of several downstream services based
# on a user-provided strategy.
#
# use it in the following way:
#   1. define your services (i.e. objects to which the method calls can be
#     forwarded)
#   2. define a load balancing strategy: strategies can be any object that
#     responds to the method `tiny_lb`, and returns an object to which a method
#     call should be forwarded; an simple example is shown below
#   3. initialize the TinyLb instance, given the services and balancing strategy
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
#   # a simple percentage-based load balancing strategy
#   class Rollout
#     def initialize(percentage:)
#       @percentage = percentage
#     end
#
#     def tiny_lb(services)
#       # services are ordered in this example:
#       # - services[0] is the primary/production service
#       # - services[1] is the new/experimental service
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
#
#     # the `lb` object is an intance of TinyLb, and when you call a method on
#     # it, `method_missing` will be triggered, the load balancing strategy will
#     # be run to select a downstream service, and then the method call will be
#     # forwarded to the selected service
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
