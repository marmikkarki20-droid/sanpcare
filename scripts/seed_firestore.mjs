import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';

const projectId = 'caresnap-app';
const databaseId = '(default)';

const staffId = 'JEioTdZJc5adxE9Bo2nrtBO6Y653';
const adminId = 'G0vPJ4myfbgC5Ip0O0al595fCKv2';
const clientId = 'client-bluegum-demo';

const now = new Date();
const startTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 7);
const endTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 15);
const dateStamp = [
  now.getFullYear(),
  String(now.getMonth() + 1).padStart(2, '0'),
  String(now.getDate()).padStart(2, '0'),
].join('');

const tokenPath = `${homedir()}/.config/configstore/firebase-tools.json`;
const tokenConfig = JSON.parse(readFileSync(tokenPath, 'utf8'));
const accessToken = tokenConfig.tokens?.access_token;

if (!accessToken) {
  throw new Error('Firebase CLI access token not found. Run `firebase login` first.');
}

function docPath(path) {
  return `projects/${projectId}/databases/${databaseId}/documents/${path}`;
}

function value(input) {
  if (input instanceof Date) return { timestampValue: input.toISOString() };
  if (typeof input === 'string') return { stringValue: input };
  if (typeof input === 'boolean') return { booleanValue: input };
  if (typeof input === 'number') {
    return Number.isInteger(input) ? { integerValue: String(input) } : { doubleValue: input };
  }
  if (Array.isArray(input)) return { arrayValue: { values: input.map(value) } };
  if (input && typeof input === 'object') return { mapValue: { fields: fields(input) } };
  return { nullValue: null };
}

function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, item]) => [key, value(item)]));
}

const docs = [
  {
    path: `users/${staffId}`,
    data: {
      fullName: 'Mia Thompson',
      email: 'staffmarmik@caresnap.com',
      role: 'staff',
      position: 'Disability Support Worker',
      facilityId: 'bluegum-house',
      isActive: true,
      createdAt: now,
    },
  },
  {
    path: `users/${adminId}`,
    data: {
      fullName: 'Jordan Lee',
      email: 'admin1@caresnap.com',
      role: 'admin',
      position: 'Care Coordinator',
      facilityId: 'bluegum-house',
      isActive: true,
      createdAt: now,
    },
  },
  {
    path: `clients/${clientId}`,
    data: {
      fullName: 'Avery Nguyen',
      roomNumber: 'Room 12',
      address: 'Bluegum Supported Living, Sydney NSW',
      careNeeds: 'Personal care support, meal prompting, community access, and low-stimulation routines.',
      mobilityStatus: 'Walks independently indoors. Supervision required on stairs and wet surfaces.',
      communicationNeeds: 'Prefers short sentences, visual choices, and extra response time.',
      riskNotes: 'Falls risk during fatigue. Sensory overload can increase agitation in noisy areas.',
      emergencyContact: 'Taylor Nguyen, 0400 111 222',
      createdAt: now,
    },
  },
  {
    path: `shifts/shift-${staffId}-${dateStamp}`,
    data: {
      staffId,
      clientId,
      startTime,
      endTime,
      serviceLocation: 'Bluegum Supported Living, Room 12',
      assignedLatitude: -33.8688,
      assignedLongitude: 151.2093,
      checkInStatus: 'Pending',
      shiftStatus: 'Scheduled',
      createdAt: now,
    },
  },
  {
    path: 'progressNotes/note-seed-morning',
    data: {
      staffId,
      clientId,
      shiftSummary: 'Morning routine completed with calm engagement.',
      activities: 'Short garden walk and music session.',
      mealsFluids: 'Breakfast completed. Fluids encouraged throughout morning.',
      personalCare: 'One-person assistance for shower and dressing.',
      moodBehaviour: 'Settled, positive response to quiet prompts.',
      communication: 'Used simple choices and visual schedule.',
      followUp: 'Monitor fatigue after lunch.',
      createdAt: new Date(now.getTime() - 2 * 60 * 60 * 1000),
    },
  },
  {
    path: 'incidentReports/incident-seed-fall-risk',
    data: {
      staffId,
      clientId,
      incidentType: 'Fall risk',
      description: 'Client stumbled near hallway mat but recovered with staff support.',
      injuryObserved: 'No injury observed.',
      actionTaken: 'Removed mat, completed observation, informed coordinator.',
      informedPerson: 'Jordan Lee',
      witnessDetails: 'No external witnesses.',
      followUp: 'Review hallway trip risks.',
      imageUrl: null,
      status: 'underReview',
      createdAt: new Date(now.getTime() - 90 * 60 * 1000),
    },
  },
  {
    path: 'hazardReports/hazard-seed-trip',
    data: {
      staffId,
      hazardType: 'Trip hazard',
      location: 'Hallway near laundry',
      riskLevel: 'Medium',
      description: 'Power cable crossing walking path.',
      actionTaken: 'Moved cable aside and notified maintenance.',
      imageUrl: null,
      status: 'actionRequired',
      createdAt: new Date(now.getTime() - 70 * 60 * 1000),
    },
  },
  {
    path: 'behaviourCharts/behaviour-seed-noise',
    data: {
      staffId,
      clientId,
      trigger: 'Loud hallway noise during morning routine.',
      behaviourObserved: 'Client became anxious and moved away from group area.',
      staffResponse: 'Offered quiet room and simple reassurance.',
      deEscalationStrategy: 'Reduced stimulation and used visual choice card.',
      outcome: 'Client settled within 10 minutes.',
      moodLevel: 'Anxious',
      followUp: 'Use quieter transition time tomorrow.',
      createdAt: new Date(now.getTime() - 45 * 60 * 1000),
    },
  },
  {
    path: 'checkIns/checkin-seed-verified',
    data: {
      staffId,
      shiftId: `shift-${staffId}-${dateStamp}`,
      status: 'Verified',
      latitude: -33.8688,
      longitude: 151.2093,
      distanceMetres: 0,
      createdAt: new Date(now.getTime() - 3 * 60 * 60 * 1000),
    },
  },
];

const writes = docs.map((doc) => ({
  update: {
    name: docPath(doc.path),
    fields: fields(doc.data),
  },
}));

const response = await fetch(
  `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${databaseId}/documents:commit`,
  {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ writes }),
  },
);

if (!response.ok) {
  const body = await response.text();
  throw new Error(`Firestore seed failed: ${response.status} ${body}`);
}

console.log(`Seeded ${docs.length} Firestore documents into ${projectId}.`);
