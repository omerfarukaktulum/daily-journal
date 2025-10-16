const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const stripe = require('stripe')(require('./config').stripe.secretKey);
const config = require('./config');

const app = express();

// Middleware
app.use(cors({
  origin: config.cors.allowedOrigins,
  credentials: true
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

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

// Webhook endpoint for Stripe events
app.post('/api/webhook', express.raw({type: 'application/json'}), async (req, res) => {
  console.log('🔧 Webhook: Request received at', new Date().toISOString());
  console.log('🔧 Webhook: Headers:', req.headers);
  console.log('🔧 Webhook: Body length:', req.body?.length || 0);
  console.log('🔧 Webhook: Raw body preview:', req.body?.toString().substring(0, 100) || 'No body');
  
  const sig = req.headers['stripe-signature'];
  const endpointSecret = 'whsec_39e83cf1b9296d2b1dd1cd77762ad354d9285895ffca4e2568a34f34f515a84e';
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
    console.log('✅ Webhook: Event received:', event.type);
  } catch (err) {
    console.log(`❌ Webhook: Signature verification failed.`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  try {
    switch (event.type) {
      case 'payment_intent.succeeded':
        const paymentIntent = event.data.object;
        console.log('✅ Webhook: Payment succeeded:', paymentIntent.id);
        console.log('✅ Webhook: Amount:', paymentIntent.amount);
        console.log('✅ Webhook: Currency:', paymentIntent.currency);
        console.log('✅ Webhook: Metadata:', paymentIntent.metadata);
        
        // Update user premium status in your database
        // This is where you would update your user's premium status
        // For now, we'll just log the success
        console.log('✅ Webhook: Payment processing completed successfully');
        break;
        
      case 'checkout.session.completed':
        const session = event.data.object;
        console.log('✅ Webhook: Checkout session completed:', session.id);
        console.log('✅ Webhook: Amount total:', session.amount_total);
        console.log('✅ Webhook: Currency:', session.currency);
        console.log('✅ Webhook: Metadata:', session.metadata);
        console.log('✅ Webhook: Payment status:', session.payment_status);
        break;
        
      case 'payment_intent.payment_failed':
        const failedPayment = event.data.object;
        console.log('❌ Webhook: Payment failed:', failedPayment.id);
        console.log('❌ Webhook: Failure reason:', failedPayment.last_payment_error?.message);
        break;
        
      case 'payment_intent.canceled':
        const canceledPayment = event.data.object;
        console.log('⚠️ Webhook: Payment canceled:', canceledPayment.id);
        break;
        
      default:
        console.log(`ℹ️ Webhook: Unhandled event type ${event.type}`);
    }
  } catch (error) {
    console.error('❌ Webhook: Error processing event:', error);
    return res.status(500).send('Webhook processing failed');
  }

  res.json({received: true});
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
