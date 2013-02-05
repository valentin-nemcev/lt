shared_context :api_helpers do
  let(:session) { ActionDispatch::Integration::Session.new(Rails.application) }
  def request(method, uri, data = {})
    unless method.in? [:get, :post, :put, :delete]
      raise ArgumentError, "Invalid method #{method}"
    end
    data = data.as_json
    params = data.merge :format => :json
    session.public_send method, uri, params
    session.response
  end
end

module ResponseHelpers
  def json_body(response_field = nil)
    body.present? or fail 'response body is empty'
    resp = JSON.parse body
    resp = resp.fetch(response_field) if response_field
    JSONStruct.new resp
  end

  def successful?
    super or fail "Request was not successful: \n" \
                  "#{code}: #{status_message}\n" \
                  "#{body}"
  end
end

class ActionDispatch::TestResponse
  include ResponseHelpers
end

class JSONStruct < OpenStruct
  def as_json
    marshal_dump
  end

  def matches?(fields)
    fields.all? do |name, value|
      self.send(name.to_sym) == value
    end
  end
end

class Hash
  def to_struct
    JSONStruct.new self
  end
end

class Array
  def find_struct(fields)
    structs = map(&:to_struct)
    matches = structs.find_all{ |s| s.matches? fields }
    l = matches.size
    l == 1 or fail "Found #{l == 0 ? 'no' : l} #{'struct'.pluralize(l)}" \
                   " matching #{fields}" \
                   " Existing #{'struct'.pluralize(structs.size)} were: \n" +
                   structs.map(&:inspect).join("\n")
    matches.last
  end
end

