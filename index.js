/*--
This file contains all the function for
the Batcave Opdrachten (edit) view.
--*/

// MINA KODUM GOT
$(document).on('click', '.batcave-assignment-section-buttons.matching .bg--green', function() {
  $('#assignment-matching-card-form').submit();
})




/*-------------------------------------------------------------------------------------------
/-------> Batcave: $(document).ready
-------------------------------------------------------------------------------------------*/

// Run some functions to show values in sections
$(document).ready(function() {
  if($('.oracle-content-section').length > 0) {
    var budgetValue = $('.batcave-assignment-section-split-left.budgetType > .inputIcon > input').val();
    var verbindPrijs = $('.verbindprijs input');

    if(budgetValue != 'Geen budget' && verbindPrijs.val() == '') {
      calculateVerdienPrijs();
    }

    changeAssignmentFieldsState();
    updateAssignmentCard();
  }
});

// Change Verdienprijs based on changes of deadline, budget etc.
$(document).on('click', '#assignment-assignment-addi-info-form input', function() {
  setTimeout(function() {
    calculateVerdienPrijs();
  }, 50);
});

// Check if budget is filled in
$(document).on('click', '#assignment-assignment-addi-info-form .batcave-assignment-section-button-save .button', function(event) {
  event.preventDefault();

  $('#assignment-assignment-addi-info-form').find('input[type="text"]:not(.is-disabled)').each(function() {
    if($(this).val() == '') {
      $(this).addClass('error');
    }
  });

  if($('#assignment-assignment-addi-info-form input.error').length == 0) {
    $('#assignment-assignment-addi-info-form').submit();
  }
});


$(document).ready(function() {
  $('.sealedPartners > tbody > tr').each(function(index, item) {
    var projectDate = $(item).find('.sealed-timer-date').text().trim();
    var projectStart = new Date(projectDate.replace(/-/g, "/"));

    $(item).find('.sealed-timer-boxes').countdown(projectStart, function(event) {
      var totalHours = event.offset.totalDays * 24 + event.offset.hours;

      $(this).find('p').text( event.strftime(totalHours + ':%M:%S'));
    });
  });
});


/*-------------------------------------------------------------------------------------------
/-------> Batcave: Opdrachten (edit)
-------------------------------------------------------------------------------------------*/

// Open the assignment section
$(document).on('click', '.oracle-content-section:not(.open)', function() {
  $(this).addClass('open');
});

// Closing the assignment section
$(document).on('click', '.oracle-content-section-head', function() {
  var section = $(this).parents('.oracle-content-section');

  if(section.hasClass('open')) {
    section.removeClass('open');
  }
});





// Opening wishlist delete confirmation
$(document).on('click', '.removeWishlistItem', function() {
  var listItem = $(this).parents('li');
  var deleteConfirm = listItem.find('.delete-wishlist-item-confirm');

  deleteConfirm.addClass('open');
});

// Closing wishlist delete confirmation
$(document).on('click', '.delete-wishlist-item-confirm-button-cancel > .button', function(event) {
  event.preventDefault();

  var listItem = $(this).parents('li');
  var deleteConfirm = listItem.find('.delete-wishlist-item-confirm');

  deleteConfirm.removeClass('open');
});

// Deleting wishlist item
$(document).on('click', '.delete-wishlist-item-confirm-button-save > .button', function(event) {
  event.preventDefault();

  var listItem = $(this).parents('li');
  var wishlist_id = listItem.attr("id").split("_")[1]
  $.when(
    $.ajax({
      type: "DELETE",
      url: "/batcave/opdrachten/wishlist_delete",
      data: {id: wishlist_id},
      dataType: "json",
    })
  ).then(function(data) {
    listItem.remove();
  });
});


// Open services dropdown
$(document).on('click', '.batcave-assignment-services-add > .buttonIcon', function() {
  var button = $(this);
  var container = button.parent();
  var dropdown = container.find('.batcave-assignment-services-dropdown');
  var content = dropdown.find('.transparentScrollbar-Y');
  var searchInput = dropdown.find('.input-search input');
  var items = dropdown.find('ul')
  var noResultsDIV = dropdown.find('.batcave-assignment-services-content-noResults');

  button.addClass('active');
  dropdown.addClass('open');
  searchInput.val('');
  items.find('li').show();
  items.find('li p').unhighlight();
  noResultsDIV.hide();
  content.perfectScrollbar();

  $(document).unbind('mouseup')
  $(document).on('mouseup', function (e) {
    var container = button.add(dropdown)

    // On mouseup hide popover, if not container
    if (!container.is(e.target) && container.has(e.target).length === 0) {
      dropdown.removeClass('open');
      button.removeClass('active');

      // Unbind mouseup function
      $(document).unbind('mouseup');
    }
  });

  return false;
});

// Searching in the services dropdown
$(document).on('keyup', '.batcave-assignment-services-search input', function() {
  var inputValue = $(this).val();
  var dropdown = $(this).parents('.batcave-assignment-services-dropdown');
  var content = dropdown.find('.batcave-assignment-services-content');
  var list = content.find('ul');
  var listItem = content.find('ul > li');
  var textHighlight = listItem.find('p');
  var noResultsDIV = content.find('.batcave-assignment-services-content-noResults');
  var emptyDIV = content.find('.batcave-assignment-services-content-empty');
  var ignore = '';

  filterItemsByKeyup(inputValue, content, list, textHighlight, noResultsDIV, emptyDIV, ignore);

  if(inputValue == '' && listItem.not('.hide').length == 0) {
    emptyDIV.show();
  }
});

// Resetting the services dropdown by clicking the ( x )
$(document).on('click', '.batcave-assignment-services-search .input-search-close', function() {
  var container = $(this).parents('.batcave-assignment-services-add');
  var dropdown = container.find('.batcave-assignment-services-dropdown');
  var searchInput = dropdown.find('.input-search input');
  var items = dropdown.find('ul')
  var noResultsDIV = dropdown.find('.batcave-assignment-services-content-noResults');

  searchInput.val('');
  items.find('li').show();
  items.find('li p').unhighlight();
  noResultsDIV.hide();
});

// Selecting a service in the dropdown
$(document).on('click', '.batcave-assignment-services-content > ul > li > label', function() {
  var label = $(this);
  var listItem = $(this).parent();
  var dropdown = $(this).parents('.batcave-assignment-services-dropdown');
  var content = dropdown.find('.batcave-assignment-services-content');
  var serviceID = listItem.find('input:hidden[id^="service_id"]').val();
  var serviceType = listItem.find('input:hidden[id^="service_type"]').val();
  var serviceName = label.find('p').text().trim();
  var serviceIcon = listItem.find('> .global--icon').html().trim();
  var list = content.find('> ul > li');
  var checkbox = listItem.find('input[type="checkbox"]');
  var servicesList = dropdown.parents('.batcave-assignment-section').find('ul.services');

  setTimeout(function() {
    if(checkbox.prop('checked') == true) {
      var exists = false;
      servicesList.find('> li').each(function(index, item) {
        var serviceIDAdded = $(item).find('input:hidden[name="services[][id]"]').val();
        var serviceTypeAdded = $(item).find('input:hidden[name="services[][type]"]').val();
        if(serviceIDAdded == serviceID && serviceTypeAdded == serviceType) {
          $(item).find('input:hidden[name="services[][deleted]"]').val(false);
          $(item).show();
          exists = true

          return false;
        } else {
          exists = false
        }
      });

      if (exists == false) {
        servicesList.append('\
          <li>\
            <input name="services[][id]" type="hidden" value="'+ serviceID +'">\
            <input name="services[][type]" type="hidden" value="'+ serviceType +'">\
            <input name="services[][deleted]" type="hidden" value="false">\
            <div class="global--icon global--icon--xxxs icon--raven">\
              '+ serviceIcon +'\
            </div>\
            <p class="fontWeight-Medium fontSize-13 color-obsidian truncateText">'+ serviceName +'</p>\
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 14 14" width="8" height="8">\
              <path fill="#9B9B9B" fill-rule="evenodd" d="M9.849 7l3.561-3.561A2.014 2.014 0 1 0 10.561.59L7 4.151 3.439.59A2.014 2.014 0 1 0 .59 3.439L4.151 7 .59 10.561a2.014 2.014 0 1 0 2.849 2.849L7 9.849l3.561 3.561a2.014 2.014 0 1 0 2.849-2.849L9.849 7z"></path>\
            </svg>\
          </li>\
        ');

      }
    } else {
      servicesList.find('> li').each(function(index, item) {
        var serviceIDAdded = $(item).find('input:hidden[name="services[][id]"]').val();
        var serviceTypeAdded = $(item).find('input:hidden[name="services[][type]"]').val();

        if(serviceIDAdded == serviceID && serviceTypeAdded == serviceType) {
          if($(item).hasClass('existing')) {
            $(item).hide();
            $(item).find('input:hidden[name="services[][deleted]"]').val(true);
          } else {
            $(item).remove();
          }
        }
      });

    }
  }, 50)
});

