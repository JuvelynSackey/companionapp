package com.example.data.auth

import android.content.Context
import android.util.Log
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.UserProfileChangeRequest
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

sealed class AuthResultState {
    object Idle : AuthResultState()
    object Loading : AuthResultState()
    data class Success(val user: FirebaseUser, val message: String? = null) : AuthResultState()
    data class Error(val message: String) : AuthResultState()
}

class FirebaseAuthManager(
    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
) {
    companion object {
        private const val TAG = "FirebaseAuthManager"
    }

    val currentUser: FirebaseUser?
        get() = auth.currentUser

    /**
     * Emits the current FirebaseUser whenever authentication state changes.
     */
    val authStateFlow: Flow<FirebaseUser?> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { firebaseAuth ->
            trySend(firebaseAuth.currentUser)
        }
        auth.addAuthStateListener(listener)
        awaitClose { auth.removeAuthStateListener(listener) }
    }

    /**
     * Sign in with Email and Password
     */
    suspend fun signInWithEmail(email: String, password: String): Result<FirebaseUser> {
        return try {
            val authResult: AuthResult = auth.signInWithEmailAndPassword(email.trim(), password).await()
            val user = authResult.user ?: throw Exception("User is null after sign in")
            Result.success(user)
        } catch (e: Exception) {
            Log.e(TAG, "signInWithEmail failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    /**
     * Sign up / Register with Email, Password and Display Name
     */
    suspend fun signUpWithEmail(
        email: String,
        password: String,
        displayName: String? = null
    ): Result<FirebaseUser> {
        return try {
            val authResult: AuthResult = auth.createUserWithEmailAndPassword(email.trim(), password).await()
            val user = authResult.user ?: throw Exception("User is null after registration")

            if (!displayName.isNullOrBlank()) {
                val profileUpdates = UserProfileChangeRequest.Builder()
                    .setDisplayName(displayName.trim())
                    .build()
                user.updateProfile(profileUpdates).await()
            }

            Result.success(user)
        } catch (e: Exception) {
            Log.e(TAG, "signUpWithEmail failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    /**
     * Send Password Reset Email
     */
    suspend fun sendPasswordResetEmail(email: String): Result<Unit> {
        return try {
            auth.sendPasswordResetEmail(email.trim()).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "sendPasswordResetEmail failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    /**
     * Sign In with Google via Android Jetpack Credential Manager
     */
    suspend fun signInWithGoogle(context: Context, serverClientId: String? = null): Result<FirebaseUser> {
        return try {
            val credentialManager = CredentialManager.create(context)

            // If a server client ID is provided, use it; otherwise fallback to default Google Sign In Option
            val googleIdOption = GetSignInWithGoogleOption.Builder(
                serverClientId ?: "campusflow-default.apps.googleusercontent.com"
            )
                .build()

            val request = GetCredentialRequest.Builder()
                .addCredentialOption(googleIdOption)
                .build()

            val response: GetCredentialResponse = credentialManager.getCredential(
                request = request,
                context = context
            )

            val credential = response.credential
            if (credential is CustomCredential && credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
                val idToken = googleIdTokenCredential.idToken
                val authCredential = GoogleAuthProvider.getCredential(idToken, null)
                val authResult = auth.signInWithCredential(authCredential).await()
                val user = authResult.user ?: throw Exception("User is null after Google Auth")
                Result.success(user)
            } else {
                throw Exception("Received unexpected credential type: ${credential.type}")
            }
        } catch (e: GetCredentialCancellationException) {
            Log.d(TAG, "Google sign-in cancelled by user")
            Result.failure(Exception("Sign-in cancelled"))
        } catch (e: GetCredentialException) {
            Log.e(TAG, "CredentialManager error: ${e.localizedMessage}", e)
            Result.failure(e)
        } catch (e: Exception) {
            Log.e(TAG, "signInWithGoogle failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    /**
     * Sign Out
     */
    fun signOut() {
        auth.signOut()
    }
}
