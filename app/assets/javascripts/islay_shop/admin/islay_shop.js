//= require ../../vendor/raphael-min
//= require ../../vendor/g.raphael-min
//= require ../../vendor/g.pie-min
//= require ../../vendor/g.line-min
//= require ../../vendor/kalendae
//= require ../../vendor/moment
//= require_tree .

$SP.GUI = {};

/* -------------------------------------------------------------------------- */
/* UTILS
/* -------------------------------------------------------------------------- */
$SP.u = {
  formatMoney: function(v) {
    return '$' + v.toFixed(2);
  }
};

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
    this.$inputs = el.find(':not([name*="active"])');

    this.$active.on('change', $.proxy(this, 'activeChange'));
    this.activeChange();
  };

  Component.prototype = {
    activeChange: function() {
      if (this.$active.is(':checked')) {
        this.$inputs.prop('disabled', false);
      }
      else {
        this.$inputs.prop('disabled', true);
      }
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
        if (!this.exclusivity[condition.scope]) {this.exclusivity[condition.scope] = [];}
        this.exclusivity[condition.scope].push(condition.name);
      }

      condition.$active.on('change', {condition: condition}, $.proxy(this, 'change'));
    }, this);

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

/* -------------------------------------------------------------------------- */
/* SKU PRICING
/* Some conveniences for editing SKU prices.
/* -------------------------------------------------------------------------- */
(function($) {
  var SkuPricing = function(table) {
    this.$table = table;
    this.$tbody = this.$table.find('tbody');
    this.$template = this.$table.find('.template').detach();

    this.pricesCount = this.$table.find('tr.current').length;

    this.$controls = $('<div class="controls"></div>');
    this.$table.before(this.$controls);

    // Add button
    this.$add = $('<button>New Price</button>');
    this.$controls.append(this.$add);
    this.$add.on('click', $.proxy(this, 'add'));

    // Show/hide historical prices
    if (this.$table.find('.historical').length > 0) {
      this.folded = true;
      this.$table.addClass('folded');
      this.$showOlder = $('<a class="button">Show History</a>');
      this.$controls.prepend(this.$showOlder);
      this.$showOlder.on('click', $.proxy(this, 'toggleHistorical'));
    }

    // Toggle rows on and off
    this.$table.find('.expire :checkbox').on('change', $.proxy(this, 'toggleRow'));
  };

  SkuPricing.prototype = {
    add: function(e) {
      var row = this.$template.clone();
      this.pricesCount += 1;
      var prefix = 'sku[price_points_attributes][' + this.pricesCount + ']';
      _.each(row.find(':input'), function(el) {
        var $el = $(el),
            name = $el.attr('name').replace('sku[new_price_point]', prefix);
        $el.attr('name', name);
      }, this);
      row.find('.pricing-mode').islayRadioButtons();
      this.$tbody.prepend(row);
      return false;
    },

    toggleRow: function(e) {
      var $target = $(e.target),
          row = $target.parents('tr')
          inputs = row.find(':text');

      if ($target.is(':checked')) {
        row.addClass('disabled');
        inputs.prop('disabled', true);
      } 
      else {
        row.removeClass('disabled');
        inputs.prop('disabled', false);
      }
    },

    toggleHistorical: function() {
      if (this.folded) {
        this.$table.removeClass('folded');
        this.$showOlder.text('Hide History');
        this.folded = false;
      }
      else {
        this.$table.addClass('folded');
        this.$showOlder.text('Show History');
        this.folded = true;
      }
    }
  };

  $.fn.islaySkuPricing = function() {
    this.each(function() {
      var $this = $(this);
      if (!$this.data('islaySkuPricing')) {
        $this.data('islaySkuPricing', new SkuPricing($this));
      }
    });
    return this;
  };
})(jQuery);

