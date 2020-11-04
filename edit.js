/*--
This file contains all the functions for
the Instellingen section in the Batcave.
--*/


/*-------------------------------------------------------------------------------------------
/-------> Accountinstellingen: Personal Information
-------------------------------------------------------------------------------------------*/

// Show form buttons for 'Personal' when focusing in on input
$(document).on('focusin', '.oracle-content-section-personal input:not([type=file])', function() {
  $('.batcave-settings-form-buttons.persoonlijkeInformatie').show(350);
});

// Show form buttons for 'Personal' when focusing in on textarea
$(document).on('focusin', '.oracle-content-section-personal textarea', function() {
  $('.batcave-settings-form-buttons.persoonlijkeInformatie').show(350);
});

// Submitting the profile form
$(document).on('click', '.persoonlijkeInformatie-button > .button', function(event){
  event.preventDefault();

  // Variables for validations and animations
  var clickedButton = $(this);
  var nameField = $('.oracle-content-section-input.fullName input');
  var nameFieldSplit = nameField.val().trim().split(' ');
  var profilePhone = $('.oracle-content-section-input.phone input');
  var profileBirth = $('.oracle-content-section-input.birth input');

  var birth = profileBirth.val().split(' - ')
  var day = birth[0];
  var month = birth[1];
  var year = birth[2];

  var selectedTime = new Date();
  selectedTime.setFullYear(year, month - 1, day);
  var currentTime = new Date();
  var currentYear = currentTime.getFullYear();

  if(nameField.val() == '') {
    nameField.addClass('error');
    nameField.parent().find('.form-error > p').text('Naam is verplicht');

  } else if(nameFieldSplit.length < 2 || nameFieldSplit[1].length < 2) {
    nameField.addClass('error');
    nameField.parent().find('.form-error > p').text('Vul je volledige naam in');

  } else if(profileBirth.val() != '' && day == '0' || day == "00" || month == "0" || month == '00' || year == "0" || year == "00" || year == "000" || year == "0000") {
    profileBirth.addClass('error');
    profileBirth.parent().find('.form-error > p').text('Voer een geldig datum in');

  } else if(profileBirth.val() != '' && day > 31) {
    profileBirth.addClass('error');
    profileBirth.parent().find('.form-error > p').text('Voer een geldig dag in');

  } else if(profileBirth.val() != '' && month > 12) {
    profileBirth.addClass('error');
    profileBirth.parent().find('.form-error > p').text('Voer een geldig maand in');

  } else if(profileBirth.val() != '' && year > currentYear) {
    profileBirth.addClass('error');
    profileBirth.parent().find('.form-error > p').text('Voer een geldig jaar in');

  } else if(profileBirth.val() != '' && selectedTime > currentTime) {
    profileBirth.addClass('error');
    profileBirth.parent().find('.form-error > p').text('Voer een geldig datum in');

  } else if(profilePhone.val() == '') {
    profilePhone.addClass('error');

  } else {
    $('#batcave-user-personal-form').submit();

    clickedButton.addClass("isLoading");

    // Retrieve the values entered by the user
    var name = $('.oracle-content-section-input.fullName input').val();
    var gender = $('.oracle-content-section-input.gender input').val();
    var birth = $('.oracle-content-section-input.birth input').val();
    var phone = $('.oracle-content-section-input.phone input').val();

    // Set original values, so that on the next cancel the right changes
    $('.oracle-content-section-input.fullName').find('.batcave-settings-original').text(name);
    $('.oracle-content-section-input.gender').find('.batcave-settings-original').text(gender);
    $('.oracle-content-section-input.birth').find('.batcave-settings-original').text(birth);
    $('.oracle-content-section-input.phone').find('.batcave-settings-original').text(phone);
  }
});

