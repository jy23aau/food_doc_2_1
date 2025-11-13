/**
 * Cloud Function: onRecordCreate
 * - Trigger: Firestore document create in `records/{docId}`
 * - Behavior: inspect the record for potential FSA / H&S breaches (fridge temp >4°C,
 *   oven hot hold <60°C, allergen handling flags, expired invoice dates) and send
 *   an FCM topic message to 'fsa_alerts' with details.
 *
 * Deployment:
 * 1. Install Firebase CLI: `npm install -g firebase-tools`
 * 2. Login and init functions (in project root): `firebase login` then
 *    `firebase init functions` (choose existing project or create new). Copy this
 *    file into the `functions/` folder created by the CLI.
 * 3. From functions folder: `npm install` then `firebase deploy --only functions`
 *
 * Note: The function sends to the topic 'fsa_alerts'. Make sure your app
 * subscribes to that topic (or modify to send to specific device tokens).
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Optional third-party providers for escalations. Configure API keys via
// Firebase environment config or process.env (recommended to use
// `firebase functions:config:set sendgrid.key="..." twilio.sid="..." twilio.token="..." twilio.from="+123" escalation.to_email="ops@example.com" escalation.to_phone="+44..."
// then `firebase deploy --only functions`)
let sendGrid;
let twilioClient;
try {
  sendGrid = require('@sendgrid/mail');
} catch (e) {
  // dependency may not be installed until `npm install` in functions/
}
try {
  const Twilio = require('twilio');
  twilioClient = Twilio;
} catch (e) {
  // ignore
}

async function sendEmail(subject, body) {
  try {
    // Prefer Firebase functions config:
    const sgKey = functions.config && functions.config().sendgrid && functions.config().sendgrid.key ? functions.config().sendgrid.key : process.env.SENDGRID_API_KEY;
    const toEmail = functions.config && functions.config().escalation && functions.config().escalation.to_email ? functions.config().escalation.to_email : process.env.ESCALATION_EMAIL;
    const fromEmail = functions.config && functions.config().sendgrid && functions.config().sendgrid.from ? functions.config().sendgrid.from : process.env.SENDGRID_FROM || toEmail;
    if (!sendGrid || !sgKey || !toEmail) {
      console.warn('SendGrid not configured; skipping email');
      return;
    }
    sendGrid.setApiKey(sgKey);
    const msg = {
      to: toEmail,
      from: fromEmail,
      subject: subject,
      text: body,
      html: `<pre>${body}</pre>`,
    };
    await sendGrid.send(msg);
    console.log('Escalation email sent');
  } catch (err) {
    console.error('sendEmail error', err);
  }
}

async function sendSms(body) {
  try {
    const sid = functions.config && functions.config().twilio && functions.config().twilio.sid ? functions.config().twilio.sid : process.env.TWILIO_SID;
    const token = functions.config && functions.config().twilio && functions.config().twilio.token ? functions.config().twilio.token : process.env.TWILIO_TOKEN;
    const from = functions.config && functions.config().twilio && functions.config().twilio.from ? functions.config().twilio.from : process.env.TWILIO_FROM;
    const to = functions.config && functions.config().escalation && functions.config().escalation.to_phone ? functions.config().escalation.to_phone : process.env.ESCALATION_PHONE;
    if (!twilioClient || !sid || !token || !from || !to) {
      console.warn('Twilio not configured; skipping SMS');
      return;
    }
    const client = twilioClient(sid, token);
    await client.messages.create({ body, from, to });
    console.log('Escalation SMS sent');
  } catch (err) {
    console.error('sendSms error', err);
  }
}

function buildAlertForRecord(data) {
  const alerts = [];

  // Fridge breach
  if (data.type === 'fridge') {
    const temp = parseFloat(data.temp);
    if (!isNaN(temp) && temp > 4.0) {
      alerts.push({
        title: 'Fridge temperature breach',
        body: `Fridge recorded ${temp}°C (over 4°C). Immediate action required.`
      });
    }
  }

  // Oven hot-hold breach
  if (data.type === 'oven' && data.mode === 'hot_hold') {
    const temp = parseFloat(data.temp);
    if (isNaN(temp) || temp < 60.0) {
      alerts.push({
        title: 'Oven hot-hold unsafe',
        body: `Oven hot-hold temperature ${data.temp ?? 'N/A'}°C is below 60°C.`
      });
    }
  }

  // Allergen issues
  if (data.type === 'allergen') {
    if (data.cross_contam_risk === true || data.segregation_ok === false || data.labeling_ok === false) {
      alerts.push({
        title: 'Allergen handling issue',
        body: `Potential issue for ${data.allergen ?? 'an allergen'} detected. Check segregation & labeling.`
      });
    }
  }

  // Invoice expiry check: look for `date` field and compare to today
  if (data.type === 'invoice' || data.supplier != null || data.date != null) {
    try {
      const d = data.date;
      if (d) {
        const parsed = new Date(d);
        if (!isNaN(parsed.getTime())) {
          const today = new Date();
          // If invoice contains an expiry-like date and it's in the past, warn
          if (parsed < today) {
            alerts.push({
              title: 'Invoice date warning',
              body: `Invoice or ingredient date ${d} appears to be in the past; check expiry.`
            });
          }
        }
      }
    } catch (e) {
      // ignore parse errors
    }
  }

  return alerts;
}

exports.onRecordCreate = functions.firestore.document('records/{docId}').onCreate(async (snap, context) => {
  const data = snap.data() || {};

  const alerts = buildAlertForRecord(data);
  if (alerts.length === 0) {
    // No issues detected
    return null;
  }

  // Send each alert as a topic message to 'fsa_alerts'
  const promises = alerts.map(a => {
    const message = {
      topic: 'fsa_alerts',
      notification: {
        title: a.title,
        body: a.body
      },
      data: {
        docId: context.params.docId || '',
        type: data.type || '',
        timestamp: data.timestamp || ''
      }
    };
    return admin.messaging().send(message);
  });

  try {
    const results = await Promise.all(promises);
    console.log('Sent alerts for document', context.params.docId, results);

    // Escalation: if any alert matches severe criteria, also send email/SMS
    const severe = alerts.some(a => /breach|unsafe|issue|warning/i.test(a.title + ' ' + a.body));
    if (severe) {
      const combined = alerts.map(a => `${a.title}: ${a.body}`).join('\n');
      // fire-and-forget
      sendEmail('Escalation: safety alert', combined);
      sendSms(combined);
    }
    return null;
  } catch (err) {
    console.error('Error sending alert messages', err);
    return null;
  }
});
