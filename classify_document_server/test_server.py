#!/usr/bin/env python3
"""
Minimal test to verify Flask app can start
Run this locally to test if the app can at least start
"""
import sys
import os

print("Testing Flask app import...")
try:
    from app import app
    print("✅ Flask app imported successfully")
    print(f"✅ App routes: {[rule.rule for rule in app.url_map.iter_rules()]}")
    
    # Test if we can create a test client
    with app.test_client() as client:
        response = client.get('/health')
        print(f"✅ Health endpoint responds: {response.status_code}")
        print(f"✅ Response: {response.get_data(as_text=True)}")
    
    print("✅ All tests passed!")
    sys.exit(0)
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