// Cancelling the profile changes
$(document).on('click', '.persoonlijkeInformatie-cancel > .button', function(event) {
  event.preventDefault();

  // Variables for original values
  var originalName = $('.oracle-content-section-input.fullName').find('.batcave-settings-original').text().trim();
  var originalGender = $('.oracle-content-section-input.gender').find('.batcave-settings-original').text().trim();
  var originalBirth = $('.oracle-content-section-input.birth').find('.batcave-settings-original').text().trim();
  var originalPhone = $('.oracle-content-section-input.phone').find('.batcave-settings-original').text().trim();
  var originalRole = $('.oracle-content-section-input.role').find('.batcave-settings-original').text().trim();
  var originalDescription = $('.oracle-content-section-input.description').find('.batcave-settings-original').text().trim();
  var originalImageInput = $('.oracle-content-section-photo').find('input[type="file"]')
  var imageDelete = $('#member-edit-deleted');

  // Variables for input fields
  var name = $('.oracle-content-section-input.fullName input');
  var gender = $('.oracle-content-section-input.gender input');
  var birth = $('.oracle-content-section-input.birth input');
  var phone = $('.oracle-content-section-input.phone input');
  var role = $('.oracle-content-section-input.role input');
  var description = $('.oracle-content-section-input.description textarea');
  var imageContainer = $('.oracle-content-section-photo .member--edit');

  // Check if image of user exists
  var defaultMember = $('.member--edit-history').find('.member');
  if(defaultMember.hasClass('memberPending')) {
    var defaultMemberInitials = defaultMember.find('p').text().trim();

    imageContainer.removeClass('imageAdded');
    imageContainer.find('> .member').addClass('memberPending')
                                    .empty()
                                    .append('\
                                      <p class="fontWeight-Bold fontSize-24 color-white">\
                                        '+ defaultMemberInitials +'\
                                      </p>\
                                    ')
  } else {
    imageContainer.find('> .member').removeClass('memberPending')
                                    .empty()
                                    .append('<img src="" width="126" height="126">');

    imageContainer.addClass('imageAdded');

    var defaultMemberImgSrc = defaultMember.find('img').attr('src');
    imageContainer.find('> .member img').attr('src', defaultMemberImgSrc);
  }

  // Set fields back to original
  originalImageInput.val('');
  name.val(originalName);
  gender.val(originalGender);
  birth.val(originalBirth);
  phone.val(originalPhone);
  role.val(originalRole);
  description.val(originalDescription);
  imageDelete.val(false);

  // Hide the buttons
  $('.batcave-settings-form-buttons.persoonlijkeInformatie').hide(350);
});




/*-------------------------------------------------------------------------------------------
/-------> Accountinstellingen: Email
-------------------------------------------------------------------------------------------*/

// Opening the change E-mail field
$(document).on('click', '.batcave-settings-account-email > .button', function(event) {
  event.preventDefault();

  // Showing the change email fields
  $('.batcave-settings-account-normal').hide();
  $('.batcave-settings-account-opened').show();

  // Focusin on password inputfield
  setTimeout(function() {
    $('.batcave-settings-account-opened .password input').putCursorAtEnd();
  }, 1)
});

// Canceling the change E-mail field
$(document).on('click', '.batcave-settings-form-button-cancel.changeEmail > .button', function(event) {
  event.preventDefault();

  // Hiding the change email fields
  $('.batcave-settings-account-normal').show();
  $('.batcave-settings-account-opened').hide();

  // Emptying the password field
  $('.batcave-settings-account-opened .password input').val('');

  // Set previous email value
  var currentUserEmail = $('.batcave-settings-account-normal input').val();
  $('.batcave-settings-account-opened .email input').val(currentUserEmail);
});

// Saving the email change in the users account
$(document).on('click', '.batcave-settings-saveEmail > .button', function(event) {
  event.stopPropagation();
  event.preventDefault();

  var clickedButton = $(this);
  var passwordField = $('.batcave-settings-account-opened .password input');
  var emailField = $('.batcave-settings-account-opened .email input');

  // Validation for email change fields
  if(passwordField.val() == '') {
    passwordField.addClass('error');
    passwordField.parent().find('.form-error > p').text('Vul je wachtwoord in')

  } else if(emailField.val() == '') {
    emailField.addClass('error');
    emailField.parent().find('.form-error > p').text('Email is verplicht')

  } else if(!isValidEmailAddress( emailField.val())) {
    emailField.addClass('error');
    emailField.parent().find('.form-error > p').text('Voer een geldig e-mail in')

  } else {

    // Loading animation of button
    clickedButton.addClass('isLoading');

    // Submitting the form
    $('#batcave-user-email-form').submit();
  }
});

// Confirming that the email has been received in the modal
$(document).on('click', '.batcave-settings-emailConfirmation .button', function(event) {
  event.preventDefault();
  event.stopPropagation();

  // Running the close email modal
  closeModal('.batcave-settings-emailConfirmation');
});




/*-------------------------------------------------------------------------------------------
/-------> Accountinstellingen: Wachtwoord
-------------------------------------------------------------------------------------------*/

