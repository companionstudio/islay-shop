/* -------------------------------------------------------------------------- */
/* PROMOTION EDITING
/* A widget which wraps around the condition and effect fields in promotion
/* editing form and provides a few conveniences e.g. disabling options when
/* they are incompatible.
/* -------------------------------------------------------------------------- */
(function($) {
  var Component = function(el) {
    this.name = el.attr('class').match(/^(.+)\-(condition|effect)/)[1];
    this.$el = el;
    this.$active = el.find('[name*="active"]:not(:hidden)');
    this.$inputs = el.find(':input:not([name*="active"])');

    this.$active.on('change', $.proxy(this, 'activeChange'));
    this.activeChange();
  };

  Component.prototype = {
    activeChange: function() {
      if (this.$active.is(':checked')) {
        this.$inputs.prop('disabled', false);
        this.$el.addClass('active');
      }
      else {
        this.$inputs.prop('disabled', true);
        this.$el.removeClass('active');
      }
      this.$inputs.trigger('change');
    },

    disable: function() {
      this.$el.addClass('disabled');
      this.$active.attr('disabled', true);
      this.$active.trigger('change');
      this.$inputs.prop('disabled', true);
    },

    enable: function() {
      this.$el.removeClass('disabled');
      this.$active.attr('disabled', false);
      this.$active.trigger('change');
    }
  };

  var Promotions = function(form) {
    this.$form = form;
    this.selected = [];
    this.updating = false;

    var self = this,
        conditions = this.$form.find('.promotion-conditions fieldset'),
        effects = this.$form.find('.promotion-effects fieldset');

    this.conditions = _.map(conditions, function(el) {
      var cond = new Component($(el))
      cond.scope = cond.$el.attr('data-exclusivity-scope');
      return cond;
    });

    this.effects = _.map(effects, function(el) {
      return new Component($(el));
    });

    // All conditions with a 'full' exclusivity
    var full = _.pluck(_.select(this.conditions, function(c) {return c.scope === 'full';}), 'name');

    this.compatibilities = {};
    this.exclusivity = {};
    _.each(this.conditions, function(condition) {
      var compatible = condition.$el.attr('data-compatible-effects').split(', ');
      this.compatibilities[condition.name] = compatible;
      if (condition.$active.is(':checked')) {this.selected.push(condition);}

      // Compute the exclusivity
      if (condition.scope === 'full') {
        this.exclusivity['full'] = _.pluck(this.conditions, 'name');
      }
      else if (condition.scope !== 'none') {
        // The default set of names should be the 'full'
        if (!this.exclusivity[condition.scope]) {this.exclusivity[condition.scope] = _.clone(full);}
        this.exclusivity[condition.scope].push(condition.name);
      }

      condition.$active.on('change', {condition: condition}, $.proxy(this, 'change'));
    }, this);

    // All non 'full' exclusivity scopes should implicitly exclude 'full'
    this.exclusivity['none'] = full;

    this.update();
  };

  Promotions.prototype = {
    change: function(e) {
      if (!this.updating) {
        var cond = e.data.condition;
        if (cond.$active.is(':disabled') || !cond.$active.is(':checked')) {
          this.selected = _.reject(this.selected, function(s) {return s.name === cond.name;});
        }
        else {
          this.selected.push(cond);
        }
        this.update();
      }
    },

    update: function() {
      this.updating = true;

      var enableEffects = [];
          disableConditions = [];

      _.each(this.selected, function(condition) {
        // Add to the list of valid effects
        enableEffects = enableEffects.concat(this.compatibilities[condition.name]);

        // If we have a scope, turn off the other conditions.
        var scope = this.exclusivity[condition.scope];
        if (scope) {
          var update = _.filter(scope, function(o) {return o !== condition.name});
          disableConditions = disableConditions.concat(update);
        }
      }, this);

      _.each(this.effects, function(e) {
        _.contains(enableEffects, e.name) ? e.enable() : e.disable();
      });

      _.each(this.conditions, function(c) {
        _.contains(disableConditions, c.name) ? c.disable() : c.enable();
      });

      this.updating = false;
    }
  };

  $.fn.islayPromotions = function() {
    this.each(function() {
      var $this = $(this);
      if (!$this.data('islayPromotions')) {
        $this.data('islayPromotions', new Promotions($this));
      }
    });
    return this;
  };
})(jQuery);
