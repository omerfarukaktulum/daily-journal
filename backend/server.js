const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const stripe = require('stripe')(require('./config').stripe.secretKey);
const config = require('./config');

const app = express();

// Security middleware
app.use((req, res, next) => {
  // Rate limiting (basic)
  const clientIP = req.ip || req.connection.remoteAddress;
  console.log(`🔒 Request from: ${clientIP} to ${req.path}`);
  next();
});

// CORS with specific origins
app.use(cors({
  origin: config.cors.allowedOrigins,
  credentials: true,
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parsing with size limits
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));

// Routes
app.get('/', (req, res) => {
  res.json({ 
    message: 'Memora Backend Server', 
    version: '1.0.0',
    status: 'running',
    endpoints: {
      'POST /api/create-payment-intent': 'Create Stripe payment intent',
      'POST /api/confirm-payment': 'Confirm payment with Stripe',
      'GET /api/health': 'Health check'
    }
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    stripe: 'connected'
  });
});

// Create Payment Intent
app.post('/api/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency = 'usd', plan } = req.body;
    
    // Input validation
    if (!amount || amount < 50 || amount > 100000) {
      return res.status(400).json({
        success: false,
        error: 'Invalid amount. Must be between $0.50 and $1000.00'
      });
    }
    
    if (!['usd', 'eur', 'gbp'].includes(currency)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid currency. Supported: usd, eur, gbp'
      });
    }
    
    if (!['monthly', 'yearly'].includes(plan)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid plan. Supported: monthly, yearly'
      });
    }
    
    console.log('🔧 Backend: Creating payment intent:', { amount, currency, plan, amountInDollars: `$${(amount / 100).toFixed(2)}` });
    
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      automatic_payment_methods: {
        enabled: true,
      },
      metadata: {
        app: 'memora',
        plan: plan || 'unknown',
        timestamp: new Date().toISOString()
      }
    });
    
    console.log('✅ Backend: Payment intent created:', paymentIntent.id);
    console.log('✅ Backend: Client secret generated');
    
    res.json({
      success: true,
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id
    });
    
  } catch (error) {
    console.error('❌ Backend: Error creating payment intent:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Confirm Payment
app.post('/api/confirm-payment', async (req, res) => {
  try {
    const { paymentIntentId, paymentMethodId } = req.body;
    
    console.log('🔧 Backend: Confirming payment:', { paymentIntentId, paymentMethodId });
    
    const paymentIntent = await stripe.paymentIntents.confirm(paymentIntentId, {
      payment_method: paymentMethodId
    });
    
    console.log('✅ Backend: Payment confirmed:', paymentIntent.id, 'Status:', paymentIntent.status);
    
    res.json({
      success: true,
      status: paymentIntent.status,
      paymentIntentId: paymentIntent.id
    });
    
  } catch (error) {
    console.error('❌ Backend: Error confirming payment:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});


// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Something went wrong!'
  });
});

// Start server
const PORT = config.server.port;
app.listen(PORT, () => {
  console.log(`🚀 Memora Backend Server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`💳 Stripe integration: Ready`);
  console.log(`🌍 Environment: ${config.server.nodeEnv}`);
});
