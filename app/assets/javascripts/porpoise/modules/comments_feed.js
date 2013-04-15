var MOVEMENT = MOVEMENT || {};

(function($) {
  $.fn.commentsFeed = function(maxItemsInFeed, templateSelector) {
    return $(this).each(function() {
      return MOVEMENT.commentsFeed.init(this, maxItemsInFeed, $(templateSelector));
    });
  }
})(jQuery);

MOVEMENT.commentsFeed = (function() {
  var self = {};

  self.init = function(root, maxItemsInFeed, template) {
    self.root = $(root);
    self.template = template;
    self.lastFeedId = null;
    self.emptySlots = self.maxItemsInFeed = maxItemsInFeed;
    self.commentsContainer = self.root.find('ul');
    self.feedPath = self.root.data("feed-path");

    fetchFeed();
    setInterval(fetchFeed, 10000);
  };

  var fetchFeed = function() {
    $.get(self.feedPath).done(function(feeds) {
      var newFeeds = findNewFeeds(feeds);
      if (newFeeds.length > 0)  {
        self.root.show();
        self.lastFeedId = newFeeds[newFeeds.length - 1].id;
      }
      renderResponse(newFeeds);
    });
  };

  var findNewFeeds = function (feeds) {
    if(feeds.length == 0) return feeds;
    var arr = $.map(feeds, function (feed) {
      return feed.id;
    });
    return feeds.slice(arr.indexOf(self.lastFeedId) + 1, arr.size);
  };

  var renderResponse = function(feed) {
    if(isFirstResponse()) {
      feed = splice(feed);
    }
    
    var newItem = feed.shift();
    if (!newItem) return;

    render(newItem, function() {
      renderResponse(feed);
    });
  };

  function isFirstResponse() {
    return (self.emptySlots == self.maxItemsInFeed);
  }

  function splice(feed) {
    var max = self.maxItemsInFeed;
    var begin = (feed.length - max) < 0 ? -999 : (feed.length - max)
    return feed.splice(begin, max);
  }

  function render(newItem, callback) {
    var newFeedEntry = createFeedEntry(newItem)
    if (self.commentsContainer.children().first().hasClass('odd')) {
      newFeedEntry.removeClass('odd').addClass('even');
    }
    newFeedEntry.prependTo(self.commentsContainer);
    if (!hasEmptySlots()) {
      newFeedEntry.slideDown('slow', callback);
    }
    else {
      self.emptySlots--;
      newFeedEntry.show();
      !hasEmptySlots() && lockRootHeight();
      callback();
    }
  }

  function hasEmptySlots() {
    return (self.emptySlots > 0)
  }

  function lockRootHeight() {
    var holder = self.root.find('div.comments');
    var maxHeight = holder.height();
    holder.height(maxHeight);
  }

  function createFeedEntry(newItem) {
    newItem.country_iso && (newItem.country_iso = newItem.country_iso.toUpperCase());
    return $(Mustache.to_html(self.template.html(), newItem)).hide();
  }

  return self;
})();