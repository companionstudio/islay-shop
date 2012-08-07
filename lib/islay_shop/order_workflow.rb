module IslayShop
  module OrderWorkflow
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
        include InstanceMethods

        class_attribute :_workflow
      end
    end

    class Workflow
      attr_accessor :col

      def initialize(col, initial, &blk)
        @col      = col
        @initial  = initial.to_s
        @events   = Hash.new {|h,k| h[k] = {}}
        @default  = lambda {next!}
        instance_eval(&blk)
      end

      def run?(model, event)
        !!@events[event][model[col].to_sym]
      end

      def run(model, event, args = [])
        config  = @events[event][model[col].to_sym]
        logic   = config[:logic]

        case config[:logic]
        when Proc   then model.instance_exec(*args, &logic)
        when Symbol then model.send(logic, *args)
        end
      end

      def run!(model, event, args = [])
        run(model, event, args) and model.save
      end

      def next_status(model, event)
        @events[event][model[col].to_sym][:to]
      end

      private

      def event(name, from_to, meth = nil, &blk)
        from    = from_to.keys.first
        to      = from_to.values.first
        config  = @events[name]
        logic   = meth || blk || @default

        case from
        when Array  then from.each {|entry| config[entry] = {:logic => logic, :to => to}}
        when Symbol then config[from] = {:logic => logic, :to => to}
        end
      end
    end

    module ClassMethods
      def workflow(col, initial, &blk)
        self._workflow = Workflow.new(col, initial, &blk)
      end

      def run_all!(event, ids, *args)
        ActiveRecord::Base.transaction do
          where(:id => ids).each {|e| e.run!(event, *args)}
        end
      end
    end

    module InstanceMethods
      def run?(event)
        _workflow.run?(self, event)
      end

      def run_any?(*events)
        result = events.map {|e| run?(e)}
        !result.empty? and result.any?
      end

      def run!(event, *args)
        @current_event = event
        _workflow.run!(self, event, args)
      end

      def run(event, *args)
        @current_event = event
        _workflow.run(self, event, args)
      end

      private

      def next!(notes = nil)
        status = _workflow.next_status(self, @current_event)
        self[_workflow.col] = status
        logs.build(:action => @current_event, :notes => notes)
        true
      end

      def fail!(notes = nil)
        status = _workflow.next_status(self, @current_event)
        logs.build(:action => @current_event, :notes => notes)
        false
      end
    end
  end
end
