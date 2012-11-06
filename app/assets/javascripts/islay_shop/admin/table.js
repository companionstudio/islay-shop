Islay.TableDisclosure = Backbone.View.extend({
  initialize: function() {
    _.bindAll(this, 'click');
    this.open = false;
    this.render();
  },

  click: function() {
    if (this.open) {
      this.open = false;
      this.$button.removeClass('open');
      this.$el.hide();
    }
    else {
      this.open = true;
      this.$button.addClass('open');
      this.$el.show();
    }
  },

  render: function() {
    this.$button = $H('a.children-disclosure').click(this.click);
    this.$el.before(this.$button).hide();
    return this;
  }
});
