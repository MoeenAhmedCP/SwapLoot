class ApiError < StandardError
  def initialize(message:, backtrace: [])
    super(message)
    set_backtrace(backtrace)
  end
end
