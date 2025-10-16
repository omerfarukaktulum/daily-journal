#!/bin/bash

# Setup script for production deployment
echo "🚀 Setting up production credentials..."

# Create Secrets.plist from template
if [ ! -f "memora/memora/Config/Secrets.plist" ]; then
    echo "📝 Creating Secrets.plist from template..."
    cp memora/memora/Config/Secrets.plist.template memora/memora/Config/Secrets.plist
    echo "✅ Secrets.plist created! Please update it with your production credentials."
else
    echo "⚠️  Secrets.plist already exists. Skipping creation."
fi

echo ""
echo "📋 Next steps:"
echo "1. Update memora/memora/Config/Secrets.plist with your production credentials:"
echo "   - STRIPE_PUBLISHABLE_KEY_LIVE: Your live Stripe publishable key"
echo "   - BACKEND_URL_PRODUCTION: Your deployed backend URL"
echo ""
echo "2. Deploy your backend to your hosting service (Vercel, Heroku, etc.)"
echo ""
echo "3. Update your backend environment variables:"
echo "   - STRIPE_SECRET_KEY: Your live Stripe secret key"
echo "   - STRIPE_PUBLISHABLE_KEY: Your live Stripe publishable key"
echo ""
echo "4. Build and deploy your iOS app to App Store"
echo ""
echo "🔒 Security Note: Secrets.plist is in .gitignore and won't be committed to git."
