/**
 * CNNO Cloud Functions.
 *
 * - recommend       FR-AI-01 Smart Recommendation (callable)
 * - orderAssistant  FR-AI-02 Order Assistant (callable)
 * - sendReceipt     FR-10 Email receipt (on order created)
 *
 * The Gemini API key is a Secret Manager secret (GEMINI_API_KEY). It is never
 * in the app or the repository. Set it with:
 *   firebase functions:secrets:set GEMINI_API_KEY
 */
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const { GoogleGenAI } = require('@google/genai');

admin.initializeApp();
const db = admin.firestore();

// Same region as Firestore. Low max instances keeps cost within the free tier.
setGlobalOptions({ region: 'asia-southeast1', maxInstances: 5 });

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const CONTACT_CNNO =
  'I am not sure about that one. Please contact CNNO directly and they will help you.';
const MAX_DAILY_AI_CALLS = 50; // per user per day (NFR-AI-03)

// ---------- helpers ----------

async function loadMenu() {
  const snap = await db.collection('products').get();
  return snap.docs
    .map((d) => ({ id: d.id, ...d.data() }))
    .sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
}

function menuText(products) {
  return products
    .map((p) => {
      const prices = (p.variants || [])
        .map((v) => (p.variants.length > 1 ? `${v.name} RM ${v.price}` : `RM ${v.price}`))
        .join(', ');
      const desc = [p.tagline, p.description].filter(Boolean).join(' ');
      return `- ${p.name} [id: ${p.id}] (${p.available ? 'available' : 'SOLD OUT'}): ${prices}. ${desc}`;
    })
    .join('\n');
}

async function checkQuota(uid) {
  const day = new Date().toISOString().slice(0, 10);
  const ref = db.collection('aiUsage').doc(`${uid}_${day}`);
  const count = await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    const n = (s.exists ? s.data().count : 0) + 1;
    tx.set(ref, { uid, day, count: n });
    return n;
  });
  if (count > MAX_DAILY_AI_CALLS) {
    throw new HttpsError('resource-exhausted', 'Daily AI limit reached.');
  }
}

async function generateJson(systemInstruction, contents) {
  const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY.value() });
  const res = await ai.models.generateContent({
    model: MODEL,
    contents,
    config: {
      systemInstruction,
      responseMimeType: 'application/json',
      temperature: 0.3,
      maxOutputTokens: 400,
    },
  });
  return JSON.parse(res.text);
}

const BUSINESS_RULES = `
CNNO facts (only use these):
- CNNO sells handmade cinnamon rolls. Prices are in ringgit (RM).
- Customers order in the CNNO app: add rolls to the cart, go to checkout, choose Pickup or Delivery,
  and choose a preferred pre-order date and time. The earliest date is tomorrow.
- Delivery is booked by CNNO on Grab outside the app. The delivery fee is quoted separately by CNNO.
- Payment is made outside the app. CNNO sends payment details after the order is placed.
- After ordering, the customer gets an email receipt and can track the order status in the Orders tab.
- Order statuses: Pending, Being prepared, Ready for pickup (pickup) or Out for delivery (delivery), Completed.
`;

// ---------- FR-AI-02 Order Assistant ----------

exports.orderAssistant = onCall({ secrets: [GEMINI_API_KEY] }, async (req) => {
  if (!req.auth) throw new HttpsError('unauthenticated', 'Please log in.');
  const raw = Array.isArray(req.data?.messages) ? req.data.messages : [];
  const messages = raw
    .slice(-10)
    .map((m) => ({
      role: m.role === 'user' ? 'user' : 'model',
      parts: [{ text: String(m.text || '').slice(0, 500) }],
    }))
    .filter((m) => m.parts[0].text.trim());
  if (!messages.length || messages[messages.length - 1].role !== 'user') {
    throw new HttpsError('invalid-argument', 'No question.');
  }
  await checkQuota(req.auth.uid);

  const menu = menuText(await loadMenu());
  const system = `You are the CNNO Order Assistant inside the CNNO app.
Answer the customer's question in 1 to 3 short, friendly sentences in the language they used.
Use ONLY the menu and facts below. Never invent products, prices, discounts, opening hours,
delivery fees or promises. Do not ask for or repeat personal data.
If the answer is not in the menu or facts, or you are not sure, set "confident" to false.

MENU (from the CNNO database):
${menu}
${BUSINESS_RULES}
Reply as JSON: {"reply": string, "confident": boolean}`;

  try {
    const out = await generateJson(system, messages);
    if (!out || out.confident !== true || !out.reply) return { reply: CONTACT_CNNO, confident: false };
    return { reply: String(out.reply).slice(0, 800), confident: true };
  } catch (e) {
    logger.error('orderAssistant failed', e);
    return { reply: CONTACT_CNNO, confident: false };
  }
});