/* -------------------------------------------------------------------------- */
/* DATE SELECTION
/* A date picker that allows multiple modes; month-by-month, range and
/* comparison (using two ranges)
/* -------------------------------------------------------------------------- */
$SP.GUI.DateSelection = Backbone.View.extend({
  tagName: 'form',
  className: 'date-selection',
  modes: ['month', 'range'],
  events: {'click .toggles li': 'toggle'},

  initialize: function() {
    _.bindAll(this, 'toggle');
    if (this.options.mode) {
      this.mode = this.options.mode;
    }
    else {
      if (this.options.action.match(/\/range\/.+\d+$/)) {
        this.mode = 'range'
      }
      else {
        this.mode = 'month'
      }
    }
    this.$el.attr({action: this.options.action, method: 'get'});
    this.toggles = {};

    this.url = this.options.action.replace(/\/(month|range|compare)[\/-].+\d+$/, '');
    var opts = {url: this.url, fullUrl: this.options.action};

    this.widgets = {
      month: new $SP.GUI.DateSelection.Month(opts),
      range: new $SP.GUI.DateSelection.Range(opts)
    };
  },

  toggle: function(e) {
    var $target = $(e.target),
        mode = $target.attr('data-mode');

    if (mode !== this.mode) {
      this.modeOn(mode);
      this.modeOff(this.mode);
      this.mode = mode;
    }
  },

  modeOn: function(mode) {
    this.toggles[mode].addClass('current');
    this.widgets[mode].show();
  },

  modeOff: function(mode) {
    this.toggles[mode].removeClass('current');
    this.widgets[mode].hide();
  },

  render: function() {
    // Render widgets
    _.each(this.widgets, function(widget) {
      this.$el.append(widget.render().el);
    }, this);

    if (!this.options.soloMode) {
      var list = $(this.make('ul', {'class': 'toggles'}));

      _.each(this.modes, function(mode) {
        var toggle = $(this.make('li', {'data-mode': mode}, mode));
        this.toggles[mode] = toggle;
        list.append(toggle);
      }, this);

      this.$el.prepend(list);
      this.modeOn(this.mode);
    }
    else {
      this.widgets[this.mode].show();
    }

    return this;
  }
});

$SP.GUI.DateSelection.Month = Backbone.View.extend({
  tagName: 'ul',
  className: 'month',
  months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  events: {
    'click .back': 'clickBack',
    'click .forward': 'clickForward',
    'click .display span': 'clickDisplay',
    'click .backYear': 'clickYearBack',
    'click .forwardYear': 'clickYearForward',
    'click .months li': 'clickMonth',
  },

  initialize: function() {
    _.bindAll(this,
      'clickBack', 'clickForward', 'clickDisplay', 'clickYearForward',
      'clickYearBack', 'clickMonth', 'hideMenu'
    );

    this.url = this.options.url;

    this.date = new Date();

    var match = this.options.fullUrl.match(/\/month-(\d{4})-(\d{1,2})$/);
    if (match) {
      this.targetYear = this.currentYear = parseInt(match[1]);
      this.currentMonth = parseInt(match[2]) - 1;
    }
    else {
      this.targetYear = this.currentYear = this.date.getFullYear();
      this.currentMonth = this.date.getMonth();
    }
  },

  show: function() {
    this.$el.show();
  },

  hide: function() {
    this.hideMenu();
    this.$el.hide();
  },

  hideMenu: function() {
    this.$menu.hide();
    $(document).off('click', this.hideMenu);
  },

  clickBack: function() {
    if (this.currentMonth === 0) {
      this.goTo(11, this.currentYear - 1);
    }
    else {
      this.goTo(this.currentMonth - 1, this.currentYear);
    }
  },

  clickForward: function() {
    if (this.currentMonth === 11) {
      this.goTo(0, this.currentYear + 1);
    }
    else {
      this.goTo(this.currentMonth + 1, this.currentYear);
    }
  },

  clickDisplay: function(e) {
    this.$menu.show();
    e.stopPropagation();
    $(document).on('click', this.hideMenu);
  },

  clickYearBack: function(e) {
    this.targetYear = this.targetYear - 1;
    this.$year.text(this.targetYear);
    e.stopPropagation();
  },

  clickYearForward: function(e) {
    this.targetYear = this.targetYear + 1;
    this.$year.text(this.targetYear);
    e.stopPropagation();
  },

  clickMonth: function(e) {
    var $target = $(e.target),
        index = parseInt($target.attr('data-index'));

    this.goTo(index, this.targetYear);
  },

  goTo: function(month, year) {
    var url = this.options.url + '/month-' + year + '-' + (month + 1);
    window.location = url;
  },

  render: function() {
    this.$display = $(this.make('span', {}, this.months[this.currentMonth] + ' ' + this.currentYear));
    this.$menu = $(this.make('div', {'class': 'menu'})).hide();
    this.$year = $(this.make('li', {'class': 'year'}, this.currentYear));

    var years = this.make('ul', {'class': 'years'}, [
      this.make('li', {'class': 'backYear'}),
      this.$year[0],
      this.make('li', {'class': 'forwardYear'})
    ]);

    this.$months = _.map(this.months, function(m, i) {
      return $(this.make('li', {'data-index': i}, m));
    }, this);

    var months = this.make('ul', {'class': 'months'}, _.pluck(this.$months, 0));

    this.$menu.append(months, years);

    this.$el.append(
      this.make('li', {'class': 'back'}),
      this.make('li', {'class': 'display'}, [this.$display[0], this.$menu[0]]),
      this.make('li', {'class': 'forward'})
    );

    this.hide();

    return this;
  }
});

