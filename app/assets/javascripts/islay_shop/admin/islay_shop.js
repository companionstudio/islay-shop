//= require ../../vendor/raphael-min
//= require ../../vendor/g.raphael-min
//= require ../../vendor/g.pie-min
//= require ../../vendor/g.line-min

var IslayShop = {};

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
    this.line.hoverColumn(this.hoverIn, this.hoverOut);
    if (this.xLabels) {this.renderXLabels(this.xLabels)};

    return this;
  },

  hoverIn: function() {
    this.tags = this.paper.set();

    for (var i = 0, ii = this.y.length; i < ii; i++) {
      var tag = this.paper.tag(this.x, this.y[i], '$' + this.values[i], 0, 9);
      tag.insertBefore(this).attr([{ fill: "black", 'stroke-width': 0}, {fill: 'white'}]);
      this.tags.push(tag);
    }
  },

  hoverOut: function() {
    this.tags && this.tags.remove();
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
    var value = {x: [], y: [], xLabels: []};

    _.each(this.options.table.find('tbody tr'), function(el, i) {
      var values = _.map($(el).find('td:not(:first-child)'), function(el) {
        return parseInt($(el).text());
      })

      value.x.push(i);
      value.xLabels.push(i + 1);
      value.y.push(values[0]);
    });

    this.valueGraph = new IslayShop.LineGraph({color: 'blue', values: value});

    this.render();
  },

  render: function() {
    this.$el.append(this.valueGraph.el);
    this.options.table.before(this.$el).remove();
    this.valueGraph.render();
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