// Removing service by clicking the service item
$(document).on('click', '.batcave-assignment-section > ul.services > li:not(.noCross)', function() {
  var listItem = $(this);
  var clickedServiceID = listItem.find('input:hidden[name="services[][id]"]').val();
  var clickedServiceType = listItem.find('input:hidden[name="services[][type]"]').val();
  var clickedServiceDeleted = listItem.find('input:hidden[name="services[][deleted]"]')
  var section = $(this).parents('.batcave-assignment-section');
  var dropdown = section.find('.batcave-assignment-services-dropdown');

  dropdown.find('ul > li').each(function() {
    var serviceID = $(this).find('input:hidden[id^="service_id"]').val();
    var serviceType = $(this).find('input:hidden[id^="service_type"]').val();

    if(serviceID == clickedServiceID && serviceType == clickedServiceType) {
      $(this).find('input').prop('checked', false);
      $(this).show();
    }
  });

  if(listItem.hasClass('existing')) {
    listItem.hide();
    clickedServiceDeleted.val(true);
  } else {
    listItem.remove();
  }

  dropdown.find('.transparentScrollbar-Y').perfectScrollbar('update');
});




// Opening attachment delete confirmation
$(document).on('click', '.removeAttachment', function() {
  var listItem = $(this).parents('li');
  var deleteConfirm = listItem.find('.delete-attachment-confirm');

  deleteConfirm.addClass('open');
});

// Closing attachment delete confirmation
$(document).on('click', '.delete-attachment-confirm-button-cancel > .button', function(event) {
  event.preventDefault();

  var listItem = $(this).parents('li');
  var deleteConfirm = listItem.find('.delete-attachment-confirm');

  deleteConfirm.removeClass('open');
  listItem.find('p.color-steel').show();
  listItem.find('p.color-red').hide();
});

// Deleting attachment item
$(document).on('click', '.delete-attachment-confirm-button-save > .button', function(event) {
  event.preventDefault();

  var listItem = $(this).parents('li');
  listItem.find('input:hidden[name="attachments[][deleted]"]').val(true);
  var deleteConfirm = listItem.find('.delete-attachment-confirm');

  deleteConfirm.removeClass('open');
  listItem.find('p.color-steel').hide();
  listItem.find('p.color-red').show();
});

// Showing/Hiding attachment on click
$(document).on('click', '.hideAndShow-attachment-buttons label', function() {
  var listItem = $(this).parents('li');
  var labelParent = $(this).parent();
  var clickedItem = labelParent.find('p').text();
  var attachmentHidden = listItem.find('input[name="hidden_assignment_attachments[][is_hidden]"]');

  var attachmentHiddenBox = listItem.find('.hideAndShow-attachment-box');

  if(clickedItem == 'Show') {
    attachmentHiddenBox.addClass('hiddenAttachment');
    attachmentHidden.val(false)

  } else if(clickedItem == 'Hide') {
    attachmentHiddenBox.removeClass('hiddenAttachment');
    attachmentHidden.val(true)
  }
});

// Add expanding class to textarea's
$(document).ready(function() {
  $('.assignmentExpanding textarea').expanding();

  $('.assignmentDescription').each(function() {
    var listItem = $(this);
    var quillEditor = listItem.find('.batcave-assignment-editor').attr('id');
    var quillEditorID = '#' + quillEditor;

    var quill = new Quill(quillEditorID, {
      placeholder: 'Voeg een opdrachtomschrijving toe',
    });

    quill.on('text-change', function(delta, source) {
      var editorContent = qlEditor.html();
      quillTextarea.html(editorContent);
    });

    var qlEditor = $(quillEditorID).find(' > .ql-editor')
    var quillTextarea = listItem.find('textarea')

    qlEditor.html(quillTextarea.text());

    // quill.clipboard.addMatcher (Node.ELEMENT_NODE, function (node, delta) {
    //   var plaintext = $ (node).text ();

    //   return new Delta().insert (plaintext);
    // });
  });
});




// Opening the dropdown for more selections
$(document).on('click', '.inputIcon--select input', function() {
  var inputIcon = $(this).parent();
  var dropdown = inputIcon.find('.inputIcon--dropdown');

  dropdown.addClass('open');
  dropdown.perfectScrollbar();

  $(document).unbind('mouseup')
  $(document).on('mouseup', function (e) {
    var container = $('.nuttin');

    // On mouseup hide popover, if not container
    if (!container.is(e.target) && container.has(e.target).length === 0) {
      dropdown.removeClass('open');

      // Unbind mouseup function
      $(document).unbind('mouseup');
    }
  });

  return false;
});

// Selecting input from inputIcon--dropdown
$(document).on('click' , '.inputIcon--dropdown input', function() {
  var container = $(this).parents('.inputIcon');
  var input = container.find('> input');
  var clickedValue = $(this).parent().find('p').text();

  // If default item is clicked, reset value so that placeholder is shown
  if($(this).hasClass('default')) { input.val('');
  } else { input.val(clickedValue); }

  changeAssignmentFieldsState();
});

// Changing budget dropdown on selection
$(document).on('click', '.batcave-assignment-section-split-left.budgetType ul > li', function() {
  var split = $(this).parents('.batcave-assignment-section-split');
  var budget = split.find('.batcave-assignment-section-split-budget');
  var budgetText = $(this).find('p').text().trim();

  if(budgetText == 'Vast bedrag - range') {
    budget.removeClass('settingValueToDots');
    budget.empty().append('\
      <div class="inputIcon inputIcon--s inputIcon--select noIcon">\
        <input class="input input--s" name="assignment_budget[sum]" placeholder="€50.000 - €125.000" readonly="" type="text" value="€250 - €1.000">\
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 40" width="10" height="6">\
          <path fill="#9B9B9B" fill-rule="evenodd" d="M32 40c-2.21 0-4.21-.895-5.657-2.343l-24-24A8 8 0 0 1 13.657 2.343L30.56 19.247c.795.795 2.05.829 2.878 0L50.343 2.343a8 8 0 0 1 11.314 11.314l-24 24A7.975 7.975 0 0 1 32 40z"></path>\
        </svg>\
        <div class="inputIcon--dropdown transparentScrollbar-Y">\
          <ul>\
            <li>\
              <input id="inputIcon-budget0" type="radio">\
              <label for="inputIcon-budget0">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€250 - €1.000</p>\
              </label>\
            </li>\
            <li>\
              <input id="inputIcon-budget1" type="radio">\
              <label for="inputIcon-budget1">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€1.000 - €3.000</p>\
              </label>\
            </li>\
            <li>\
              <input id="inputIcon-budget2" type="radio">\
              <label for="inputIcon-budget2">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€3.000 - €8.000</p>\
              </label>\
            </li>\
            <li>\
              <input id="inputIcon-budget3" type="radio">\
              <label for="inputIcon-budget3">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€8.000 - €15.000</p>\
              </label>\
            </li>\
            <li>\
              <input id="inputIcon-budget4" type="radio">\
              <label for="inputIcon-budget4">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€15.000 - €50.000</p>\
              </label>\
            </li>\
            <li>\
              <input id="inputIcon-budget5" type="radio">\
              <label for="inputIcon-budget5">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€50.000 - €125.000</p>\
              </label>\
            </li>\
          </ul>\
        </div>\
      </div>\
    ');

    $('input[name="assignment_budget[selection]"]').val('');

  } else if(budgetText == 'Per uur - range') {
    budget.removeClass('settingValueToDots');
    budget.empty().append('\
      <div class="inputIcon inputIcon--s inputIcon--select noIcon">\
        <input class="input input--s" name="assignment_budget[sum]" placeholder="€45 - €65" readonly="" type="text" value="€45 - €65">\
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 40" width="10" height="6">\
          <path fill="#9B9B9B" fill-rule="evenodd" d="M32 40c-2.21 0-4.21-.895-5.657-2.343l-24-24A8 8 0 0 1 13.657 2.343L30.56 19.247c.795.795 2.05.829 2.878 0L50.343 2.343a8 8 0 0 1 11.314 11.314l-24 24A7.975 7.975 0 0 1 32 40z"></path>\
        </svg>\
        <div class="inputIcon--dropdown transparentScrollbar-Y">\
          <ul>\
            <li>\
              <input id="inputIcon-budgetUur0" type="radio">\
              <label for="inputIcon-budgetUur0">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€45 - €65</p>\
              </label>\
            </li>\
            <li>\
              <input id="inputIcon-budgetUur1" type="radio">\
              <label for="inputIcon-budgetUur1">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€65 - €95</p>\
              </label>\
            </li>\
            <li>\
              <input id="inputIcon-budgetUur2" type="radio">\
              <label for="inputIcon-budgetUur2">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€95 - €125</p>\
              </label>\
            </li>\
            <li>\
              <input id="inputIcon-budgetUur3" type="radio">\
              <label for="inputIcon-budgetUur3">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€125 - €150</p>\
              </label>\
            </li>\
            <li>\
              <input id="inputIcon-budgetUur4" type="radio">\
              <label for="inputIcon-budgetUur4">\
                <p class="fontWeight-Medium fontSize-14 color-kadett truncateText">€150+</p>\
              </label>\
            </li>\
          </ul>\
        </div>\
      </div>\
    ');

    $('input[name="assignment_budget[selection]"]').val('');

  } else if(budgetText == 'Vast bedrag - specifiek' || budgetText == 'Per uur - specifiek') {
    budget.addClass('settingValueToDots');
    budget.empty().append('\
      <input class="input input--s" name="assignment_budget[sum]" placeholder="€125.000" value="€125.000">\
    ');

    $('input[name="assignment_budget[selection]"]').val('Unlimited');
  }
});

