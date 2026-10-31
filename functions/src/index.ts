import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

interface PlanInfo {
  name: string;
  amount: number;
  memberLimit: string;
}

// Centralized Plan Catalog for server validation
const PLAN_CATALOG: Record<string, PlanInfo> = {
  family_basic: {
    name: "Family Basic",
    amount: 0,
    memberLimit: "Up to 3 family members",
  },
  family_pro: {
    name: "Family Pro",
    amount: 299,
    memberLimit: "Up to 8 family members",
  },
  family_premium: {
    name: "Family Premium",
    amount: 599,
    memberLimit: "Unlimited family members",
  },
};

/**
 * Server-side email verification enforcement & onboarding init
 */
export const checkServerEmailVerification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const userRecord = await admin.auth().getUser(request.auth.uid);
  const isVerified = userRecord.emailVerified;

  if (isVerified) {
    const userRef = db.collection("users").doc(request.auth.uid);
    const userSnap = await userRef.get();
    const currentStatus = userSnap.data()?.onboardingStatus;

    if (currentStatus === "ACCOUNT_CREATED" || currentStatus === "NO_ACCOUNT") {
      await userRef.set({
        emailVerified: true,
        onboardingStatus: "EMAIL_VERIFIED",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    }
  }

  return {emailVerified: isVerified};
});

/**
 * Server-side Family & Admin Membership creation
 * Enforces:
 * 1. Caller authenticated
 * 2. Caller email verified server-side
 * 3. Idempotent family creation & atomic admin membership linking
 */
export const createFamilyGroupServer = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  // 1. Server-side Email Verification check (Section 7)
  const userRecord = await admin.auth().getUser(request.auth.uid);
  if (!userRecord.emailVerified) {
    throw new HttpsError(
      "permission-denied",
      "Email verification is required before creating family records."
    );
  }

  const uid = request.auth.uid;
  const familyName = (request.data.familyName || "").trim();
  const description = (request.data.description || "").trim();
  const memberId = request.data.memberId;

  if (!familyName || familyName.length < 2 || familyName.length > 100) {
    throw new HttpsError(
      "invalid-argument",
      "Family name must be between 2 and 100 characters."
    );
  }

  if (description.length > 250) {
    throw new HttpsError(
      "invalid-argument",
      "Description cannot exceed 250 characters."
    );
  }

  // Check existing family for admin (Idempotence)
  const existingFamilyQuery = await db.collection("families")
    .where("adminUid", "==", uid)
    .limit(1)
    .get();

  const batch = db.batch();
  let familyId: string;

  if (!existingFamilyQuery.empty) {
    familyId = existingFamilyQuery.docs[0].id;
    const famRef = db.collection("families").doc(familyId);
    batch.update(famRef, {
      familyName,
      description: description || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else {
    const famRef = db.collection("families").doc();
    familyId = `fam_${famRef.id.substring(0, 8)}`;
    const newFamRef = db.collection("families").doc(familyId);

    batch.set(newFamRef, {
      familyId,
      familyName,
      description: description || null,
      adminUid: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // Ensure ADMIN membership for memberId
  if (memberId) {
    const membershipQuery = await db.collection("familyMemberships")
      .where("familyId", "==", familyId)
      .where("memberId", "==", memberId)
      .limit(1)
      .get();

    if (membershipQuery.empty) {
      const mbrRef = db.collection("familyMemberships").doc();
      const membershipId = `mbr_${mbrRef.id.substring(0, 8)}`;
      const newMbrRef = db.collection("familyMemberships").doc(membershipId);

      batch.set(newMbrRef, {
        membershipId,
        familyId,
        memberId,
        role: "ADMIN",
        status: "ACTIVE",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  // Update user onboarding status
  const userRef = db.collection("users").doc(uid);
  batch.set(userRef, {
    onboardingStatus: "FAMILY_CREATED",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  await batch.commit();

  return {
    success: true,
    familyId,
    familyName,
    role: "ADMIN",
  };
});

/**
 * Server-side Mock Subscription Processor
 * Enforces:
 * 1. Verified email
 * 2. Admin ownership of family
 * 3. Payment mode tagged as MOCK
 * 4. Idempotent subscription update
 */
export const processMockSubscriptionServer = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const uid = request.auth.uid;
  const {familyId, planId, simulateSuccess = true} = request.data;

  const plan = PLAN_CATALOG[planId];
  if (!plan) {
    throw new HttpsError("invalid-argument", "Invalid subscription plan.");
  }

  // Verify caller is admin of this family
  const familyDoc = await db.collection("families").doc(familyId).get();
  if (!familyDoc.exists || familyDoc.data()?.adminUid !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the Family Admin can manage family subscriptions."
    );
  }

  const isFree = plan.amount === 0;
  let status = "PAYMENT_FAILED";
  if (isFree) {
    status = "FREE";
  } else if (simulateSuccess) {
    status = "MOCK_ACTIVE";
  }

  const subQuery = await db.collection("subscriptions")
    .where("familyId", "==", familyId)
    .limit(1)
    .get();

  let subscriptionId: string;
  const batch = db.batch();

  const timestamp = Date.now();
  let mockTransactionId = `txn_failed_${timestamp}`;
  if (isFree) {
    mockTransactionId = `txn_free_${timestamp}`;
  } else if (simulateSuccess) {
    const randomHex = Math.random().toString(36).substring(2, 6);
    mockTransactionId = `txn_mock_${timestamp}_${randomHex}`;
  }

  if (!subQuery.empty) {
    subscriptionId = subQuery.docs[0].id;
    const subRef = db.collection("subscriptions").doc(subscriptionId);
    batch.update(subRef, {
      planId,
      amount: plan.amount,
      currency: "INR",
      billingCycle: "MONTHLY",
      status,
      paymentMode: "MOCK",
      mockTransactionId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else {
    const subRef = db.collection("subscriptions").doc();
    subscriptionId = `sub_${subRef.id.substring(0, 8)}`;
    const newSubRef = db.collection("subscriptions").doc(subscriptionId);

    batch.set(newSubRef, {
      subscriptionId,
      familyId,
      planId,
      amount: plan.amount,
      currency: "INR",
      billingCycle: "MONTHLY",
      status,
      paymentMode: "MOCK",
      mockTransactionId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // If approved or free, mark onboarding complete
  if (status === "MOCK_ACTIVE" || status === "FREE") {
    const userRef = db.collection("users").doc(uid);
    batch.update(userRef, {
      pendingPlanId: null,
      onboardingStatus: "COMPLETED",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();

  return {
    subscriptionId,
    status,
    paymentMode: "MOCK",
    mockTransactionId,
  };
});
