#!/bin/bash
echo "Stopping any old frontend servers..."
pkill -f "node server.js" || true
echo "Starting Frontend Server on port 5000..."
nohup node /home/saleel/botmarket/frontend/server.js > /home/saleel/botmarket/frontend/frontend.log 2>&1 &
sleep 3
if lsof -i :5000 > /dev/null; then
    echo "✅ SUCCESS: Frontend is LIVE at http://192.168.1.111:5000"
else
    echo "❌ ERROR: Frontend failed to start. Check /home/saleel/botmarket/frontend/frontend.log"
fi
