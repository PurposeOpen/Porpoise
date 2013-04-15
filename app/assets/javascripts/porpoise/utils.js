var MOVEMENT = MOVEMENT || {};

MOVEMENT.utils = {
  isSelectLabelSelected: function (select) {
    select = $(select);
    var selectedOption = select.find('option:selected');
    var firstOption = $(select.find('option')[0]);
    var firstOptionIsLabel = firstOption.attr('disabled') != undefined;
    return selectedOption.val() === firstOption.val() && firstOptionIsLabel;
  }
};