// Disable/Enable fields based on user choice
function changeAssignmentFieldsState() {
  var startDateSelection = $('.assignmentStartDateType input[type="text"]').val();
  var startDate = $('.assignmentStartDate input[type="text"]');
  var budgetType = $('.budgetType input[type="text"]').val();
  var budgetHourlyType = $('.budgetHourlyType input[type="text"]');
  var budgetHourly = $('.budgetHourly input[type="text"]');
  var deadlineSelection = $('.assignmentDeadlineType input[type="text"]').val();
  var deadline = $('.assignmentDeadline input[type="text"]');

  if(startDateSelection == 'Anders') { startDate.removeClass('is-disabled');
  } else {
    startDate.addClass('is-disabled');
    startDate.val('');
  }

  if(budgetType == 'Per uur - range' || budgetType == 'Per uur - specifiek') {
    budgetHourlyType.removeClass('is-disabled');
    budgetHourly.removeClass('is-disabled');
  } else {
    budgetHourlyType.addClass('is-disabled').val('');
    budgetHourly.addClass('is-disabled').val('');
  }

  if(deadlineSelection == 'Geen einddatum') {
    deadline.addClass('is-disabled').val('');
  } else {
    deadline.removeClass('is-disabled');
  }
}

// Calculate the 'Verdienprijs' based on budget
function calculateVerdienPrijs() {
  var budgetType = $('.budgetType input[type="text"]').val();
  var budgetValue = $('.budgetValue').find('input[type="text"]:visible').val();
  var verdienPrijs;

  // Regelt de min en max van het budget
  if(budgetType != 'Vast bedrag - specifiek' && budgetType != 'Per uur - specifiek') {
    var budgetMinText = budgetValue.split('-')[0]
    var budgetMin = budgetValue.split('-')[0].replace(/\€/g, '').replace(/€|&euro/g, '').replace(/\s*\u20ac\s*/ig,'');
    budgetMin = budgetMin.replace(/\./g, '');
    budgetMin = budgetMin.replace(/\,/g, '.').trim();

    var budgetMax = budgetValue.split('-')[1].replace(/\€/g, '').replace(/€|&euro/g, '').replace(/\s*\u20ac\s*/ig,'');
    budgetMax = budgetMax.replace(/\./g, '');
    budgetMax = budgetMax.replace(/\,/g, '.').trim();
  }

  if(budgetType == 'Vast bedrag - range') {
    if(budgetMin < 15000) {
      var verdienPrijs = (parseInt(budgetMin) + parseInt(budgetMax)) / 2;
      verdienPrijs = dotSeparateNumber(verdienPrijs);
      verdienPrijs = '€' + verdienPrijs
    } else if(budgetMin >= 15000) {
      verdienPrijs = budgetMinText;
    }

  } else if(budgetType == 'Vast bedrag - specifiek') {
    verdienPrijs = budgetValue;

  } else if(budgetType == 'Per uur - range' || budgetType == 'Per uur - specifiek') {
    var budgetHourlyType = $('.budgetHourlyType input[type="text"]').val();
    var budgetHourly = $('.budgetHourly input[type="text"]').val();
    var startDateSelection = $('.assignmentStartDateType input[type="text"]').val();
    var deadlineSelection = $('.assignmentDeadlineType input[type="text"]').val();
    var deadline = $('.assignmentDeadline input[type="text"]').val();

    var dateArray = ['Januari', 'Februari', 'Maart', 'April', 'Mei', 'Juni', 'Juli', 'Augustus', 'September', 'Oktober', 'November', 'December']

    if(startDateSelection == 'Zo snel mogelijk' || startDateSelection == 'Binnen 14 dagen' || startDateSelection == 'Binnen een maand') {
      var startDateCalc = $('#assignment_confirmed_at').val();
      startDateCalc = new Date(startDateCalc.replace(/-/g, "/"))

    } else {
      var startDate = $('.assignmentStartDate input[type="text"]').val();
      var startDay = startDate.split(' - ')[0];
      var startMonth = startDate.split(' - ')[1];
      startMonth = parseInt($.inArray(startMonth, dateArray));
      var startYear = startDate.split(' - ')[2];

      startDateCalc = new Date(startYear, startMonth, startDay);
    }

    var deadlineDay = deadline.split(' - ')[0];
    var deadlineMonth = deadline.split(' - ')[1];
    deadlineMonth = parseInt($.inArray(deadlineMonth, dateArray));
    var deadlineYear = deadline.split(' - ')[2];

    deadlineDateCalc = new Date(deadlineYear, deadlineMonth, deadlineDay);

    var dateMonths = differenceInMonths(deadlineDateCalc, startDateCalc);
    var dateWeeks = differenceInWeeks(deadlineDateCalc, startDateCalc);

    if(budgetHourlyType == 'Eenmalig' || budgetHourlyType == '') {
      verdienPrijs = parseInt(budgetMin) * parseInt(budgetHourly)

    } else if(budgetHourlyType == 'Wekelijks') {
      if(deadlineSelection == 'Geen einddatum') {
        var period = 26;
        verdienPrijs = (parseInt(budgetMin) * parseInt(budgetHourly)) * period;

      } else if(deadlineSelection == 'Tijdelijk') {
        verdienPrijs = (parseInt(budgetMin) * parseInt(budgetHourly)) * parseInt(dateWeeks);
      }

    } else if(budgetHourlyType == 'Maandelijks') {
      if(deadlineSelection == 'Geen einddatum') {
        var period = 12;
        verdienPrijs = (parseInt(budgetMin) * parseInt(budgetHourly)) * period;

      } else if(deadlineSelection == 'Tijdelijk') {
        verdienPrijs = (parseInt(budgetMin) * parseInt(budgetHourly)) * parseInt(dateMonths);
      }
    }

    verdienPrijs = dotSeparateNumber(verdienPrijs);
    verdienPrijs = '€' + verdienPrijs;
  }

  $('.assignmentEarning input[type="text"]').val(verdienPrijs);
}

// Update the assignment preview card (Ontdek)
function updateAssignmentCard() {
  var cardPreview = $('.batcave-assignment-card-preview');
  var cardTitle = cardPreview.find('> p.color-white');
  var cardSubtitle = cardPreview.find('> p.color-ravenDark');
  var cardVerbind = cardPreview.find('.batcave-assignment-card-preview-verbind > p');

  cardSubtitle.text($('.assignmentSubtitle input').val());
  cardTitle.text($('.assignmentTitle input').val());
  cardVerbind.text('Verdien ' + $('.assignmentEarning > input').val());
}

// Calculate percentage of verbind
$(document).on('focusout', '.verbindprijs input, .assignmentEarning input', function() {
  var verbindprijs = $('.verbindprijs input').val();
  var budgetType = $('.budgetType').find('input[type="text"]:visible').val();
  var budgetValue = $('.budgetValue').find('input[type="text"]:visible').val();
  var verdienPrijs = $('.assignmentEarning input[type="text"]').val();

  verbindprijs = verbindprijs.replace(/\€/g, '').replace(/€|&euro/g, '').replace(/\s*\u20ac\s*/ig,'');
  verbindprijs = verbindprijs.replace(/\./g, '');
  verbindprijs = verbindprijs.replace(/\,/g, '.').trim();

  verdienPrijs = verdienPrijs.replace(/\€/g, '').replace(/€|&euro/g, '').replace(/\s*\u20ac\s*/ig,'');
  verdienPrijs = verdienPrijs.replace(/\./g, '');
  verdienPrijs = verdienPrijs.replace(/\,/g, '.').trim();

  if(verbindprijs == '') {
    percent = 0;
    $(this).val('€0')
  } else {
    var percent = (parseInt(verbindprijs) / parseInt(verdienPrijs)) * 100
    percent = Math.round(percent);
  }

  $('.batcave-assignment-percentage input').val(percent + '%');
  $('.batcave-assignment-card-preview > ul.points > li:nth-child(3) > p').text('maar ' + percent + '% 😍')
});

