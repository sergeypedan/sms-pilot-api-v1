# frozen_string_literal: true

module SmsPilot

  class InvalidAPIkeyError     < ArgumentError; end
  class InvalidLocaleError     < ArgumentError; end
  class InvalidMessageError    < ArgumentError; end
  class InvalidPhoneError      < ArgumentError; end
  class InvalidSenderNameError < ArgumentError; end

end