// Opening the change Password fields
$(document).on('click', '.batcave-settings-account-password-normal > .button', function(event) {
  event.preventDefault();

  // Showing the change password fields
  $('.batcave-settings-account-password-normal').hide();
  $('.batcave-settings-account-password-opened').show();

  // Focusin on password inputfield
  setTimeout(function() {
    $('.batcave-settings-account-password-old input').putCursorAtEnd();
  }, 1)
})

// Canceling the change Password fields
$(document).on('click', '.batcave-settings-form-button-cancel.wachtwoord > .button', function(event) {
  event.preventDefault();

  // Hiding the change password fields
  $('.batcave-settings-account-password-normal').show();
  $('.batcave-settings-account-password-opened').hide();

  // Resetting the password fields
  $('.batcave-settings-account-password-opened input').val('');
  $('.batcave-settings-account-password-opened input').removeClass('error');
  $('.batcave-settings-account-password-new > ul > li').removeClass('isChecked');
});

// Validating password field
function passwordValidationInSettings() {
  var oldPassword = $('.batcave-settings-account-password-old input');
  var newPassword = $('.batcave-settings-account-password-new input');
  var repeatPassword = $('.batcave-settings-account-password-repeat input');
  var repeatPasswordVal = $('.batcave-settings-account-password-repeat input').val();
  var newPasswordVal = newPassword.val();

  // Validation on the password fields
  if(oldPassword.val() == '') {
    oldPassword.addClass('error');
    oldPassword.parent().find('.form-error > p').text('Vul je oude wachtwoord in')

  } else if(newPasswordVal.length < 8) {
    newPassword.addClass('error');
    newPassword.parent().find('.form-error > p').text('Wachtwoord te kort')

  } else if(newPasswordVal.length > 72) {
    newPassword.addClass('error');
    newPassword.parent().find('.form-error > p').text('Wachtwoord te lang')

  } else if(newPasswordVal != repeatPasswordVal) {
    repeatPassword.addClass('error');
    repeatPassword.parent().find('.form-error > p').text('Wachtwoord komt niet overeen');

  } else if(oldPassword.val() == newPasswordVal) {
    newPassword.addClass('error');
    newPassword.parent().find('.form-error > p').text('Oeps, dit wachtwoord is hetzelfde als je huidige. Probeer een andere.');

  } else {
    $('.batcave-settings-form-button-save.wachtwoord > .button').addClass('isLoading');

    setTimeout(function() {
      $('#batcave-user-password-form').submit();
    }, 700)
  }
}

// Submitting the form on CLick
$(document).on('click', '.batcave-settings-form-button-save.wachtwoord > .button', function(event) {
  event.preventDefault();

  passwordValidationInSettings();
});

// Submitting the form on ENTER
$(document).on('keydown', '.batcave-settings-account-password-repeat input',function(event) {
  if(event.keyCode == 13) {
    event.preventDefault();

    passwordValidationInSettings();
  }
});




/*-------------------------------------------------------------------------------------------
/-------> Accountinstellingen: Gebruikersnaam
-------------------------------------------------------------------------------------------*/

// Opening the edit tag view
$(document).on('click', '.batcave-settings-form-tag-edit > .button', function(event) {
  event.preventDefault();

  // Enabling the user tag input
  $('.oracle-content-section-tag').removeClass("disabled");

  // Focusing on the tag input field
  setTimeout(function() {
    $('.oracle-content-section-tag input').putCursorAtEnd();
  }, 1)

  // Hiding the edit tag button
  $('.batcave-settings-form-tag-edit').hide(0);
  $('.batcave-settings-form-buttons.tagButtons').show(0);
});

// Saving the user tag change
$(document).on('click', '.batcave-settings-form-button-save.tagButton > .button', function(event){
  event.preventDefault();

  // Variables
  var clickedButton = $(this);
  var tag = $('.oracle-content-section-tag input');
  var firstChar = tag.val().charAt(0);

  // Validation
  if(tag.val() == '') {
    tag.addClass('error');
    tag.parent().find('.form-error > p').text('Tag is verplicht');
    $('.batcave-settings-form-buttons.tagButtons').css('margin-top', '37px');

  } else if(tag.val().length < 2) {
    tag.addClass('error');
    tag.parent().find('.form-error > p').text('Minimaal 2 karakters');
    $('.batcave-settings-form-buttons.tagButtons').css('margin-top', '37px');

  } else if(tag.val().length > 30) {
    tag.addClass('error');
    tag.parent().find('.form-error > p').text('Maximaal 30 karakters');
    $('.batcave-settings-form-buttons.tagButtons').css('margin-top', '37px');

  } else if(firstChar <= '9' && firstChar >= '0') {
    tag.addClass('error');
    tag.parent().find('.form-error > p').text('Mag niet met een cijfer beginnen');
    $('.batcave-settings-form-buttons.tagButtons').css('margin-top', '37px');

  } else {

    $('#batcave-user-tag-form').submit();

    clickedButton.addClass("isLoading");
  }
});