// Change the card preview title
$(document).on('keyup', '.assignmentTitle input', function() {
  var cardPreview = $('.batcave-assignment-card-preview');

  cardPreview.find('> p.color-white').text($(this).val());
});

// Change the card preview subtitle
$(document).on('keyup', '.assignmentSubtitle input', function() {
  var cardPreview = $('.batcave-assignment-card-preview');

  cardPreview.find('> p.color-ravenDark').text($(this).val());
});

// Change the card preview price
$(document).on('focusout', '.batcave-assignment-price > input', function() {
  var cardPreview = $('.batcave-assignment-card-preview');
  var budget = $("#non_usable_budget")
  var budget_hourly = $("#non_usable_budget_hourly")
  var assignment_deadline = $("#non_usable_assignment_deadline")

  cardPreview.find('ul.points > li:nth-child(1) > p').text('Verbindprijs ' + $(this).val());
});

// Change the card preview Earning
$(document).on('focusout', '.assignmentEarning > input', function() {
  var cardPreview = $('.batcave-assignment-card-preview');

  cardPreview.find('.batcave-assignment-card-preview-verbind > p').text('Verdien ' + $(this).val());
});

// Selecting partner from the matching tab
$(document).on('click', '.oracle-content-section-filter-content-table.matchingTab label', function() {
  var tableRow = $(this).parents('tr');
  var input = $(this).parent().find('input[type="checkbox"]')

  setTimeout(function() {
    if(input.prop('checked') == true) {
      tableRow.find('.oracle-table-prio').show();
    } else {
      tableRow.find('.oracle-table-prio').hide();
    }

    var checkedItems = tableRow.parent().find('input:checked').length;
    var saveButton = $('.oracle-content-section-save.matching .button');
    saveButton.text(checkedItems + ' Partners toevoegen aan lijst');
  }, 50);
});

// Selecting a prio from the prio column
function selectingAPrio(clickedItem) {
  var tableRow = clickedItem.parents('tr');
  var company_id = tableRow.attr("id").split("_")[1]
  var prioView = tableRow.find('.oracle-table-prio');
  var prioColumn = tableRow.find('.prioriteit');
  var statusColumn = tableRow.find('.status');
  var tbody = tableRow.parents('tbody');

  if(clickedItem.hasClass('prioOne')) {
    prioView.hide();

    if(tbody.hasClass('matchingPartnersContent')) {
      prioColumn.empty().append('\
        <input type="hidden" name="potential_candidates[][priority]" id="potential_candidates_priority_'+company_id+'" value="1">\
        <button class="button button--xs button--flat bg--red noEmboss">prio 1</button>\
      ');
    } else {
      prioColumn.empty().append('\
        <button class="button button--xs button--flat bg--red noEmboss">prio 1</button>\
      ');
    }

  } else if(clickedItem.hasClass('prioSecond')) {
    prioView.hide();

    if(tbody.hasClass('matchingPartnersContent')) {
      prioColumn.empty().append('\
        <input type="hidden" name="potential_candidates[][priority]" id="potential_candidates_priority_'+company_id+'" value="2">\
        <button class="button button--xs button--flat bg--orange noEmboss">prio 2</button>\
      ');
    } else {
      prioColumn.empty().append('\
        <button class="button button--xs button--flat bg--orange noEmboss">prio 2</button>\
      ');
    }

  } else if(clickedItem.hasClass('prioThird')) {
    prioView.hide();

    if(tbody.hasClass('matchingPartnersContent')) {
      prioColumn.empty().append('\
        <input type="hidden" name="potential_candidates[][priority]" id="potential_candidates_priority_'+company_id+'" value="3">\
        <button class="button button--xs button--flat bg--yellow noEmboss">prio 3</button>\
      ');
    } else {
      prioColumn.empty().append('\
        <button class="button button--xs button--flat bg--yellow noEmboss">prio 3</button>\
      ');
    }

  } else if(clickedItem.hasClass('prioFourth')) {
    prioView.hide();

    if(tbody.hasClass('matchingPartnersContent')) {
      prioColumn.empty().append('\
        <input type="hidden" name="potential_candidates[][priority]" id="potential_candidates_priority_'+company_id+'" value="4">\
        <button class="button button--xs button--flat bg--green noEmboss">prio 4</button>\
      ');
    } else {
      prioColumn.empty().append('\
        <button class="button button--xs button--flat bg--green noEmboss">prio 4</button>\
      ');
    }

  } else if(clickedItem.hasClass('prioFifth')) {
    prioView.hide();

    if(tbody.hasClass('matchingPartnersContent')) {
      prioColumn.empty().append('\
        <input type="hidden" name="potential_candidates[][priority]" id="potential_candidates_priority_'+company_id+'" value="5">\
        <button class="button button--xs button--flat bg--blue noEmboss">prio 5</button>\
      ');
    } else {
      prioColumn.empty().append('\
        <button class="button button--xs button--flat bg--blue noEmboss">prio 5</button>\
      ');
    }

  } else if(clickedItem.hasClass('voorstelAfkeuren')) {
    prioView.hide();
    statusColumn.empty().append('<button class="button button--xs button--flat bg--red noEmboss">afgekeurd</button>');

  } else if(clickedItem.hasClass('prioClose')) {
    prioView.hide();
    prioColumn.empty().append('<p class="fontWeight-Medium fontSize-15 color-obsidian">-</p>');
  }
}

// Selecting a prio from the prio view after CHECK
$(document).on('click', '.oracle-table-prio > ul > li', function(event) {
  event.preventDefault();

  selectingAPrio($(this));

  var tablePrio = $(this).parents('.oracle-table-prio');
  var selectedPrio = $(this).find('button').text().trim().split(' ')[1];
  if(tablePrio.hasClass('geschiktePartners')) {
    var assignment = $("#assignment_id").val();
    var tableRow = tablePrio.parents("tr")
    var company = tableRow.attr("id").split("_")[1]

    $.ajax({
      type: "PUT",
      url: "/batcave/opdrachten/update_priority",
      data: {id: assignment, company: company, priority: selectedPrio},
      dataType: "json",
      success:function(data){
      },
    });
  }
});

// Changing a prio from the prio column
$(document).on('click', '.oracle-table td.prioriteit', function(event) {
  event.preventDefault();

  var tableRow = $(this).parents('tr');
  var prioView = tableRow.find('.oracle-table-prio');

  prioView.show();

  selectingAPrio($(this));
});

// Opening the services popup
$(document).on('click', '.openServicesPopup', function(event) {
  var popup = $(this).parent().find('.transparentScrollbar-Y');

  popup.addClass('open');
  popup.perfectScrollbar();

  $(document).unbind('mouseup')
  $(document).on('mouseup', function (e) {
    var container = popup

    // On mouseup hide popover, if not container
    if (!container.is(e.target) && container.has(e.target).length === 0) {
      popup.removeClass('open');

      // Unbind mouseup function
      $(document).unbind('mouseup');
    }
  });

  return false;
});




// Timer functions in the poule
$(document).ready(function() {
  $(".oracle-content-section.poules").each(function(index, item){
    var projectDate = $(item).find('.poule_end_date').text().trim();
    var projectDateSecond = $(item).find('.poule_end_date_plus').text().trim();
    var projectStart = new Date(projectDate.replace(/-/g, "/"));
    var projectStartSecond = new Date(projectDateSecond.replace(/-/g, "/"));

    if(projectDate == '') {
      $('.headerTimer').find('p.color-obsidian').text('00');

    } else {
      $(item).find('.headerTimer').countdown(projectStart, function(event) {
        var totalHours = event.offset.totalDays * 24 + event.offset.hours;

        if(totalHours < 10) {
          $(this).find('.hours p.color-obsidian').text( event.strftime('%H'));
        } else {
          $(this).find('.hours p.color-obsidian').text( event.strftime(totalHours.toString()));
        }

        $(this).find('.minutes p.color-obsidian').text( event.strftime('%M'));
        $(this).find('.seconds p.color-obsidian').text( event.strftime('%S'));
      });

      $(item).find('.headerTimerSecond').countdown(projectStartSecond, function(event) {
        var totalHours = event.offset.totalDays * 24 + event.offset.hours;

        if(totalHours < 10) {
          $(this).find('.hours p.color-red').text( event.strftime('%H'));
        } else {
          $(this).find('.hours p.color-red').text( event.strftime(totalHours.toString()));
        }
        $(this).find('.minutes p.color-red').text( event.strftime('%M'));
        $(this).find('.seconds p.color-red').text( event.strftime('%S'));

        if(event.elapsed == true) {
          var sectionHead = $(this).parents('.oracle-content-section-head');
          var pouleTag = sectionHead.find('.oracle-content-section-head-poule-live > .button');

          pouleTag.removeClass('bg--green').addClass('bg--red').text('poule is gesloten')

        }
      });
    }
  });
});

