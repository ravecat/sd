#!/bin/sh
set -e

# Generate runtime config from container env
cat > /usr/share/nginx/html/env-config.js << EOF
window.__ENV__ = {
  API_URL: "${API_URL:-/api}"
};
EOF

exec "$@"
