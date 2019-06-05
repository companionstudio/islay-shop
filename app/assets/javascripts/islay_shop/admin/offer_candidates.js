/* -------------------------------------------------------------------------- */
/* OFFER CANDIDATES
/* Some conveniences for generating offer orders
/* -------------------------------------------------------------------------- */
(function($) {
  var OfferCandidates = function(table) {
    this.$table = table;
    this.$button = table.find('a[data-action=generate-orders]');
    this.$checkboxes = table.find('tbody :checkbox');
    this.$orderLinks = table.find('tbody a.order-link');
    this.$status = table.find('tfoot td.status');

    this.baseHref = this.$button.attr('href');

    this.$table.on('change', ':checkbox', $.proxy(this, 'updateTable'));

    this.updateTable();
  };

  OfferCandidates.prototype = {
    updateTable: function(e) {
      var selected = this.$checkboxes.filter(':checked'),
          status = [];

      if (selected.length) {
        this.$button
          .attr('href', this.baseHref + '?member_ids=' + $.map(selected, function(e){return $(e).val()}).join(','))
          .removeClass('is-disabled');
      } else {
        this.$button.addClass('is-disabled');
        this.$button.attr('href', null)
      }

      if (selected.length) {status.push(selected.length + ' selected');}
      status.push(this.$checkboxes.length + ' candidates');
      status.push(this.$orderLinks.length + ' orders generated');

      this.$status.html(status.join('. '))
    },
  };

  $.fn.islayOfferCandidates = function() {
    this.each(function() {
      var $this = $(this);
      if (!$this.data('islayOfferCandidates')) {
        $this.data('islayOfferCandidates', new OfferCandidates($this));
      }
    });
    return this;
  };
})(jQuery);