// Disablen the poule timer minutes input, for max 59
$(document).on('keydown keyup', '.oracle-content-section-filter-timer li.minutes input', function(event) {
  if($(this).val() > 59 && event.keyCode !== 46 && event.keyCode !== 8) {
    event.preventDefault();
    $(this).val(59);
  }
});





// Selecting partner from the Voorstellen tab
$(document).on('click', '.oracle-content-section-filter-content-table.voorstellenTab label', function() {
  var tableRow = $(this).parents('tr');
  var input = $(this).parent().find('input[type="checkbox"]')

  setTimeout(function() {
    if(input.prop('checked') == true) {
      tableRow.find('.oracle-table-prio').show();
    } else {
      tableRow.find('.oracle-table-prio').hide();
    }
  }, 50);
});

// Remove partners from poules
$(document).on('click', '.oracle-content-section-remove.poules > .button', function(event) {
  event.preventDefault();
  var poule_id = $(this).parents().find(".oracle-content-section.poules").attr("id").split("_")[$(this).parents().find(".oracle-content-section.poules").attr("id").split("_").length - 1]

  var removeIcon = '\
    <div class="uiSquareIcon uiSquareIcon--s button button--flat bg--white noPointerEvents">\
      <div class="global--icon global--icon--xxxs icon--red">\
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="14" height="14">\
          <path fill="#9B9B9B" fill-rule="evenodd" d="M46 6h13a5 5 0 0 1 5 5 5 5 0 0 1-5 5H5a5 5 0 0 1-5-5 5 5 0 0 1 5-5h11a6 6 0 0 1 6-6h18a6 6 0 0 1 6 6zM7 24h25v40H18.599a10 10 0 0 1-9.922-8.748L5.017 26.25A2 2 0 0 1 7 24zm50 0a2 2 0 0 1 1.984 2.25l-3.661 29.002A10 10 0 0 1 45.402 64H32V24h25z"></path>\
        </svg>\
      </div>\
    </div>\
  ';

  removed_partners = []

  $('.poulesContent > tr').each(function(index, item) {
    var input = $(item).find('input[type="checkbox"]');
    var partnerState = $(item).find('td.partnerState');

    if(input.prop('checked') == true) {
      removed_partners.push($(input).attr("id").split("-")[input.attr("id").split("-").length - 1])
    }
  });
});

// Deactivate partners from poules
$(document).on('click', '.oracle-content-section-deActivate.poules > .button', function(event) {
  event.preventDefault();
  var poule = $(this).parents(".oracle-content-section.poules");
  var form = poule.find('form[id*="assignment-poule-companies-edit-form"]')
  $("#poule_section_submit_type").remove();
  $(form).append('<input type="hidden" id="poule_section_submit_type" name="poule_section_submit_type" value="update_poule_companies">');
  form.submit()

  var deactivateIcon = '\
    <div class="uiSquareIcon uiSquareIcon--s button button--flat bg--white noPointerEvents">\
      <div class="global--icon global--icon--xxxs icon--red">\
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 60" width="14" height="14">\
          <path fill="#9B9B9B" fill-rule="evenodd" d="M32 60C14.327 60 0 47.673 0 30 0 12.327 14.327 0 32 0c17.673 0 32 12.327 32 30 0 17.673-14.327 30-32 30zm0-18c6.627 0 12-4.725 12-11.5S38.627 19 32 19s-12 4.725-12 11.5S25.373 42 32 42z"></path>\
        </svg>\
      </div>\
    </div>\
  ';

  poule.find('.poulesContent > tr').each(function(index, item) {
    var input = $(item).find('input[type="checkbox"]');
    var partnerState = $(item).find('td.partnerState');

    setTimeout(function() {
      if(input.prop('checked') == true) {
        partnerState.empty().append(deactivateIcon);
      }
    }, 50);
  });
});

// Deactivate partners from poules
$(document).on('click', '.oracle-content-section-undoSeal.poules > .button', function(event) {
  event.preventDefault();
  var r = confirm("Weet je het zeker!?");
  if (r == true) {
    var poule = $(this).parents(".oracle-content-section.poules");
    var form = poule.find('form[id*="assignment-poule-companies-edit-form"]')
    $("#poule_section_submit_type").remove();
    $(form).append('<input type="hidden" id="poule_section_submit_type" name="poule_section_submit_type" value="undo_seal">');
    form.submit()
  }
});




/*-------------------------------------------------------------------------------------------
/-------> Batcave: Opdrachten (edit) - Switching sections
-------------------------------------------------------------------------------------------*/

// Save 'Opdrachtomschrijving' section
$(document).on('click', '.oracle-content-section-save.opdrachtOmschrijving > .button', function() {
  var opdrachtOmschrijving = $('.oracle-content-section.opdrachtOmschrijving');
  var opdrachtBewerken = $('.oracle-content-section.opdrachtBewerken');

  opdrachtOmschrijving.find('input[type="text"]:not(.is-disabled):not(.input-search)').each(function(index, item) {
    if($(item).val() == '') {
      $(item).addClass('error');
      $('html, body').animate({ scrollTop: $(item).offset().top - 300 }, 300);

      return false;
    }
  });

  opdrachtOmschrijving.find('textarea').each(function(index, item) {
    if($(item).val() == '') {
      $(item).addClass('error');
      $('html, body').animate({ scrollTop: $(item).offset().top - 300 }, 300);

      return false;
    }
  });

  if(!opdrachtOmschrijving.find('input').hasClass('error') &&
     !opdrachtOmschrijving.find('textarea').hasClass('error') &&
     !opdrachtOmschrijving.find('.ql-editor').hasClass('error')) {

    $('.oracle-content-section').removeClass('open');
    opdrachtOmschrijving.addClass('isComplete');
    opdrachtBewerken.addClass('open');

    $('html, body').animate({ scrollTop: opdrachtBewerken.offset().top - 300 }, 10);
    var opdrachtDroom = opdrachtOmschrijving.find('.clientAssignmentDream input').val();
    var opdrachtDesc = opdrachtOmschrijving.find('.clientAssignmentDescription textarea').html().trim();

    opdrachtBewerken.find('.clientAssignmentDream input').val(opdrachtDroom);
    opdrachtBewerken.find('.clientAssignmentDescription textarea').html(opdrachtDesc);
    opdrachtBewerken.find('.clientAssignmentDescription .ql-editor').html(opdrachtBewerken.find('.clientAssignmentDescription textarea').text());
    saveProcessStep("step_1");
  }
});

// Save 'Opdracht bewerken' section
$(document).on('click', '.oracle-content-section-save.opdrachtBewerken > .button', function() {
  var opdrachtBewerken = $('.oracle-content-section.opdrachtBewerken');
  var matching = $('.oracle-content-section.matching');

  opdrachtBewerken.find('input[type="text"]:not(.is-disabled):not(.input-search)').each(function(index, item) {
    if($(item).val() == '') {
      $(item).addClass('error');
      $('html, body').animate({ scrollTop: $(item).offset().top - 300 }, 300);

      return false;
    }
  });

  opdrachtBewerken.find('textarea').each(function(index, item) {
    if($(item).val() == '') {
      $(item).addClass('error');
      $(item).parent().find('.ql-editor').addClass('error');
      $('html, body').animate({ scrollTop: $(item).offset().top - 300 }, 300);

      return false;
    }
  });

  if(!opdrachtBewerken.find('input').hasClass('error') &&
     !opdrachtBewerken.find('textarea').hasClass('error') &&
     !opdrachtBewerken.find('.ql-editor').hasClass('error')) {
    $('.oracle-content-section').removeClass('open');
    matching.addClass('open');
    opdrachtBewerken.addClass('isComplete');

    $('html, body').animate({ scrollTop: matching.offset().top - 300 }, 10);
    saveProcessStep("step_2");
  }
});

