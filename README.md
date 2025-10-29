# Takagi CoAP Interoperability Tests

Test suite to verify Takagi works with different CoAP clients (libcoap, aiocoap, node-coap). Why? 
The new implementation of CoAP should be able to communicate with others, right? So what not to use them?

---

## Quick Start

**Docker (easiest):**
```bash
docker-compose run --rm tests
```

**Manual:**
```bash
bundle install
sudo apt-get install libcoap2-bin
bundle exec rspec
```

---

## Write Your First Test

Create `spec/rfc7252_core/my_test.rb`:

```ruby
require 'spec_helper'

RSpec.describe "My Test" do
  CoAPClients.each do |client_name, client|
    context "using #{client_name}" do
      it "gets temperature" do
        response = client.get('/temperature')
        expect(response.code).to eq('2.05')
      end
    end
  end
end
```

Run it: `bundle exec rspec spec/rfc7252_core/my_test.rb`

---

## Add Test Endpoint

Edit `takagi_app/server.rb`:

```ruby
class InteropTestServer < Takagi::Base
  get '/my-endpoint' do
    json my_data: 'hello'
  end
end
```

---

## Project Structure

```
.
├── spec/
│   ├── rfc7252_core/      # Your tests go here
│   └── support/
│       └── coap_clients.rb
├── takagi_app/
│   └── server.rb          # Test endpoints
└── Dockerfile
```

---

## Common Commands

```bash
bundle exec rspec                              # All tests
bundle exec rspec spec/rfc7252_core/my_test.rb # One file
COAP_CLIENTS=libcoap bundle exec rspec         # Specific client
VERBOSE=1 bundle exec rspec                    # Debug mode

# Docker
docker-compose run --rm tests  # Run tests
docker-compose run --rm dev    # Shell
```

---

## Test Manually

```bash
# Terminal 1: Start server
ruby takagi_app/server.rb

# Terminal 2: Test it
coap-client -m get coap://localhost:5683/temperature
```

---

## Response Object

```ruby
response.code      # "2.05", "4.04"
response.payload   # Response body
response.json      # Parsed JSON
response.success?  # true if 2.xx
```

## Troubleshooting

```bash
# Port in use?
COAP_PORT=5684 bundle exec rspec

# Client not found?
sudo apt-get install libcoap2-bin

# See what's happening
VERBOSE=1 bundle exec rspec
```

---

That's it! Start writing tests. 🚀