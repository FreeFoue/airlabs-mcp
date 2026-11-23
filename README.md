# AirLabs MCP Server

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This [Model Context Protocol (MCP)](https://modelcontextprotocol.io) server provides access to the [AirLabs](https://airlabs.co) aviation data API. It lets AI assistants such as Claude Desktop and Cursor access real-time flight data, airport schedules, delays, and reference databases for airlines, airports, aircraft fleets and routes — directly through natural-language questions.

The entire server lives in a single file (`index.ts`): tool definitions, the AirLabs HTTP client, request handling and the stdio transport.

## Features

- **Live flight status** — look up any flight by number and get status, gate, terminal and delay.
- **Airport schedules** — departures and arrivals boards for any airport.
- **Delay monitoring** — find flights delayed beyond a threshold at an airport or airline.
- **Real-time positions** — live aircraft coordinates, altitude, speed and heading by area, airline or registration.
- **Nearest airport** — closest airports to any coordinate.
- **Reference databases** — airlines, airports, aircraft fleets (by tail number or ICAO24 hex) and route networks.
- **Code resolution** — turn a place or airline name into its IATA/ICAO code.

## Prerequisites

1. **Node.js** 18.0.0 or higher.
2. **AirLabs API key** — get a free key at <https://airlabs.co/signup>.

## Remote MCP deployment (Docker Compose)

The HTTP transport is intended to run behind an HTTPS reverse proxy. It keeps the
stdio transport as the default for local MCP clients. Docker Compose binds the
server to `127.0.0.1:8003`; the existing Nginx instance provides HTTPS and routes
`/airlabs/mcp` to the container's `/mcp` endpoint. The endpoint requires
`MCP_BEARER_TOKEN` in `Authorization: Bearer …`.

1. Point the domain's DNS A record to the VPS and allow inbound TCP ports 80 and 443.
2. Install Docker Engine and the Docker Compose plugin on Ubuntu, then clone this repository.
3. Create `.env` from `.env.example`; set `AIRLABS_API_KEY` and a unique
   `MCP_BEARER_TOKEN` of at least 32 characters. Keep `.env` private and out of Git.
4. Add this location to the existing TLS server block in Nginx:

   ```nginx
   location = /airlabs/mcp {
       proxy_pass http://127.0.0.1:8003/mcp;
       proxy_http_version 1.1;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto https;
       proxy_set_header Authorization $http_authorization;
       proxy_set_header Connection "";
       proxy_buffering off;
       proxy_cache off;
       proxy_read_timeout 3600s;
   }

   location = /airlabs/health {
       proxy_pass http://127.0.0.1:8003/health;
   }
   ```

5. Start the service:

   ```bash
   docker compose up -d --build
   docker compose logs -f
   ```

6. Configure Sandra with `https://YOUR_DOMAIN/airlabs/mcp` and the matching Bearer token.
   `https://YOUR_DOMAIN/airlabs/health` provides a basic liveness check.

To update later, run `git pull` followed by `docker compose up -d --build`.

## Installation

### Via npm

```bash
npm install -g @airlabs-co/airlabs-mcp
```

## Configuration

### Claude Desktop Integration

Add this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "airlabs": {
      "command": "npx",
      "args": ["@airlabs-co/airlabs-mcp@latest"],
      "env": {
        "AIRLABS_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

**Notes:**

- Replace `your_api_key_here` with your actual AirLabs API key.
- Restart Claude Desktop after editing the config.
- If you build from source locally, use `"command": "node", "args": ["/path/to/build/index.js"]`.

### Other MCP Clients

Run the server directly over stdio:

```bash
AIRLABS_API_KEY=your_api_key_here npx @airlabs/airlabs-mcp
```

## Available Tools

| Tool | AirLabs endpoint | Purpose |
| --- | --- | --- |
| `get_flight_status` | `/flight` | Live status of one flight by IATA/ICAO number |
| `get_airport_schedule` | `/schedules` | Departures / arrivals board for an airport |
| `monitor_delays` | `/delays` | Flights delayed beyond a threshold |
| `track_live_flights` | `/flights` | Live aircraft positions by area, airline or registration |
| `find_nearest_airport` | `/nearby` | Closest airports to a coordinate |
| `search_airport_code` | `/suggest` | Resolve a name to an IATA/ICAO code |
| `get_airline_info` | `/airlines` | Airline details by code |
| `get_airport_info` | `/airports` | Airport details by code |
| `lookup_aircraft` | `/fleets` | Aircraft by registration or ICAO24 hex |
| `find_routes` | `/routes` | Which airlines fly a given route |

All tools accept an optional `_fields` parameter (where the endpoint supports it) to return only selected fields and keep responses compact.

## Usage Examples

Once configured, just ask your assistant:

- *"Is flight BA117 on time?"* → `get_flight_status`
- *"What flights are leaving JFK today?"* → `get_airport_schedule`
- *"Are arrivals delayed at LAX by more than 30 minutes?"* → `monitor_delays`
- *"Show me planes flying over New York."* → `track_live_flights`
- *"What aircraft is registration N790AN?"* → `lookup_aircraft`
- *"Which airlines fly from London to Tokyo?"* → `find_routes`

## Development

### Building from source

```bash
git clone https://github.com/airlabs-co/airlabs-mcp.git
cd airlabs-mcp
npm install
npm run build
```

### Contributing

1. Fork the repository.
2. Create a feature branch.
3. Make your changes.
4. Submit a pull request.

## Support

- **Documentation**: <https://airlabs.co/docs>
- **Issues**: [GitHub Issues](https://github.com/airlabs-co/airlabs-mcp/issues)
- **API support**: <https://airlabs.co/faq#Contact>

## License

MIT License — see [LICENSE](LICENSE).