// Save 'Matching' section
$(document).on('click', '.oracle-content-section-save.matching > .buttonIcon', function() {
  var matching = $('.oracle-content-section.matching');
  var geschiktePartners = $('.oracle-content-section.geschiktePartners');

  $("#assignment-potential-candidates-edit-form").submit();

  $('.oracle-content-section').removeClass('open');
  geschiktePartners.addClass('open');
  matching.addClass('isComplete');

  // Append selected partners to geschikt view
  $('.matchingPartnersContent > tr').each(function(index, item) {
    var randomID = Math.floor((Math.random() * 1000) + 1);
    var companyID = $(item).attr('id').split('_')[1];
    var partnerImageSrc = $(item).find('img').attr('src');
    var partnerName = $(item).find('.partnerName > p').text().trim();
    var services = $(item).find('.services').html().trim();
    var budgetVast = $(item).find('.partnerBudgetVast > p').text().trim();
    var budgetUur = $(item).find('.partnerBudgetUur > p').text().trim();
    var prioriteit = $(item).find('.prioriteit');
    prioriteit.find('input').remove();
    if(prioriteit.html().trim() == '') {
      prioriteit = '-'
    } else {
      prioriteit = prioriteit.html().trim();
    }

    if($(item).find('input[type="checkbox"]').prop('checked') == true) {
      $('tbody.geschiktePartnersContent').append('\
        <tr id="company_'+ companyID +'">\
          <td>\
            <div class="oracle-table-prio">\
              <ul>\
                <li class="prioOne">\
                  <button class="button button--xs button--outlined bg--red--hover noEmboss">prio 1</button>\
                </li>\
                <li class="prioSecond">\
                  <button class="button button--xs button--outlined bg--orange--hover noEmboss">prio 2</button>\
                </li>\
                <li class="prioThird">\
                  <button class="button button--xs button--outlined bg--yellow--hover noEmboss">prio 3</button>\
                </li>\
                <li class="prioFourth">\
                  <button class="button button--xs button--outlined bg--green--hover noEmboss">prio 4</button>\
                </li>\
                <li class="prioFifth">\
                  <button class="button button--xs button--outlined bg--blue--hover noEmboss">prio 5</button>\
                </li>\
                <li class="prioClose">\
                  <div class="uiSquareIcon uiSquareIcon--xs button button--outlined bg--red--hover noEmboss">\
                    <div class="global--icon global--icon--xxxs icon--kadett icon--white--hover">\
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 14 14" width="14" height="14">\
                        <path fill="#9B9B9B" fill-rule="evenodd" d="M9.849 7l3.561-3.561A2.014 2.014 0 1 0 10.561.59L7 4.151 3.439.59A2.014 2.014 0 1 0 .59 3.439L4.151 7 .59 10.561a2.014 2.014 0 1 0 2.849 2.849L7 9.849l3.561 3.561a2.014 2.014 0 1 0 2.849-2.849L9.849 7z"></path>\
                      </svg>\
                    </div>\
                  </div>\
                </li>\
              </ul>\
            </div>\
            <div class="oracle-table-checkbox-container">\
              <input id="matching-partner-geschikt'+ companyID +'" name="poule_companies[][company]" type="checkbox", value="'+ companyID +'">\
              <label for="matching-partner-geschikt'+ companyID +'">\
                <div class="oracle-table-checkbox-area">\
                  <div class="oracle-table-checkbox">\
                    <div class="global--icon global--icon--xxxxxs icon--white">\
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 44" width="8" height="6">\
                        <path fill="#9B9B9B" fill-rule="evenodd" d="M62.041 2.715C60.511.99 58.281 0 55.926 0a8.224 8.224 0 0 0-5.267 1.898L22.374 25.523l-8.608-8.297c-1.523-1.468-3.542-2.272-5.692-2.272-2.167 0-4.199.817-5.725 2.303C.832 18.741-.006 20.705 0 22.795c.006 2.09.851 4.051 2.38 5.522l13.911 13.404A8.146 8.146 0 0 0 21.981 44a8.227 8.227 0 0 0 5.273-1.901l33.942-28.352c1.636-1.367 2.624-3.262 2.781-5.346.16-2.084-.528-4.105-1.936-5.686"></path>\
                      </svg>\
                    </div>\
                  </div>\
                </div>\
              </label>\
              <div class="member member--s">\
                <img src="'+ partnerImageSrc +'" width="24" height="24">\
              </div>\
            </div>\
          </td>\
          <td class="partnerName">\
            <p class="fontWeight-Medium fontSize-15 color-obsidian">'+ partnerName +'</p>\
          </td>\
          <td>\
            <div class="uiSquareIcon uiSquareIcon--s button button--flat bg--white noPointerEvents">\
              <div class="global--icon global--icon--xxxs icon--satin">\
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 28" width="14" height="14">\
                  <path fill="#9B9B9B" fill-rule="evenodd" d="M15.994 28H12a.992.992 0 0 1-.999-.99v-4.02c0-.539-.452-.99-1.01-.99H8.01a.995.995 0 0 0-1.01.99v4.02a1 1 0 0 1-.999.99H2.006A2.006 2.006 0 0 1 0 26.005V8.03l.63-5.063C.835 1.326 2.347 0 4.01 0h9.98c1.673 0 3.177 1.332 3.382 2.975L18 7.989v18.016A2 2 0 0 1 15.994 28zM5 10.999v1.002c0 .556.447.999.999.999h1.002A.996.996 0 0 0 8 12.001v-1.002A.996.996 0 0 0 7.001 10H5.999a.996.996 0 0 0-.999.999zm0-5v1.002c0 .556.447.999.999.999h1.002A.996.996 0 0 0 8 7.001V5.999A.996.996 0 0 0 7.001 5H5.999A.996.996 0 0 0 5 5.999zm5 5v1.002c0 .556.447.999.999.999h1.002a.996.996 0 0 0 .999-.999v-1.002a.996.996 0 0 0-.999-.999h-1.002a.996.996 0 0 0-.999.999zm0-5v1.002c0 .556.447.999.999.999h1.002A.996.996 0 0 0 13 7.001V5.999A.996.996 0 0 0 12.001 5h-1.002a.996.996 0 0 0-.999.999zm-5 10v1.002c0 .556.447.999.999.999h1.002A.996.996 0 0 0 8 17.001v-1.002A.996.996 0 0 0 7.001 15H5.999a.996.996 0 0 0-.999.999zm5 0v1.002c0 .556.447.999.999.999h1.002a.996.996 0 0 0 .999-.999v-1.002a.996.996 0 0 0-.999-.999h-1.002a.996.996 0 0 0-.999.999z"></path>\
                </svg>\
              </div>\
            </div>\
          </td>\
          <td class="prioriteit">\
            '+ prioriteit +'\
          </td>\
          <td>\
            <p class="fontWeight-Medium fontSize-15 color-obsidian">-</p>\
          </td>\
          <td class="services">\
            '+ services +'\
          </td>\
          <td class="partnerBudgetVast">\
            <p class="fontWeight-Medium fontSize-15 color-obsidian">'+ budgetVast +'</p>\
          </td>\
          <td class="partnerBudgetUur">\
            <p class="fontWeight-Medium fontSize-15 color-obsidian">'+ budgetUur +'</p>\
          </td>\
        </tr>\
      ')
    }
  });

  $('html, body').animate({ scrollTop: geschiktePartners.offset().top - 300 }, 10);
  saveProcessStep("step_3");
});

