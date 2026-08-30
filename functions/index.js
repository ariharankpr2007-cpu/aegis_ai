const { setGlobalOptions } = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/https");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

setGlobalOptions({
  maxInstances: 10,
});

exports.createOfficer = onCall(async (request) => {
  // 1. Make sure someone is logged in.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in."
    );
  }

  // 2. Check that the logged-in user is an Admin.
  const adminDoc = await db
      .collection("users")
      .doc(request.auth.uid)
      .get();

  if (!adminDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Admin profile not found."
    );
  }

  const adminData = adminDoc.data();

  if (adminData.role !== "Admin") {
    throw new HttpsError(
      "permission-denied",
      "Only an Admin can create Officer accounts."
    );
  }

  // 3. Get Officer information from the app.
  const {
    name,
    email,
    phone,
    department,
    password,
  } = request.data;

  // 4. Validate the information.
  if (
    !name ||
    !email ||
    !phone ||
    !department ||
    !password
  ) {
    throw new HttpsError(
      "invalid-argument",
      "All Officer details are required."
    );
  }

  if (password.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Password must contain at least 6 characters."
    );
  }

  try {
    // 5. Create Firebase Authentication account.
    const officer =
        await admin.auth().createUser({
          email: email.trim(),
          password: password,
          displayName: name.trim(),
          phoneNumber: phone.trim(),
        });

    // 6. Create the Officer's user document.
    await db
        .collection("users")
        .doc(officer.uid)
        .set({
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          department: department.trim(),
          role: "Officer",
          createdBy: request.auth.uid,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    return {
      success: true,
      uid: officer.uid,
      message: "Officer account created successfully.",
    };
  } catch (error) {
    console.error("Create Officer Error:", error);

    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
        "already-exists",
        "An account with this email already exists."
      );
    }

    if (error.code === "auth/invalid-phone-number") {
      throw new HttpsError(
        "invalid-argument",
        "Enter a valid phone number."
      );
    }

    throw new HttpsError(
      "internal",
      "Unable to create Officer account."
    );
  }
});