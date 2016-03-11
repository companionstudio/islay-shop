module OrderWorkflowConcern
  extend ActiveSupport::Concern

  included do
    self.class_attribute :_workflow
  end

  class OnHoldError < StandardError
    def initialize(event)
      @event = event
    end

    def to_s
      "The event '#{@event}' can't be run while this order is on hold"
    end
  end

  class InvalidEventError < StandardError
    def initialize(event, status, check)
      @event = event
      @status = status
      @check = check
    end

    def to_s
      "The event '#{@event}' can't be run while in the '#{@status}' status. Reason: #{@check[:reason]}"
    end
  end

  class Workflow
    attr_accessor :col

    def initialize(col, initial, &blk)
      @col            = col
      @initial        = initial.to_s
      @events         = Hash.new {|h,k| h[k] = {}}
      @default_logic  = :default_workflow_logic
      @default_test   = :default_workflow_test
      @holding        = []
      instance_eval(&blk)
    end

    def run?(model, event)
      config = @events[event][model[col].to_sym]
      !model.on_hold? and !!config and model.send(config[:test])[:success]
    end

    # Checks to see if an event can be run and returns a hash which indicates
    # the success state and if applicable, the reason for failure.
    #
    # @param ActiveRecord::Base model
    # @param Symbol event
    #
    # @return Hash
    def run_check(model, event)
      event = @events[event]
      config = event[model[col].to_sym]

      if model.on_hold?
        {:success => false, :reason => :on_hold}
      elsif event.empty?
        {:success => false, :reason => :no_event_defined}
      elsif config.nil?
        {:success => false, :reason => :out_of_sequence}
      else
        model.send(config[:test])
      end
    end

    # Indicates if the workflow can be put on hold from the current state.
    #
    # @param ActiveRecord::Base model
    #
    # @return Boolean
    def can_hold?(model)
      @holding.include?(model[col].to_sym)
    end

    # @return Boolean
    #
    # @raises [OnHoldError, InvalidEventError]
    def run(model, event, args = [])
      raise OnHoldError.new(event) if model.on_hold?

      check = run_check(model, event)
      raise InvalidEventError.new(event, model[col], check) unless check[:success]

      config  = @events[event][model[col].to_sym]
      logic   = config[:logic] 

      result = model.send(logic, *args)
      model[col] = config[:to] if result
      result
    end

    def run!(model, event, args = [])
      if run(model, event, args)
        model.save 
      else
        false
      end
    end

    def next_status(model, event)
      @events[event][model[col].to_sym][:to]
    end

    private

    # Declares the states from which the workflow can be put on hold.
    # 
    # @param [String, Symbol] states
    #
    # @return Array<Symbol>
    def holding(*states)
      @holding.concat(states.map(&:to_sym))
    end

    def event(name, from_to, opts = {})
      from    = from_to.keys.first
      to      = from_to.values.first
      config  = @events[name]

      settings = case opts
      when Symbol 
        {:logic => opts, :test => @default_test, :to => to}
      when Hash 
        {:logic => opts[:run] || @default_logic, :test => opts[:test] || @default_test, :to => to}
      when nil
        {:logic => @default_logic, :test => @default_test, :to => to}
      end

      case from
      when Array  then from.each {|entry| config[entry] = settings}
      when Symbol then config[from] = settings
      end
    end
  end

  class_methods do
    def workflow(col, initial, &blk)
      self._workflow = Workflow.new(col, initial, &blk)
    end

    def run_all!(event, ids, *args)
      ActiveRecord::Base.transaction do
        where(:id => ids).each {|e| e.run!(event, *args)}
      end
    end
  end

  # Indicates if an event can be run.
  #
  # @param Symbol event
  #
  # @return [true, false]
  def run?(event)
    _workflow.run?(self, event)
  end

  # Indicates why an event can't be run. This has the same semantics as #run?
  # except it returns a hash indicating why an event can't be run.
  #
  # @param Symbol event
  #
  # @return Hash
  def run_check(event)
    _workflow.run_check(self, event)
  end

  # Indicates if the model's workflow can be put on hold based on the
  # current state.
  # 
  # @return Boolean
  def can_hold?
    !on_hold? and _workflow.can_hold?(self)
  end

  def run_any?(*events)
    result = events.map {|e| run?(e)}
    !result.empty? and result.any?
  end

  def run!(event, *args)
    @current_event = event
    extract_event_options!(args)
    _workflow.run!(self, event, args)
  end

  def run(event, *args)
    @current_event = event
    extract_event_options!(args)
    _workflow.run(self, event, args)
  end

  # Puts the model's workflow on hold.
  #
  # @param String notes
  #
  # @return Boolean
  def hold!(notes = nil)
    self.on_hold = true
    logs.build(:status_type => 'order', :status => "on_hold", :notes => notes)
    save
  end

  # Releases a model from being on hold so that the workflow can progress
  # again.
  #
  # @param String notes
  #
  # @return Boolean
  def release!(notes = nil)
    self.on_hold = false
    logs.build(:status_type => 'order', :status => "released_from_hold", :notes => notes)
    save
  end

  private

  # Default logic that gets run when transitioning.
  #
  # @return true
  def default_workflow_logic
    next!
  end

  # Default test that gets executed when checking if a workflow event can
  # be run.
  #
  # @return Hash
  def default_workflow_test
    {:success => true}
  end

  # Keys specific to the workflow. These are extracted from any hashes passed
  # into the #run or #run! methods.
  EVENT_OPTIONS = [:notes].freeze

  # Destructively updates the args array if the last entry is a hash by 
  # removing the keys defined in EVENT_OPTIONS and storing them in 
  # @event_opts, with is used later.
  #
  # @param Array args
  #
  # @return Hash
  def extract_event_options!(args)
    @event_opts = if args.last.is_a?(Hash)
      args.last.extract!(EVENT_OPTIONS)
    else
      {}
    end
  end

  # Stores the current status against the model and logs the transition.
  #
  # @param String notes
  #
  # @return true
  def next!(notes = nil)
    workflow_response(true, notes)
  end

  # Logs the failure to transition.
  #
  # @return false
  def fail!(notes = nil)
    workflow_response(false, notes)
  end

  # A helper for building workflow responses. Should not be used directly. 
  # Instead refer to the #next! and #fail! methods.
  #
  # @param [true, false] state
  # @param String notes
  # @return Boolean
  def workflow_response(state, notes = nil)
    status = _workflow.next_status(self, @current_event)
    notes = [@event_opts[:notes], notes].compact.join('. ')
    build_log(state, @current_event, notes)
    state
  end

  # Shortcut for generating logs
  #
  # @param [true, false] succeeded
  # @param String action
  # @param String notes
  # @return OrderLog
  def build_log(succeeded, action, notes = nil)
    logs.build(:action => action, :notes => notes, :succeeded => succeeded)
  end
end
