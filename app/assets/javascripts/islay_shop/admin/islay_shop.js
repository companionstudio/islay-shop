//= require ../../vendor/d3.min
//= require ../../vendor/d3.layout.min
//= require ../../vendor/rickshaw

var IslayShop = {};


IslayShop.LineGraph = Backbone.View.extend({
  className: 'graph',

  initialize: function() {
    this.graph = new Rickshaw.Graph({
      width: 500,
      height: 300,
      renderer: 'line',
      element: this.el,
      series: [{color: this.options.color, data: this.options.values}]
    });

    this.yAxis = new Rickshaw.Graph.Axis.Y({graph: this.graph});
    var time = new Rickshaw.Fixtures.Time();
    var days = time.unit('day');
    this.xAxis = new Rickshaw.Graph.Axis.Time({
      graph: this.graph,
      timeUnit: days
    });

    var hoverDetail = new Rickshaw.Graph.HoverDetail({
      graph: this.graph,
      formatter: function(series, x, y) {
        return y + ' ' + x;
      }
    });
  },

  render: function() {
    this.graph.render();
    return this;
  }
});

/* -------------------------------------------------------------------------- */
/* SERIES GRAPH
/* -------------------------------------------------------------------------- */
IslayShop.SeriesGraph = Backbone.View.extend({
  className: 'series-graph',

  initialize: function() {
    var value = [],
        volume = [],
        sku_volume = [];

    _.each(this.options.table.find('tbody tr'), function(el, i) {
      var values = _.map($(el).find('td:not(:first-child)'), function(el) {
        return parseInt($(el).text());
      })

      value.push({x: i + 1, y: values[0]});
      volume.push({x: i, y: values[1]});
      sku_volume.push({x: i, y: values[2]});
    });

    this.valueGraph = new IslayShop.LineGraph({color: 'blue', values: value});
    // this.volumeGraph = new IslayShop.LineGraph({color: 'green', values: volume});
    // this.skuVolumeGraph = new IslayShop.LineGraph({color: 'red', values: sku_volume});

    this.render();
  },

  render: function() {
    // this.$el.append(this.valueGraph.el, this.volumeGraph.el, this.skuVolumeGraph.el);
    this.$el.append(this.valueGraph.el);
    this.options.table.before(this.$el).remove();
    this.valueGraph.render();
    // this.volumeGraph.render();
    // this.skuVolumeGraph.render();
    return this;
  }
});

$SP.where('#islay-shop-admin-reports.index').select('.series-graph').run(function(table) {
  var graph = window.graph = new IslayShop.SeriesGraph({table: table});
});