$SP.GUI.DateSelection.Range = Backbone.View.extend({
  tagName: 'ul',
  className: 'range',
  events: {'click .start': 'clickStart', 'click .end': 'clickEnd', 'click .go': 'clickGo'},

  initialize: function() {
    _.bindAll(this, 'clickStart', 'clickEnd', 'clickGo', 'startUpdate', 'endUpdate', 'documentClick');

    this.current = null;

    this.url = this.options.url;
    var match = this.options.fullUrl.match(/\/range\/(\d{4}-\d{2}-\d{2})\/(\d{4}-\d{2}-\d{2})$/);
    if (match) {
      this.startDate = moment(match[1]);
      this.endDate = moment(match[2]);
    }
    else {
      var now = new Date();
      this.startDate = moment().startOf('month');
      this.endDate = moment().endOf('month');
    }
  },

  show: function() {
    this.$el.show();
  },

  hide: function() {
    this.$el.hide();
  },

  clickStart: function(e) {
    this.openCalendar(e, 'start');
  },

  clickEnd: function(e) {
    this.openCalendar(e, 'end');
  },

  clickGo: function() {
    var url = this.url + '/range/' + this.startDate.format('YYYY-MM-DD') + '/' + this.endDate.format('YYYY-MM-DD');
    window.location = url;
  },

  startUpdate: function() {
    this.update('start');
  },

  endUpdate: function() {
    this.update('end');
  },

  openCalendar: function(e, pos) {
    if (this.current !== pos) {
      var name = pos + 'Calendar';

      this.$el.find('.' + pos).addClass('current');

      if (!this[name]) {
        this[name] = new Kalendae(this['$' + pos].parent()[0], {selected: this[pos + 'Date']});
        this[name].subscribe('change', this[pos + 'Update']);
      }
      else {
        $(this[name].container).show();
      }

      if (!_.isNull(this.current)) {
        this.close(this.current);
      }
      else {
        $(document).on('click', this.documentClick);
        this.$el.on('click', this.supressEvent);
      }

      this.current = pos;
      e.stopPropagation();
    }
  },

  update: function(pos) {
    var date = pos + 'Date', calendar = pos + 'Calendar';
    this[date] = this[calendar].getSelectedRaw()[0];
    this['$' + pos].text(this[date].format(' D MMM YYYY'));
    this.close(pos);
    this.reset();
  },

  supressEvent: function(e) {
    e.stopPropagation();
  },

  documentClick: function() {
    this.close(this.current);
    this.reset();
  },

  reset: function() {
    $(document).off('click', this.documentClick);
    this.$el.off('click', this.supressEvent);
    this.current = null;
  },

  close: function(pos) {
    var calendar = pos + 'Calendar';
    $(this[calendar].container).hide();
    this.$el.find('.' + pos).removeClass('current');
  },

  render: function() {
    this.$start = $(this.make('span', {}, this.startDate.format(' D MMM YYYY')));
    this.$end = $(this.make('span', {}, this.endDate.format(' D MMM YYYY')));

    this.$el.append(
      this.make('li', {'class': 'start'}, [document.createTextNode('Start:'), this.$start[0]]),
      this.make('li', {'class': 'end'}, [document.createTextNode('End:'), this.$end[0]]),
      this.make('li', {'class': 'go'}, 'Go')
    );

    this.hide();

    return this;
  }
});

