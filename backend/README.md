# Memora Backend Server

Backend server for Memora app with Stripe payment integration.

## 🚀 Quick Start

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure Environment
Create a `.env` file with your Stripe keys:

```bash
# Create .env file
touch .env

# Add your Stripe keys to .env
echo "STRIPE_SECRET_KEY=your_stripe_secret_key_here" >> .env
echo "STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here" >> .env
echo "PORT=3000" >> .env
echo "NODE_ENV=development" >> .env
echo "ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080" >> .env
```

### 3. Start the Server
```bash
# Development mode (with auto-restart)
npm run dev

# Production mode
npm start
```

## 📡 API Endpoints

### Health Check
```
GET /api/health
```

### Create Payment Intent
```
POST /api/create-payment-intent
Content-Type: application/json

{
  "amount": 499,
  "currency": "usd",
  "plan": "monthly"
}
```

### Confirm Payment
```
POST /api/confirm-payment
Content-Type: application/json

{
  "paymentIntentId": "pi_...",
  "paymentMethodId": "pm_..."
}
```


## 🔧 Configuration

The server requires environment variables to be set:
- **STRIPE_SECRET_KEY**: Your Stripe secret key (sk_test_...)
- **STRIPE_PUBLISHABLE_KEY**: Your Stripe publishable key (pk_test_...)

## 🌍 Deployment

### Heroku
```bash
# Install Heroku CLI
# Create new app
heroku create memora-backend

# Set environment variables
heroku config:set STRIPE_SECRET_KEY=sk_live_...
heroku config:set STRIPE_PUBLISHABLE_KEY=pk_live_...

# Deploy
git push heroku main
```

### Railway
```bash
# Connect to Railway
railway login
railway init
railway up
```

## 🔍 Testing

### Test Payment Intent Creation
```bash
curl -X POST http://localhost:3000/api/create-payment-intent \
  -H "Content-Type: application/json" \
  -d '{"amount": 499, "currency": "usd", "plan": "monthly"}'
```

### Test Health Check
```bash
curl http://localhost:3000/api/health
```

## 📊 Stripe Dashboard

All payments will appear in your Stripe test dashboard with:
- **App metadata**: `app=memora`
- **Plan metadata**: `plan=monthly|yearly`
- **Test mode**: All transactions are test transactions

## 🛠 Development

The server includes:
- **CORS enabled** for iOS app
- **Error handling** with detailed logs
- **Health monitoring** endpoint
- **Automatic restart** in development mode