// Cancelling the edit tag view
$(document).on('click', '.batcave-settings-form-button-cancel.tagButton > .button', function(event) {
  event.preventDefault();

  // Variables for original values
  var originalTag = $('.oracle-content-section-tag').find('.batcave-settings-original').text().trim();

  // Variables for input fields
  var tag = $('.oracle-content-section-tag input');

  // Set fields back to original
  tag.val(originalTag);

  // Hide the buttons
  $('.batcave-settings-form-buttons.tagButtons').hide(0);
  $('.oracle-content-section-tag').addClass("disabled");
  $('.batcave-settings-form-tag-edit').show(0);
});




/*-------------------------------------------------------------------------------------------
/-------> Accountinstellingen: Create account
-------------------------------------------------------------------------------------------*/
$(document).on('click', '.createAccount-button > .button', function(event) {
  event.preventDefault();

  // Variables for validations and animations
  var clickedButton = $(this);
  var emailField = $('.oracle-content-section-input.email input');
  var passwordField = $('.oracle-content-section-input.password input');
  var nameField = $('.oracle-content-section-input.fullName input');
  var nameFieldSplit = nameField.val().trim().split(' ');
  var profilePhone = $('.oracle-content-section-input.phone input');
  var profileBirth = $('.oracle-content-section-input.birth input');
  var profileRole = $('.oracle-content-section-input.role input');
  var profileDescription = $('.oracle-content-section-input.description textarea');
  var profileTag = $('.oracle-content-section-input.tag input');

  var birth = profileBirth.val().split(' - ')
  var day = birth[0];
  var month = birth[1];
  var year = birth[2];

  var selectedTime = new Date();
  selectedTime.setFullYear(year, month - 1, day);
  var currentTime = new Date();
  var currentYear = currentTime.getFullYear();

  if(emailField.val() == '') {
    emailField.addClass('error');
    emailField.parent().find('.form-error > p').text('Email is verplicht')

  } else if(!isValidEmailAddress( emailField.val())) {
    emailField.addClass('error');
    emailField.parent().find('.form-error > p').text('Voer een geldig e-mail in')

  } else if(passwordField.val() == '') {
    passwordField.addClass('error');

  } else if(nameField.val() == '') {
    nameField.addClass('error');
    nameField.parent().find('.form-error > p').text('Naam is verplicht');

  } else if(nameFieldSplit.length < 2 || nameFieldSplit[1].length < 2) {
    nameField.addClass('error');
    nameField.parent().find('.form-error > p').text('Vul je volledige naam in');

  } else if(profileBirth.val() != '' && day == '0' || day == "00" || month == "0" || month == '00' || year == "0" || year == "00" || year == "000" || year == "0000") {
    profileBirth.addClass('error');
    profileBirth.parent().find('.form-error > p').text('Voer een geldig datum in');

  } else if(profileBirth.val() != '' && day > 31) {
    profileBirth.addClass('error');
    profileBirth.parent().find('.form-error > p').text('Voer een geldig dag in');

  } else if(profileBirth.val() != '' && month > 12) {
    profileBirth.addClass('error');
    profileBirth.parent().find('.form-error > p').text('Voer een geldig maand in');

  } else if(profileBirth.val() != '' && year > currentYear) {
    profileBirth.addClass('error');
    profileBirth.parent().find('.form-error > p').text('Voer een geldig jaar in');

  } else if(profileBirth.val() != '' && selectedTime > currentTime) {
    profileBirth.addClass('error');
    profileBirth.parent().find('.form-error > p').text('Voer een geldig datum in');

  } else if(profilePhone.val() == '') {
    profilePhone.addClass('error');

  } else if(profileRole.val() == '') {
    profileRole.addClass('error');

  } else if(profileDescription.val() == '') {
    profileDescription.addClass('error');

  } else if(profileTag.val() == '') {
    profileTag.addClass('error');

  } else {
    $('#batcave-create-account-form').submit();

    clickedButton.addClass("isLoading");
  }
});