/* -------------------------------------------------------------------------- */
/* SEGMENTED CONTROL
/* Simplistic, report-specific segmented control.
/* -------------------------------------------------------------------------- */
$SP.GUI.SegmentedControl = Backbone.View.extend({
  tagName: 'ul',
  className: 'segmented-control',
  events: {'click li': 'click'},

  initialize: function() {
    _.bindAll(this, 'click');
    this.lis = [];
  },

  click: function(e) {
    var $target = $(e.target),
        index = parseInt($target.attr('data-index'));

    if (index !== this.current) {
      var current = this.lis[this.current];
      current.removeClass('current');
      $target.addClass('current');
      this.current = index;
      this.trigger('selected', index);
    }
  },

  render: function() {
    _.each(this.options.labels, function(label, i) {
      var li = $H('li[data-index=' + i + ']', label);
      this.$el.append(li);
      this.lis.push(li);

      if (i === 0) {
        this.current = i;
        li.addClass('current');
      }
    }, this);

    return this;
  }
});

/* -------------------------------------------------------------------------- */
/* LINE GRAPH
/* Wraps gRaphael line graphs. Makes it easier to render.
/* -------------------------------------------------------------------------- */
$SP.GUI.LineGraph = Backbone.View.extend({
  className: 'graph',

  initialize: function() {
    this.x = this.options.values.x;
    this.y = this.options.values.y;
  },

  render: function(width) {
    this.paper = Raphael(this.el);
    this.width = width || this.$el.innerWidth();

    var opts = {symbol: '', axis: '0 0 1 1', axisxstep: 1, axisystep: 5, colors: [this.options.values.color]},
        graphW = width ? width - 60 : 500;

    this.line = this.paper.linechart(30, 0, graphW, 250, this.x, this.y, opts);

    // These callbacks are defined inline, and we use the behaviour of closures
    // to keep our view in scope and call our own handlers. This is because of
    // gRaphael's limited callbacks.
    var view = this;
    this.line.hoverColumn(function() {view.hoverIn(this);}, function() {view.hoverOut(this);});
    this.renderXLabels();

    return this;
  },

  hide: function() {
    this.$el.hide();
    return this;
  },

  show: function() {
    this.$el.show();
    return this;
  },

  hoverIn: function(cover) {
    this.tags = []
    var date = this.options.dates[cover.axis];

    for (var i = 0, ii = cover.y.length; i < ii; i++) {
      var tag = $H('div.graph-label', [
        $H('span.value', this.format(cover.values[i])),
        $H('span.date', date)
      ]);

      this.tags.push(tag);
      this.$el.append(tag);

      var top = cover.y[i] - (tag.outerHeight() / 2);

      // The extra 20px here is a to deal with the odd rendering
      // inconsistencies and to be conservative about making sure the tag
      // always displays.
      if (cover.x + tag.width() + 20 > this.width) {
        tag.addClass('flip');
        tag.css({left: cover.x - tag.outerWidth(), top: top});
      }
      else {
        tag.addClass('regular');
        tag.css({left: cover.x, top: top});
      }
    }
  },

  hoverOut: function() {
    this.tags && _.invoke(this.tags, 'remove');
  },

  format: function(val) {
    var val = val || 0;

    if (this.options.values.monentaryValues) {
      return $SP.u.formatMoney(val);
    }
    else {
      return val;
    }
  },

  renderXLabels: function(labels) {
    var els = this.line.axis[0].text.items;
    els[0].attr({text: _.first(this.options.dates)});
    els[1].attr({text: _.last(this.options.dates)});
  }
});

