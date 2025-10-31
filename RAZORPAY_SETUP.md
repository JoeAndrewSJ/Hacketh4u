# Razorpay Setup Instructions

## 1. Get Razorpay Keys

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Sign up or log in to your account
3. Go to Settings > API Keys
4. Generate API Keys (Test mode for development)

## 2. Update Environment Variables

1. Open the `.env` file in the project root
2. Replace the placeholder values with your actual Razorpay keys:

```
RAZORPAY_KEY_ID=rzp_test_your_key_id_here
RAZORPAY_KEY_SECRET=your_key_secret_here
```

## 3. Important Notes

- **Never commit your actual keys to version control**
- Use test keys for development
- Use live keys only for production
- Keep your key secret secure and never expose it in client-side code

## 4. Testing

- The payment system is now integrated
- Test with Razorpay's test card numbers
- Check the console logs for debugging information

## 5. Production Deployment

- Update the keys in your production environment
- Ensure proper security measures are in place
- Test thoroughly before going live