// Save 'Geschikte Partners' section
$(document).on('click', '.oracle-content-section-save.geschiktePartners > .buttonIcon', function() {
  var geschiktePartners = $('.oracle-content-section.geschiktePartners');
  var poules = $('.oracle-content-section.poules');
  var pouleSelection = $('.oracle-content-section-save-poules');

  pouleSelection.addClass('open');

  // Append selected partners to geschikt view after poule selection
  if(pouleSelection.find('input:checked').length > 0) {
    $("#assignment-poule-companies-edit-form").submit();

    $('.oracle-content-section').removeClass('open');
    poules.addClass('open');
    geschiktePartners.addClass('isComplete');

    $('.geschiktePartnersContent > tr').each(function(index, item) {
      var randomID = Math.floor((Math.random() * 1000) + 1);
      var partnerImageSrc = $(item).find('img').attr('src');
      var partnerName = $(item).find('.partnerName > p').text().trim();
      var poule = pouleSelection.find('input:checked').val();

      if($(item).find('input[type="checkbox"]').prop('checked') == true) {
        $('tbody.poulesContent').append('\
          <tr>\
            <td>\
              <div class="oracle-table-checkbox-container">\
                <input id="matching-partner-poule'+ randomID +'" type="checkbox">\
                <label for="matching-partner-poule'+ randomID +'">\
                  <div class="oracle-table-checkbox">\
                    <div class="global--icon global--icon--xxxxxs icon--white">\
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 44" width="8" height="6">\
                        <path fill="#9B9B9B" fill-rule="evenodd" d="M62.041 2.715C60.511.99 58.281 0 55.926 0a8.224 8.224 0 0 0-5.267 1.898L22.374 25.523l-8.608-8.297c-1.523-1.468-3.542-2.272-5.692-2.272-2.167 0-4.199.817-5.725 2.303C.832 18.741-.006 20.705 0 22.795c.006 2.09.851 4.051 2.38 5.522l13.911 13.404A8.146 8.146 0 0 0 21.981 44a8.227 8.227 0 0 0 5.273-1.901l33.942-28.352c1.636-1.367 2.624-3.262 2.781-5.346.16-2.084-.528-4.105-1.936-5.686"></path>\
                      </svg>\
                    </div>\
                  </div>\
                </label>\
                <div class="member member--s">\
                  <img src="'+ partnerImageSrc +'" width="24" height="24">\
                </div>\
              </div>\
            </td>\
            <td>\
              <p class="fontWeight-Medium fontSize-15 color-obsidian">'+ partnerName +'</p>\
            </td>\
            <td>\
              <div class="uiSquareIcon uiSquareIcon--s button button--flat bg--white noPointerEvents">\
                <div class="global--icon global--icon--xxxs icon--satin">\
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 28" width="14" height="14">\
                    <path fill="#9B9B9B" fill-rule="evenodd" d="M15.994 28H12a.992.992 0 0 1-.999-.99v-4.02c0-.539-.452-.99-1.01-.99H8.01a.995.995 0 0 0-1.01.99v4.02a1 1 0 0 1-.999.99H2.006A2.006 2.006 0 0 1 0 26.005V8.03l.63-5.063C.835 1.326 2.347 0 4.01 0h9.98c1.673 0 3.177 1.332 3.382 2.975L18 7.989v18.016A2 2 0 0 1 15.994 28zM5 10.999v1.002c0 .556.447.999.999.999h1.002A.996.996 0 0 0 8 12.001v-1.002A.996.996 0 0 0 7.001 10H5.999a.996.996 0 0 0-.999.999zm0-5v1.002c0 .556.447.999.999.999h1.002A.996.996 0 0 0 8 7.001V5.999A.996.996 0 0 0 7.001 5H5.999A.996.996 0 0 0 5 5.999zm5 5v1.002c0 .556.447.999.999.999h1.002a.996.996 0 0 0 .999-.999v-1.002a.996.996 0 0 0-.999-.999h-1.002a.996.996 0 0 0-.999.999zm0-5v1.002c0 .556.447.999.999.999h1.002A.996.996 0 0 0 13 7.001V5.999A.996.996 0 0 0 12.001 5h-1.002a.996.996 0 0 0-.999.999zm-5 10v1.002c0 .556.447.999.999.999h1.002A.996.996 0 0 0 8 17.001v-1.002A.996.996 0 0 0 7.001 15H5.999a.996.996 0 0 0-.999.999zm5 0v1.002c0 .556.447.999.999.999h1.002a.996.996 0 0 0 .999-.999v-1.002a.996.996 0 0 0-.999-.999h-1.002a.996.996 0 0 0-.999.999z"></path>\
                  </svg>\
                </div>\
              </div>\
            </td>\
            <td class="partnerState">\
              <p class="fontWeight-Medium fontSize-15 color-obsidian">-</p>\
            </td>\
            <td>\
              <p class="fontWeight-Medium fontSize-15 color-obsidian">'+ poule +'</p>\
            </td>\
            <td>\
              <p class="fontWeight-Medium fontSize-15 color-obsidian">Nee</p>\
            </td>\
            <td>\
              <p class="fontWeight-Medium fontSize-15 color-obsidian">Nee</p>\
            </td>\
          </tr>\
        ');
      }
    });

    $('.oracle-content-section.poules:first-child').removeClass('hide');
    $('html, body').animate({ scrollTop: poules.offset().top - 300 }, 10);
    saveProcessStep("step_4");
  }
});

// Show Poule settings confirm button
$(document).on('click', '.oracle-content-section-filter-save.pouleSettings > .button', function(event) {
  event.preventDefault();
  var confirmView = $('.oracle-content-section-filter-confirm.pouleSettings');
  confirmView.show();
});

// Set Poule as live
$(document).on('click', '.oracle-content-section-filter-confirm.pouleSettings > .button', function(event) {
  event.preventDefault();
  var poule = $(this).parents(".oracle-content-section.poules");
  var pouleOption = poule.find('.oracle-content-section-filter-query');
  var pouleOptionText = pouleOption.find('input[type="text"]').val();
  var pouleLiveHead = poule.find('.oracle-content-section-head-poule-live');
  var confirmView = poule.find('.oracle-content-section-filter-confirm.pouleSettings');
  var opdrachtOmschrijving = $('.oracle-content-section.opdrachtOmschrijving');
  var opdrachtBewerken = $('.oracle-content-section.opdrachtBewerken');

  var form = poule.find('form[id*="assignment-poule-edit-form"]')

  if(pouleOptionText == 'Poule is live') {
    form.submit();

  } else if(pouleOptionText == 'Poule live zetten') {
    form.find('input[name="save_type"]').val("live")

    opdrachtOmschrijving.find('input[type="text"]:not(.is-disabled):not(.input-search)').each(function(index, item) {
      if($(item).val() == '') {
        opdrachtOmschrijving.addClass('open');
        $(item).addClass('error');
        $('html, body').animate({ scrollTop: $(item).offset().top - 300 }, 300);

        return false;
      }
    });

    opdrachtOmschrijving.find('textarea').each(function(index, item) {
      if($(item).val() == '') {
        opdrachtOmschrijving.addClass('open');
        $(item).addClass('error');
        $('html, body').animate({ scrollTop: $(item).offset().top - 300 }, 300);

        return false;
      }
    });

    if(!opdrachtOmschrijving.find('input').hasClass('error') &&
       !opdrachtOmschrijving.find('textarea').hasClass('error') &&
       !opdrachtOmschrijving.find('.ql-editor').hasClass('error')) {

      opdrachtBewerken.find('input[type="text"]:not(.is-disabled):not(.input-search)').each(function(index, item) {
        if($(item).val() == '') {
          opdrachtBewerken.addClass('open');
          $(item).addClass('error');

          $('html, body').animate({ scrollTop: $(item).offset().top - 300 }, 300);
          return false;
        }
      });

      opdrachtBewerken.find('textarea').each(function(index, item) {
        if($(item).val() == '') {
          opdrachtBewerken.addClass('open');
          $(item).addClass('error');
          $(item).parent().find('.ql-editor').addClass('error');

          $('html, body').animate({ scrollTop: $(item).offset().top - 300 }, 300);
          return false;
        }
      });

      if(!opdrachtBewerken.find('input').hasClass('error') &&
         !opdrachtBewerken.find('textarea').hasClass('error') &&
         !opdrachtBewerken.find('.ql-editor').hasClass('error')) {

        var pouleTimer = poule.find('.oracle-content-section-filter-timer');
        pouleTimer.find('input').each(function(index, item) {
          if($(item).val() == '') {
            $(item).addClass('error');
            return false;
          }
        });

        if(!pouleTimer.find('input').hasClass('error')) {
          pouleLiveHead.removeClass('hide');
          form.submit();

          var stateIcon = '\
            <div class="uiSquareIcon uiSquareIcon--s button button--flat bg--white noPointerEvents">\
              <div class="global--icon global--icon--xxxs icon--green">\
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 60" width="14" height="14">\
                  <path fill="#9B9B9B" fill-rule="evenodd" d="M32 60C14.327 60 0 47.673 0 30 0 12.327 14.327 0 32 0c17.673 0 32 12.327 32 30 0 17.673-14.327 30-32 30zm0-7c13.255 0 24-9.245 24-22.5S45.255 8 32 8 8 17.245 8 30.5 18.745 53 32 53zm0-11c-6.627 0-12-4.725-12-11.5S25.373 19 32 19s12 4.725 12 11.5S38.627 42 32 42z"></path>\
                </svg>\
              </div>\
            </div>\
          ';
        }
      }
    }

  } else if(pouleOptionText == 'Maak inactief') {
    form.find('input[name="save_type"]').val("close")
    pouleLiveHead.addClass('hide');

    var stateIcon = '\
      <div class="uiSquareIcon uiSquareIcon--s button button--flat bg--white noPointerEvents">\
        <div class="global--icon global--icon--xxxs icon--blue">\
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 60" width="14" height="14">\
            <path fill="#9B9B9B" fill-rule="evenodd" d="M32 60C14.327 60 0 47.673 0 30 0 12.327 14.327 0 32 0c17.673 0 32 12.327 32 30 0 17.673-14.327 30-32 30zm0-18c6.627 0 12-4.725 12-11.5S38.627 19 32 19s-12 4.725-12 11.5S25.373 42 32 42z"></path>\
          </svg>\
        </div>\
      </div>\
    ';

  } else if(pouleOptionText == 'Poule sluiten') {
    form.find('input[name="save_type"]').val("close")
    form.submit();
    pouleLiveHead.addClass('hide');
  }

  poule.find('.poulesContent > tr').each(function(index, item) {
    var partnerState = $(item).find('td.partnerState');
    partnerState.empty().append(stateIcon);
  });

  confirmView.hide();
});