// ---------- FR-AI-01 Smart Recommendation ----------

exports.recommend = onCall({ secrets: [GEMINI_API_KEY] }, async (req) => {
  if (!req.auth) throw new HttpsError('unauthenticated', 'Please log in.');
  const uid = req.auth.uid;
  await checkQuota(uid);

  const [products, userSnap, ordersSnap] = await Promise.all([
    loadMenu(),
    db.collection('users').doc(uid).get(),
    db.collection('orders').where('userId', '==', uid).limit(20).get(),
  ]);
  const available = products.filter((p) => p.available);
  if (!available.length) return { productId: null, message: '' };

  // Only flavour preferences and product names are sent to the AI, no personal data (NFR-AI-04).
  const favourites = (userSnap.data()?.favouriteFlavours || []).join(', ') || 'none given';
  const past = ordersSnap.docs.flatMap((d) => (d.data().items || []).map((i) => i.name));
  const pastText = past.length ? past.join(', ') : 'no past orders';

  const system = `You recommend one CNNO product to a customer.
Pick exactly one product id from the AVAILABLE list. Prefer a flavour the customer has not ordered
before that suits their favourites. Write a short message (max 10 words) such as
"Love chocolate? You may enjoy Pistachio." Do not mention prices or discounts.

AVAILABLE:
${menuText(available)}

Reply as JSON: {"productId": string, "message": string}`;

  try {
    const out = await generateJson(system, [
      { role: 'user', parts: [{ text: `Favourite flavours: ${favourites}. Past orders: ${pastText}.` }] },
    ]);
    const valid = available.some((p) => p.id === out?.productId);
    if (!valid || !out.message) return { productId: null, message: '' };
    return { productId: out.productId, message: String(out.message).slice(0, 80) };
  } catch (e) {
    logger.error('recommend failed', e);
    return { productId: null, message: '' };
  }
});

// ---------- FR-10 Email receipt ----------
// Writes to the `mail` collection, which the "Trigger Email from Firestore"
// Firebase extension sends (see docs/FIREBASE_SETUP.md).

exports.sendReceipt = onDocumentCreated('orders/{orderId}', async (event) => {
  const o = event.data?.data();
  if (!o || !o.customerEmail) return;
  const rm = (n) => `RM ${Number(n).toFixed(2)}`;
  const date = o.preferredDate?.toDate?.().toLocaleDateString('en-MY', {
    day: 'numeric', month: 'short', year: 'numeric', timeZone: 'Asia/Kuala_Lumpur',
  });
  const method = o.fulfilment === 'delivery' ? 'Delivery' : 'Pickup';
  const lines = (o.items || []).map((i) => `${i.quantity} x ${i.name}  ${rm(i.lineTotal)}`);
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

  const text = [
    `Hi ${o.customerName},`,
    '',
    `Thank you for your order #${o.number} with CNNO.`,
    '',
    ...lines,
    `Total: ${rm(o.total)}`,
    '',
    `${method} on ${date}, ${o.preferredTime}`,
    o.fulfilment === 'delivery' ? `Address: ${o.address}\nDelivery is booked by CNNO on Grab. The fee is quoted separately.` : '',
    `Payment: ${o.paymentMethod} (outside the app). CNNO will send payment details.`,
    '',
    "cnno's bakes",
  ].filter((l) => l !== null).join('\n');

  const html = `<p>Hi ${esc(o.customerName)},</p>
<p>Thank you for your order <b>#${o.number}</b> with CNNO.</p>
<table cellpadding="4">${(o.items || []).map((i) => `<tr><td>${i.quantity} x ${esc(i.name)}</td><td align="right">${rm(i.lineTotal)}</td></tr>`).join('')}
<tr><td><b>Total</b></td><td align="right"><b>${rm(o.total)}</b></td></tr></table>
<p>${method} on ${esc(date)}, ${esc(o.preferredTime)}${o.fulfilment === 'delivery' ? `<br>Address: ${esc(o.address)}<br>Delivery is booked by CNNO on Grab. The fee is quoted separately.` : ''}</p>
<p>Payment: ${esc(o.paymentMethod)} (outside the app). CNNO will send payment details.</p>
<p>cnno's bakes</p>`;

  await db.collection('mail').add({
    to: o.customerEmail,
    message: { subject: `CNNO receipt for order #${o.number}`, text, html },
    orderId: event.params.orderId,
  });
});
