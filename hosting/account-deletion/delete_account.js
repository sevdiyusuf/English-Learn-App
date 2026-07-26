// web/delete_account.js
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import {
  getAuth,
  signInWithEmailAndPassword,
  GoogleAuthProvider,
  signInWithPopup,
  signOut,
  setPersistence,
  browserSessionPersistence
} from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";
import {
  getFunctions,
  httpsCallable
} from "https://www.gstatic.com/firebasejs/10.8.0/firebase-functions.js";
import {
  initializeAppCheck,
  ReCaptchaEnterpriseProvider
} from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app-check.js";

// Firebase Config extracted from lib/firebase_options.dart
const firebaseConfig = {
  apiKey: "AIzaSyByotpukb4AtLC_lZQxc0CojeSq4DlWk44",
  appId: "1:55568769953:web:3dd0f776ec8324a1f921e0",
  messagingSenderId: "55568769953",
  projectId: "my-english-project-f25ff",
  authDomain: "my-english-project-f25ff.firebaseapp.com",
  storageBucket: "my-english-project-f25ff.firebasestorage.app",
  measurementId: "G-V2QYPYTFRV"
};

const app = initializeApp(firebaseConfig);

// App Check configuration
const siteKey = window.FIREBASE_APPCHECK_SITE_KEY || firebaseConfig.appCheckSiteKey;
const isAppCheckRequired = Boolean(window.FIREBASE_APPCHECK_REQUIRED || firebaseConfig.appCheckRequired);
let isAppCheckActive = false;

if (siteKey) {
  try {
    initializeAppCheck(app, {
      provider: new ReCaptchaEnterpriseProvider(siteKey),
      isTokenAutoRefreshEnabled: true
    });
    isAppCheckActive = true;
    console.log('[AppCheck] Web App Check (reCAPTCHA Enterprise) initialized successfully.');
  } catch (e) {
    console.warn('[AppCheck] Web App Check initialization warning:', e);
  }
} else {
  if (isAppCheckRequired) {
    console.error('[AppCheck] CRITICAL: Web App Check site key missing in production-required mode.');
  } else {
    console.info('[AppCheck] Web App Check site key not configured; skipping web activation in dev mode.');
  }
}

const auth = getAuth(app);
const functions = getFunctions(app, 'us-central1');

// DOM Elements
const authSection = document.getElementById('auth-section');
const deleteSection = document.getElementById('delete-section');
const successSection = document.getElementById('success-section');
const emailForm = document.getElementById('email-form');
const btnEmailLogin = document.getElementById('btn-email-login');
const btnGoogleLogin = document.getElementById('btn-google-login');
const btnDeleteAccount = document.getElementById('btn-delete-account');
const btnCancel = document.getElementById('btn-cancel');
const confirmCheckbox = document.getElementById('confirm-checkbox');
const errorMessage = document.getElementById('error-message');
const deleteErrorMessage = document.getElementById('delete-error-message');
const displayEmail = document.getElementById('display-email');

let isProcessing = false;

// Helpers
function showError(msg, element = errorMessage) {
  element.textContent = msg;
  element.style.display = 'block';
  element.classList.remove('hidden');
}

function hideErrors() {
  errorMessage.style.display = 'none';
  errorMessage.classList.add('hidden');
  deleteErrorMessage.style.display = 'none';
  deleteErrorMessage.classList.add('hidden');
}

function setButtonLoading(button, isLoading) {
  const text = button.querySelector('.btn-text');
  const loader = button.querySelector('.loader');

  if (isLoading) {
    button.disabled = true;
    if (text) text.style.display = 'none';
    if (loader) loader.style.display = 'block';
  } else {
    button.disabled = false;
    if (text) text.style.display = 'block';
    if (loader) loader.style.display = 'none';
  }
}

function maskEmail(email) {
  if (!email) return "Bilinmeyen Kullanıcı";
  const parts = email.split('@');
  if (parts.length !== 2) return email;
  const name = parts[0];
  if (name.length <= 2) return `${name}***@${parts[1]}`;
  return `${name.substring(0, 2)}***@${parts[1]}`;
}

