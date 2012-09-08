//= require ../../vendor/raphael-min
//= require ../../vendor/g.raphael-min
//= require ../../vendor/g.pie-min
//= require ../../vendor/g.line-min

var IslayShop = {};

/* -------------------------------------------------------------------------- */
/* UTILS
/* -------------------------------------------------------------------------- */
IslayShop.u = {
  formatMoney: function(v) {
    return '$' + v.toFixed(2);
  }
};

/* -------------------------------------------------------------------------- */
/* LINE GRAPH
/* Wraps gRaphael line graphs. Makes it easier to render.
/* -------------------------------------------------------------------------- */
IslayShop.LineGraph = Backbone.View.extend({
  className: 'graph',

  initialize: function() {
    this.x = this.options.values.x;
    this.y = this.options.values.y;
    this.xLabels = this.options.values.xLabels;
  },

  render: function() {
    this.paper = Raphael(this.el);

    var opts = {symbol: 'circle', axis: '0 0 1 1', axisxstep: this.x.length - 1, axisystep: 5, gutter: 10};
    this.line = this.paper.linechart(30, 0, 500, 250, this.x, this.y, opts);

    // These callbacks are defined inline, and we use the behaviour of closures
    // to keep our view in scope and call our own handlers. This is because of
    // gRaphael's limited callbacks.
    var view = this;
    this.line.hoverColumn(function() {view.hoverIn(this);}, function() {view.hoverOut(this);});

    if (this.xLabels) {this.renderXLabels(this.xLabels)};

    return this;
  },

  hoverIn: function(cover) {
    this.tags = []

    for (var i = 0, ii = cover.y.length; i < ii; i++) {
      var tag = $H('div.tag', IslayShop.u.formatMoney(cover.values[i]));
      this.tags.push(tag);
      this.$el.append(tag);
      tag.css({left: cover.x, top: cover.y[i] - (tag.outerHeight() / 2)});
    }
  },

  hoverOut: function() {
    this.tags && _.each(this.tags, function(tag) {tag.remove();});
  },

  renderXLabels: function(labels) {
    var els = this.line.axis[0].text.items;
    _.each(labels, function(label, i) {els[i].attr({text: label});});
  }
});

/* -------------------------------------------------------------------------- */
/* SERIES GRAPH
/* -------------------------------------------------------------------------- */
IslayShop.SeriesGraph = Backbone.View.extend({
  className: 'series-graph',

  initialize: function() {
    this.values = {
      value:      {x: [], y: [], xLabels: []},
      volume:     {x: [], y: [], xLabels: []},
      sku_volume: {x: [], y: [], xLabels: []}
    };

    _.each(this.options.table.find('tbody tr'), function(el, i) {
      var values = _.map($(el).find('td:not(:first-child)'), function(el) {
        return parseInt($(el).text());
      })

      this.update('value', i, values[0], i + 1);
      this.update('volume', i, values[1], i + 1);
      this.update('sku_volume', i, values[2], i + 1);
    }, this);

    this.graphs = _.map(this.values, function(v) {
      return new IslayShop.LineGraph({color: 'blue', values: v});
    });

    this.render();
  },

  update: function(key, x, y, label) {
    var v = this.values[key];
    v.x.push(x);
    v.y.push(y);
    if (label) {v.xLabels.push(label);}
  },

  render: function() {
    this.options.table.before(this.$el).remove();
    _.each(this.graphs, function(view) {
      this.$el.append(view.el);
      view.render();
    }, this);
    return this;
  }
});

/* -------------------------------------------------------------------------- */
/* SKU TOP TEN
/* -------------------------------------------------------------------------- */
IslayShop.TopTen = Backbone.View.extend({
  events: {'click .segmented li': 'click'},

  initialize: function() {
    this.tables = [];

    _.each(this.$el.find('table'), function(table, i) {
      var $table = $(table);
      this.tables.push({table: $table, caption: $table.find('caption').text()});
    }, this);

    this.render();
  },

  click: function(e) {
    var $target = $(e.target),
        index = parseInt($target.attr('data-index'));

    if (index !== this.current) {
      var current = this.tables[this.current];
      current.li.removeClass('current');
      current.table.hide();

      $target.addClass('current');
      this.tables[index].table.show();
      this.current = index;
    }
  },

  render: function() {
    this.links = $H('ul.segmented');

    _.each(this.tables, function(c, i) {
      var li = $H('li[data-index=' + i + ']', c.caption);
      this.links.append(li);
      c.li = li;

      if (i > 0) {
        c.table.hide();
        this.current = i;
        li.addClass('current');
      }
    }, this);

    this.$el.find('h3').after(this.links);

    return this;
  }
});

$SP.where('#islay-shop-admin-reports.index').run(function() {
  var graph = new IslayShop.SeriesGraph({table: $('.series-graph')});
  var topTen = new IslayShop.TopTen({el: $("#top-ten")});
});