/*-------------------------------------------------------------------------------------------
/-------> Batcave: Opdrachten (edit) - On Hold (modal)
-------------------------------------------------------------------------------------------*/

// Opening the On Hold modal
$(document).on('click', '.batcave-assignment-hold > .uiSquareIcon', function(event) {
  event.preventDefault();

  openModal('.oracle-assignmentOnHold');
});

// Closing the On Hold modal
$(document).on('click', '.oracle-assignmentOnHold .modal-close > .uiLoneIcon', function(event) {
  event.preventDefault();

  closeModal('.oracle-assignmentOnHold');
});

// Validating the password field
function validatePasswordField(passwordField, clickedButton) {
  if(passwordField.val() == '') {
    passwordField.addClass('error');
    passwordField.parent().find('.form-error > p').text('Vul je wachtwoord in')

  } else {
    $.when(checkCurrentUserPassword(passwordField.val())).then(function( pass ) {
      if(pass == true) {
        clickedButton.addClass('isLoading');

        setTimeout(function() {
          // $('#on-hold-assignment-form').submit();
          modalStepFromTo('.oracle-assignmentOnHold', true, false, 'initial', 'second');
        }, 1000);

        setTimeout(function() { clickedButton.removeClass('isLoading'); }, 1200);

      } else {
        passwordField.addClass('error');
        passwordField.parent().find('.form-error p').text('Geen geldig wachtwoord');
      }
    });
  }
}

// Submitting the On Hold modal on Click
$(document).on('click', '.oracle-assignmentOnHold-button > .button', function(event) {
  event.preventDefault();

  var clickedButton = $(this).find('.buttonIcon');
  var passwordField = $('.oracle-assignmentOnHold-container input');

  validatePasswordField(passwordField, clickedButton);
});

// Submitting the On Hold modal on ENTER
$(document).on('keydown', '.oracle-assignmentOnHold-container .inputIcon > input', function(event) {
  var clickedButton = $('.oracle-assignmentOnHold-button > .button');
  var passwordField = $(this);

  if(event.keyCode == 13) {
    event.preventDefault();

    validatePasswordField(passwordField, clickedButton);
  }
});




/*-------------------------------------------------------------------------------------------
/-------> Batcave: Opdrachten (edit) - Assignee
-------------------------------------------------------------------------------------------*/

// Selecing an assignee
$(document).on('click', '.batcave-assignment-heading > .batcave-assignment-user ul > li > label', function() {
  var assignmentUser = $('.batcave-assignment-user');
  var assigneeButton = $('.batcave-assignment-user-button');

  var listItem = $(this).parent();
  var listItemSplitted = listItem.attr("id").split("_")
  var assigneeImage = listItem.find('.member');

  if(assigneeImage.hasClass('memberPending')) {
    assigneeMember =
      '<div class="member member--s memberPending">\
        <p class="fontWeight-Bold fontSize-10 color-white">\
          '+ assigneeImage.find('p').text().trim() +'\
        </p>\
      </div>';
  } else {
    assigneeMember =
      '<div class="member member--s">\
        <img src="'+ assigneeImage.find('img').attr('src') +'"/>\
      </div>';
  }

  var assigneeName = listItem.find('p.color-kadett').text().trim().split(' ')[0];

  var assignment = $("#assignment_id").val();
  var moderator = listItemSplitted[listItemSplitted.length - 1]
  $.when(
    $.ajax({
      type: "PUT",
      url: "/batcave/opdrachten/assign_moderator",
      data: {id: assignment, moderator: moderator},
      dataType: "json",
    })
  ).then(function(data) {
    if ($.isEmptyObject(data)) {
      assigneeButton.find('> p').text(assigneeName);
      assigneeButton.find('.member').remove();

      $(assigneeMember).insertBefore(assigneeButton.find('p'));

      assignmentUser.find('.popup-compact').removeClass('open');
      assignmentUser.find('.openPopupCompact').removeClass('active');
    }else{
      console.log(data);
    }
  });
});





/*-------------------------------------------------------------------------------------------
/-------> Batcave: Opdrachten (edit) - Voorstellen
-------------------------------------------------------------------------------------------*/

// Save voorstellen section
$(document).on('click', '.saveVoorstellenSection .button', function(event) {
  event.preventDefault();
  $("#proposals-form").find("#save_type").val("reject")
  $("#proposals-form").submit()
});

// Send voorstellen section
$(document).on('click', '.sendVoorstellenSection .button', function(event) {
  event.preventDefault();
  $("#proposals-form").find("#save_type").val("send")
  $("#proposals-form").submit()
});

// save proposal cap
$(document).on('click', '.saveProposalCap .button', function(event) {
  event.preventDefault();
  $("#proposals-form").find("#save_type").val("proposal_cap")
  $("#proposals-form").submit()
});

// Save proposal deadlines
$(document).on('click', '.saveProposalDeadlines .button', function(event) {
  event.preventDefault();
  $("#proposal-deadline-form").submit()
});


/*-------------------------------------------------------------------------------------------
/-------> Batcave: Opdrachten (edit) - Matching process
-------------------------------------------------------------------------------------------*/
function saveProcessStep(step){
  $.ajax({
    url: "/batcave/opdrachten/complete_step",
    type: 'PUT',
    dataType: 'json',
    data: {id: $("#assignment_id").val(), step: step}
  })
  .done(function(data) {
    console.log(data);
    return data;
  })
  .fail(function(error) {
    console.log(error);
    return error;
  })
  .always(function() {
    console.log("complete");
  });
}





// Checking percentage box
$(document).on('click', '.batcave-assignment-section.isCheckbox label', function() {
  var checkbox = $(this);
  setTimeout(function() {
    if(checkbox.parent().find('input').prop('checked') == true) {
      $("#hidePercentage").val(true)
      $('.batcave-assignment-card-preview > ul.points > li:nth-child(2)').show();
      $('.batcave-assignment-card-preview > ul.points > li:nth-child(3)').show();
    } else {
      $("#hidePercentage").val(false)
      $('.batcave-assignment-card-preview > ul.points > li:nth-child(2)').hide();
      $('.batcave-assignment-card-preview > ul.points > li:nth-child(3)').hide();
    }
  }, 1);
});




// Searching in Matching
$(document).on('keyup', '#matchingSearchInputField', function() {
  var value = $(this).val();
  var content = $('.matchingPartnersContent');
  var list = content;
  var highlight = list.find('.partnerName p');
  var noResults = content.find('.cases-editor-information-services-noResults');
  var empty = content.find('.cases-editor-information-services-empty');
  var ignore = 'hide';

  // Add listitem to be ignored to search
  if(ignore != '') { var ignoreClass = ':not(.'+ ignore +')';
  } else { ignoreClass = ''; }

  // Show/Hide items based on value provided
  if(value == '') {
    list.find('> tr' + ignoreClass + ':contains("' + value + '")').show();
    noResults.hide()

    if(list.find('> tr' + ignoreClass).length == 0) { empty.show(); }

  } else {
    value = value.split(";");
    list.find('> tr' + ignoreClass).hide();

    $.each(value, function(i){
      list.find('> tr' + ignoreClass + ':contains("' + value[i] + '")').show();

      if(list.find('> tr' + ignoreClass + ':contains("' + value[i] + '")').length != 0) {
        noResults.hide();
        empty.hide();
        noResults.find('> p:last-child').text('');

      } else {
        noResults.show();
        empty.hide();
        noResults.find('> p:last-child').text("'" + value + "'");
      }
    });
  }

  // Highlight the text when it matches the value provided by the user
  highlight.unhighlight();
  highlight.highlight(value);

});


// Searching in Matching
$(document).on('click', '.cancelButton', function(event) {
  event.preventDefault();
  location.reload();
});