/* -------------------------------------------------------------------------- */
/* SERIES GRAPH
/* -------------------------------------------------------------------------- */
$SP.GUI.SeriesGraph = Backbone.View.extend({
  className: 'series-graph',

  initialize: function() {
    _.bindAll(this, 'toggle');

    this.current = 0;

    this.values = {
      value:      {x: [], y: [], color: 'green', monentaryValues: true},
      volume:     {x: [], y: [], color: 'blue'},
      sku_volume: {x: [], y: [], color: 'red'}
    };

    _.each(this.options.table.find('tbody tr'), function(el, i) {
      var values = _.map($(el).find('td:not(:first-child)'), function(el) {
        return parseInt($(el).text());
      });

      this.update('value', i, values[0]);
      this.update('volume', i, values[1]);
      this.update('sku_volume', i, values[2]);
    }, this);

    // Determine the date range
    var dths = this.options.table.find('tbody th'),
        dates = _.map(dths, function(el) {return $(el).text();});

    this.graphs = _.map(this.values, function(v) {
      return new $SP.GUI.LineGraph({dates: dates, values: v});
    });

    var ths    = this.options.table.find('thead th:gt(0)'),
        labels = _.map(ths, function(th) {return $(th).text();});

    this.controls = new $SP.GUI.SegmentedControl({labels: labels});
    this.controls.on('selected', this.toggle);

    this.render();
  },

  toggle: function(index) {
    this.graphs[this.current].hide();
    this.graphs[index].show();
    this.current = index;
  },

  update: function(key, x, y) {
    var v = this.values[key];
    v.x.push(x);
    v.y.push(y);
  },

  render: function() {
    this.options.table.before(this.$el).remove();

    this.$el.append(this.controls.render().el);

    _.each(this.graphs, function(view, i) {
      this.$el.append(view.$el);
      view.render(view.$el.innerWidth());

      if (i > 0) {view.hide();}
    }, this);

    return this;
  }
});

/* -------------------------------------------------------------------------- */
/* SORTABLE TABLE
/* -------------------------------------------------------------------------- */
$SP.GUI.SortableTable = Backbone.View.extend({
  events: {'click thead th': 'click'},

  initialize: function() {
    _.bindAll(this, 'click');

    this.$el.addClass('sortable');

    this.body = this.$el.find('tbody');

    this.types = _.map(this.body.find('tr:first-child td'), function(td) {
      var raw = $(td).text();
      if (/^[\$]?\d+\.\d{2}$/.test(raw)) {
        return 'monentary';
      }
      else if (/^\d+$/.test(raw)) {
        return 'integer';
      }
      else {
        return 'string';
      }
    });

    this.columns = [];

    _.each(this.$el.find('tbody tr'), function(row) {
      var $row = $(row);
      _.each($row.find('td'), function(td, i) {
        column = this.columns[i] || (this.columns[i] = [])
        column.push([this._coerce(i, $(td).text()), $row]);
      }, this);
    }, this);

    this.ths = _.map(this.$el.find('thead th'), function(th, i) {
      var $th = $(th);
      $th.attr('data-index', i);
      if ($th.is('.sorted')) {this.current = i;}
      return $th;
    }, this);

  },

  _coerce: function(i, val) {
    switch(this.types[i]) {
      case 'monentary':
        return parseFloat(val.split('$')[1]);
      case 'integer':
        return parseInt(val);
      case 'string':
        return val;
    }
  },

  click: function(e) {
    var $target = $(e.target),
        index = parseInt($target.attr('data-index'));

    if (!$target.is('.sorted')) {
      this.ths[this.current].removeClass('sorted');
      $target.addClass('sorted');
      this.current = index;

      var column = this.columns[index];
      if (this.types[index] === 'string') {
        column.sort(this._alphaSort);
      }
      else {
        column.sort(this._numericSort);
      }
      this.body.find('tr').detach();
      _.each(column, function(row) {this.body.append(row[1])}, this);
    }
  },

  _alphaSort: function(x, y) {
    if (x[0] < y[0]) return -1;
    if (x[0] > y[0]) return 1;
    return 0;
  },

  _numericSort: function(x, y) {
    if (x[0] < y[0]) return 1;
    if (x[0] > y[0]) return -1;
    return 0;
  }
});

