var MOVEMENT = MOVEMENT || {};

(function($) {
  $.fn.activityFeed = function(maxItemsInFeed, templateSelector) {
    return $(this).each(function() {
      feed = MOVEMENT.initActivityFeed(this, maxItemsInFeed, $(templateSelector));
      return feed.start();
    });
  }
})(jQuery);

MOVEMENT.initActivityFeed = function(root, maxItemsInFeed, templateElement) {
  var self = {};

  self.root = $(root);
  self.emptySlots = self.maxItemsInFeed = maxItemsInFeed;
  self.feedPath = self.root.data("feed-path");
  self.template = templateElement.html();
  self.lastFeedId = null;

  self.start = function () {
    fetchFeed();
    setInterval(fetchFeed, 10000);
  };

  self.createFeedEntry = function(newItem) {
    var message = $('<p>').append(newItem.html);
    var actionLink = message.find("a");
    if (actionLink.length) {
      var actionUrl = "/" + $("body").data("locale") + "/actions/" + actionLink.data("page-name");
      actionLink.attr("href", actionUrl);
    }
    
    newItem.html = message.html();
    newItem.country_iso && (newItem.country_iso = newItem.country_iso.toUpperCase());
    
    return $(Mustache.to_html(self.template, newItem));
  };

  var fetchFeed = function () {
    $.get(self.feedPath).done(function (feeds) {
      var newFeeds = findNewFeeds(feeds);
      if (newFeeds.length > 0)  {
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

  var slideNewItem = function(newItem, callback) {
    var feedEntry = self.createFeedEntry(newItem);
    if(!self.root.children().first().hasClass('bg-med-stripe')) {
      feedEntry.addClass('bg-med-stripe');
    }
    feedEntry.prependTo(self.root);
    feedEntry.hide();


    if (self.emptySlots <= 0) {
      feedEntry.slideDown(500, 'linear', callback);
    } else {
      feedEntry.show();
      self.emptySlots--;
      callback();
    }
  };

  var renderResponse = function(feed) {
    if(isFirstResponse()) {
      feed = splice(feed);
    }
    var newItem = feed.shift();
    if (!newItem) return;
    slideNewItem(newItem, function() {
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

  return self;
};
