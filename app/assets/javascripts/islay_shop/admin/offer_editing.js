/* -------------------------------------------------------------------------- */
/* OFFER EDITOR
/* Some conveniences for editing offers.
/* -------------------------------------------------------------------------- */
(function($) {
  var OfferEditing = function(table) {
    this.$table = table;
    this.$tbody = this.$table.find('tbody');
    this.$template = this.$table.find('.template').detach();

    this.pricesCount = this.$table.find('tr.current').length;

    this.$controls = $('<div class="controls"></div>');
    this.$table.before(this.$controls);

    // Add button
    this.$add = $('<button>Add another item</button>');
    this.$controls.append(this.$add);
    this.$add.on('click', $.proxy(this, 'add'));

    // Init radio buttons for 'new' records
    this.$table.find('tr.new .pricing-mode').islayRadioButtons();

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

  OfferEditing.prototype = {
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

  $.fn.islayOfferEditing = function() {
    this.each(function() {
      var $this = $(this);
      if (!$this.data('islayOfferEditing')) {
        $this.data('islayOfferEditing', new OfferEditing($this));
      }
    });
    return this;
  };
})(jQuery);