/* -------------------------------------------------------------------------- */
/* TABBED TABLE CELL
/* -------------------------------------------------------------------------- */
$SP.GUI.Tabs = Backbone.View.extend({
  initialize: function() {
    _.bindAll(this, 'toggle');

    this.entries = [];
    this.current = 0;
    var labels = [];

    _.each(this.$el.find(this.options.tabs), function(el, i) {
      var $el = $(el);
      this.entries.push($el);
      labels.push($el.find(this.options.labels).remove().text());
    }, this);

    this.controls = new $SP.GUI.SegmentedControl({labels: labels});
    this.controls.on('selected', this.toggle);

    this.render();
  },

  toggle: function(index) {
    this.entries[this.current].hide();
    this.entries[index].show();
    this.current = index;
  },

  render: function() {
    this.$el.find('h3').after(this.controls.render().el);
    _.each(this.entries, function(el, i) {
      if (this.options.sortable === true) {
        var view = new $SP.GUI.SortableTable({el: el});
      }
      if (i > 0) {
        el.hide();
      }
    }, this);

    return this;
  }
});

$SP.where('#islay-shop-admin-product-categories.show, #islay-shop-admin-products.index').select('table ul.children').run(function(collection) {
  var children = _.map(collection, function(list) {
    return new Islay.TableDisclosure({el: $(list)});
  });
});

$SP.where('#islay-admin-dashboard.index').run(function() {
  var graph = new $SP.GUI.SeriesGraph({table: $('.series-graph')});
});

$SP.where('#islay-shop-admin-reports.index').run(function() {
  var graph = new $SP.GUI.SeriesGraph({table: $('.series-graph')});
  var topTen = new $SP.GUI.Tabs({el: $("#top-ten"), tabs: 'table', labels: 'caption'});
  var dates = new $SP.GUI.DateSelection({action: window.location.href, soloMode: true});
  $('#sub-header').append(dates.render().el);
});

$SP.where('#islay-shop-admin-reports.orders').run(function() {
  var graph = new $SP.GUI.SeriesGraph({table: $('.series-graph')});
  var orders = new $SP.GUI.SortableTable({el: $("#orders-summary")});
  var tabs = new $SP.GUI.Tabs({el: $("#bests"), tabs: 'div.day, div.month', labels: 'h4'});
  var dates = new $SP.GUI.DateSelection({action: window.location.href});
  $('#sub-header').append(dates.render().el);
});

$SP.where('#islay-shop-admin-reports.products').run(function() {
  var tabs = new $SP.GUI.Tabs({el: $("#product-listing"), sortable: true, tabs: 'table', labels: 'caption'});
});

$SP.where('#islay-shop-admin-reports.product').run(function() {
  var graph = new $SP.GUI.SeriesGraph({table: $('.series-graph')});
  var skus = new $SP.GUI.SortableTable({el: $("#skus-summary")});
  var orders = new $SP.GUI.SortableTable({el: $("#orders-summary")});
  var tabs = new $SP.GUI.Tabs({el: $("#bests"), tabs: 'div.day, div.month', labels: 'h4'});

  var dates = new $SP.GUI.DateSelection({action: window.location.href});
  $('#sub-header').append(dates.render().el);
});

$SP.where('#islay-shop-admin-reports.sku').run(function() {
  var graph = new $SP.GUI.SeriesGraph({table: $('.series-graph')});
  var dates = new $SP.GUI.DateSelection({action: window.location.href});
  var tabs = new $SP.GUI.Tabs({el: $("#bests"), tabs: 'div.day, div.month', labels: 'h4'});
  $('#sub-header').append(dates.render().el);
});

$SP.where('#islay-shop-admin-promotions.[edit, new, update, create]').run(function() {
  $('#islay-form').islayPromotions();
});

$SP.where('#islay-shop-admin-skus.[edit, new, update, create]').run(function() {
  $('.islay-shop-sku-pricing table').islaySkuPricing();
  $('.islay-shop-sku-pricing :checkbox').islayCheckbox({mode: 'depressed'});
});