// Error Mapping
function mapFirebaseError(error) {
  const code = error.code || error.message;
  switch (code) {
    case 'auth/user-not-found':
    case 'auth/wrong-password':
    case 'auth/invalid-credential':
      return 'E-posta adresi veya parola hatalı.';
    case 'auth/user-disabled':
      return 'Bu hesap devre dışı bırakılmış.';
    case 'auth/too-many-requests':
      return 'Çok fazla başarısız deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
    case 'auth/popup-closed-by-user':
    case 'auth/cancelled-popup-request':
      return 'Giriş işlemi iptal edildi.';
    case 'auth/popup-blocked':
      return 'Giriş penceresi tarayıcı tarafından engellendi. Lütfen popup engelleyiciyi kapatın.';
    case 'auth/network-request-failed':
      return 'Ağ bağlantısı hatası. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';

    // Callable Errors
    case 'unauthenticated':
    case 'functions/unauthenticated':
      return 'Oturum süresi doldu. Lütfen yeniden giriş yapın.';
    case 'permission-denied':
    case 'recent-login-required':
    case 'functions/permission-denied':
    case 'functions/failed-precondition':
      return 'Güvenlik nedeniyle yakın zamanda giriş yapmış olmanız gerekiyor. Lütfen yeniden giriş yapın.';
    case 'functions/resource-exhausted':
    case 'functions/unavailable':
      return 'Servis şu anda meşgul veya ulaşılamıyor. Lütfen daha sonra tekrar deneyin.';
    case 'functions/internal':
    case 'internal':
    case 'functions/unknown':
      return 'Sunucu tarafında bir hata oluştu. Lütfen daha sonra tekrar deneyin.';

    default:
      return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  }
}

// Auth State handling
async function handleSuccessfulLogin(user) {
  hideErrors();
  displayEmail.textContent = maskEmail(user.email);
  authSection.classList.add('hidden');
  deleteSection.classList.remove('hidden');
}

// Ensure session persistence is short-lived for security
setPersistence(auth, browserSessionPersistence).catch(console.error);

// Email/Password Login
emailForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  if (isProcessing) return;

  hideErrors();
  isProcessing = true;
  setButtonLoading(btnEmailLogin, true);

  const email = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;

  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    // Clear password field immediately
    document.getElementById('password').value = '';
    await handleSuccessfulLogin(userCredential.user);
  } catch (error) {
    showError(mapFirebaseError(error));
  } finally {
    isProcessing = false;
    setButtonLoading(btnEmailLogin, false);
  }
});

// Google Sign-In
btnGoogleLogin.addEventListener('click', async () => {
  if (isProcessing) return;

  hideErrors();
  isProcessing = true;
  btnGoogleLogin.disabled = true;

  const provider = new GoogleAuthProvider();
  try {
    const userCredential = await signInWithPopup(auth, provider);
    await handleSuccessfulLogin(userCredential.user);
  } catch (error) {
    showError(mapFirebaseError(error));
  } finally {
    isProcessing = false;
    btnGoogleLogin.disabled = false;
  }
});

// Checkbox enable/disable delete button
confirmCheckbox.addEventListener('change', (e) => {
  if (!isProcessing) {
    btnDeleteAccount.disabled = !e.target.checked;
  }
});

// Cancel button
btnCancel.addEventListener('click', async () => {
  try {
    await signOut(auth);
  } catch (e) {
    // ignore
  }
  window.location.reload();
});

// Delete Account action
btnDeleteAccount.addEventListener('click', async () => {
  if (isProcessing || !confirmCheckbox.checked) return;

  if (isAppCheckRequired && !isAppCheckActive) {
    showError('Güvenlik doğrulama yapılandırması eksik. Lütfen daha sonra tekrar deneyin.', deleteErrorMessage);
    return;
  }

  hideErrors();
  isProcessing = true;
  setButtonLoading(btnDeleteAccount, true);
  btnCancel.disabled = true;
  confirmCheckbox.disabled = true;

  try {
    const requestAccountDeletion = httpsCallable(functions, 'requestAccountDeletion');
    // Payload is empty, server relies entirely on Auth token UID
    await requestAccountDeletion({});

    // Successfully deleted
    await signOut(auth);
    deleteSection.classList.add('hidden');
    successSection.classList.remove('hidden');

  } catch (error) {
    // If recent-login required or unauthenticated
    if (error.code === 'permission-denied' || error.message === 'recent-login-required' || error.code === 'unauthenticated') {
      await signOut(auth);
      deleteSection.classList.add('hidden');
      authSection.classList.remove('hidden');
      showError('Güvenlik nedeniyle tekrar giriş yapmanız gerekmektedir.');
      confirmCheckbox.checked = false;
    } else {
      showError(mapFirebaseError(error), deleteErrorMessage);
    }
  } finally {
    isProcessing = false;
    setButtonLoading(btnDeleteAccount, false);
    btnCancel.disabled = false;
    confirmCheckbox.disabled = false;
    if (!confirmCheckbox.checked) {
      btnDeleteAccount.disabled = true;
    }
  }
});

// Automatically sign out on page load to ensure fresh authentication
signOut(auth).catch(() => {});
