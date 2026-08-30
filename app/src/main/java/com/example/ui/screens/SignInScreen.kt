package com.example.ui.screens

import android.widget.Toast
import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.R
import com.example.data.auth.AuthResultState
import com.example.data.model.InstitutionProfile
import com.example.ui.MainViewModel
import com.example.ui.NavigationTab
import com.example.ui.theme.*

enum class AuthMode {
    SIGN_IN,
    SIGN_UP
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignInScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier,
    onNavigateBack: (() -> Unit)? = null,
    onAuthSuccess: (() -> Unit)? = null
) {
    val context = LocalContext.current
    val focusManager = LocalFocusManager.current
    val scrollState = rememberScrollState()

    val currentInstitution by viewModel.currentInstitution.collectAsState()
    val firebaseUser by viewModel.firebaseUser.collectAsState()
    val authUiState by viewModel.authUiState.collectAsState()

    var authMode by remember { mutableStateOf(AuthMode.SIGN_IN) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var showForgotPasswordDialog by remember { mutableStateOf(false) }
    var resetEmailInput by remember { mutableStateOf("") }

    val isLoading = authUiState is AuthResultState.Loading

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Slate50)
            .verticalScroll(scrollState)
    ) {
        // Top Bar / Navigation Header
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = Color.White,
            shadowElevation = 1.dp
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (onNavigateBack != null) {
                        IconButton(
                            onClick = onNavigateBack,
                            modifier = Modifier.testTag("sign_in_back_button")
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = "Back",
                                tint = HighDensityText
                            )
                        }
                    } else {
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = Color(currentInstitution.primaryColorHex).copy(alpha = 0.12f),
                            modifier = Modifier.size(36.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icons.Filled.Lock,
                                    contentDescription = null,
                                    tint = Color(currentInstitution.primaryColorHex),
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(10.dp))
                    }
                    Text(
                        text = if (firebaseUser != null) "Account & Security" else "Firebase Authentication",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = HighDensityText
                    )
                }

                // Current University Badge
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = Color(currentInstitution.primaryColorHex).copy(alpha = 0.1f),
                    border = BorderStroke(1.dp, Color(currentInstitution.primaryColorHex).copy(alpha = 0.3f))
                ) {
                    Text(
                        text = currentInstitution.shortCode,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontWeight = FontWeight.Bold,
                            fontSize = 11.sp
                        ),
                        color = Color(currentInstitution.primaryColorHex)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Main Card Container
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (firebaseUser != null) {
                // User is already signed in
                SignedInProfileCard(
                    user = firebaseUser!!,
                    institution = currentInstitution,
                    viewModel = viewModel,
                    onSignOut = { viewModel.signOutUser() },
                    onContinue = {
                        onAuthSuccess?.invoke() ?: viewModel.setSelectedTab(NavigationTab.DASHBOARD)
                    }
                )
            } else {
                // Sign In / Sign Up Form Card
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("auth_form_card"),
                    shape = RoundedCornerShape(24.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    border = BorderStroke(1.dp, Slate200),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // University Crest / Logo Icon Header
                        Surface(
                            shape = CircleShape,
                            color = Color(currentInstitution.primaryColorHex).copy(alpha = 0.12f),
                            modifier = Modifier.size(64.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icons.Filled.School,
                                    contentDescription = null,
                                    tint = Color(currentInstitution.primaryColorHex),
                                    modifier = Modifier.size(36.dp)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Text(
                            text = if (authMode == AuthMode.SIGN_IN) "Welcome Back" else "Create Campus Account",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = HighDensityText,
                            textAlign = TextAlign.Center
                        )

                        Text(
                            text = if (authMode == AuthMode.SIGN_IN) {
                                "Sign in with your student email to sync timetable & grades"
                            } else {
                                "Register your official ${currentInstitution.shortCode} student credentials"
                            },
                            style = MaterialTheme.typography.bodySmall,
                            color = HighDensityMutedText,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(horizontal = 8.dp)
                        )

                        Spacer(modifier = Modifier.height(20.dp))

                        // Auth Mode Segmented Switcher
                        Surface(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp),
                            color = Slate100
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(4.dp)
                            ) {
                                Surface(
                                    modifier = Modifier
                                        .weight(1f)
                                        .clickable {
                                            authMode = AuthMode.SIGN_IN
                                            viewModel.resetAuthUiState()
                                        }
                                        .testTag("sign_in_tab"),
                                    shape = RoundedCornerShape(10.dp),
                                    color = if (authMode == AuthMode.SIGN_IN) Color.White else Color.Transparent,
                                    shadowElevation = if (authMode == AuthMode.SIGN_IN) 2.dp else 0.dp
                                ) {
                                    Text(
                                        text = "Sign In",
                                        modifier = Modifier.padding(vertical = 10.dp),
                                        style = MaterialTheme.typography.bodyMedium.copy(
                                            fontWeight = if (authMode == AuthMode.SIGN_IN) FontWeight.Bold else FontWeight.Medium
                                        ),
                                        color = if (authMode == AuthMode.SIGN_IN) Color(currentInstitution.primaryColorHex) else HighDensityMutedText,
                                        textAlign = TextAlign.Center
                                    )
                                }

                                Surface(
                                    modifier = Modifier
                                        .weight(1f)
                                        .clickable {
                                            authMode = AuthMode.SIGN_UP
                                            viewModel.resetAuthUiState()
                                        }
                                        .testTag("sign_up_tab"),
                                    shape = RoundedCornerShape(10.dp),
                                    color = if (authMode == AuthMode.SIGN_UP) Color.White else Color.Transparent,
                                    shadowElevation = if (authMode == AuthMode.SIGN_UP) 2.dp else 0.dp
                                ) {
                                    Text(
                                        text = "Create Account",
                                        modifier = Modifier.padding(vertical = 10.dp),
                                        style = MaterialTheme.typography.bodyMedium.copy(
                                            fontWeight = if (authMode == AuthMode.SIGN_UP) FontWeight.Bold else FontWeight.Medium
                                        ),
                                        color = if (authMode == AuthMode.SIGN_UP) Color(currentInstitution.primaryColorHex) else HighDensityMutedText,
                                        textAlign = TextAlign.Center
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(20.dp))

                        // Error Banner if state is error
                        if (authUiState is AuthResultState.Error) {
                            val errorMsg = (authUiState as AuthResultState.Error).message
                            Surface(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(bottom = 16.dp)
                                    .testTag("auth_error_banner"),
                                shape = RoundedCornerShape(12.dp),
                                color = Color(0xFFFEF2F2),
                                border = BorderStroke(1.dp, Color(0xFFFCA5A5))
                            ) {
                                Row(
                                    modifier = Modifier.padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = Icons.Filled.ErrorOutline,
                                        contentDescription = null,
                                        tint = Color(0xFFDC2626),
                                        modifier = Modifier.size(20.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = errorMsg,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color(0xFF991B1B),
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }
                        }

                        // Display Name Input (Only for Sign Up)
                        AnimatedVisibility(
                            visible = authMode == AuthMode.SIGN_UP,
                            enter = fadeIn() + expandVertically(),
                            exit = fadeOut() + shrinkVertically()
                        ) {
                            Column(modifier = Modifier.fillMaxWidth()) {
                                OutlinedTextField(
                                    value = displayName,
                                    onValueChange = { displayName = it },
                                    label = { Text("Full Name") },
                                    placeholder = { Text("e.g. Kwesi Mensah") },
                                    leadingIcon = {
                                        Icon(Icons.Filled.Person, contentDescription = null, tint = HighDensityMutedText)
                                    },
                                    singleLine = true,
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .testTag("name_input"),
                                    shape = RoundedCornerShape(12.dp),
                                    keyboardOptions = KeyboardOptions(
                                        keyboardType = KeyboardType.Text,
                                        imeAction = ImeAction.Next
                                    ),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = Color(currentInstitution.primaryColorHex),
                                        focusedLabelColor = Color(currentInstitution.primaryColorHex)
                                    )
                                )
                                Spacer(modifier = Modifier.height(14.dp))
                            }
                        }

                        // Email Input
                        OutlinedTextField(
                            value = email,
                            onValueChange = { email = it },
                            label = { Text("Email Address") },
                            placeholder = { Text("student@st.${currentInstitution.shortCode.lowercase()}.edu.gh") },
                            leadingIcon = {
                                Icon(Icons.Filled.Email, contentDescription = null, tint = HighDensityMutedText)
                            },
                            singleLine = true,
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("email_input"),
                            shape = RoundedCornerShape(12.dp),
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Email,
                                imeAction = ImeAction.Next
                            ),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = Color(currentInstitution.primaryColorHex),
                                focusedLabelColor = Color(currentInstitution.primaryColorHex)
                            )
                        )

                        Spacer(modifier = Modifier.height(14.dp))

                        // Password Input
                        OutlinedTextField(
                            value = password,
                            onValueChange = { password = it },
                            label = { Text("Password") },
                            placeholder = { Text("••••••••") },
                            leadingIcon = {
                                Icon(Icons.Filled.Lock, contentDescription = null, tint = HighDensityMutedText)
                            },
                            trailingIcon = {
                                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                                    Icon(
                                        imageVector = if (passwordVisible) Icons.Filled.VisibilityOff else Icons.Filled.Visibility,
                                        contentDescription = if (passwordVisible) "Hide password" else "Show password",
                                        tint = HighDensityMutedText
                                    )
                                }
                            },
                            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                            singleLine = true,
                            modifier = Modifier
                                .fillMaxWidth()
                                .testTag("password_input"),
                            shape = RoundedCornerShape(12.dp),
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Password,
                                imeAction = if (authMode == AuthMode.SIGN_IN) ImeAction.Done else ImeAction.Next
                            ),
                            keyboardActions = KeyboardActions(
                                onDone = {
                                    focusManager.clearFocus()
                                    if (authMode == AuthMode.SIGN_IN) {
                                        viewModel.signInWithEmail(email, password) {
                                            onAuthSuccess?.invoke()
                                        }
                                    }
                                }
                            ),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = Color(currentInstitution.primaryColorHex),
                                focusedLabelColor = Color(currentInstitution.primaryColorHex)
                            )
                        )

                        // Confirm Password (Sign Up only)
                        AnimatedVisibility(
                            visible = authMode == AuthMode.SIGN_UP,
                            enter = fadeIn() + expandVertically(),
                            exit = fadeOut() + shrinkVertically()
                        ) {
                            Column(modifier = Modifier.fillMaxWidth()) {
                                Spacer(modifier = Modifier.height(14.dp))
                                OutlinedTextField(
                                    value = confirmPassword,
                                    onValueChange = { confirmPassword = it },
                                    label = { Text("Confirm Password") },
                                    placeholder = { Text("••••••••") },
                                    leadingIcon = {
                                        Icon(Icons.Filled.Lock, contentDescription = null, tint = HighDensityMutedText)
                                    },
                                    visualTransformation = PasswordVisualTransformation(),
                                    singleLine = true,
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .testTag("confirm_password_input"),
                                    shape = RoundedCornerShape(12.dp),
                                    keyboardOptions = KeyboardOptions(
                                        keyboardType = KeyboardType.Password,
                                        imeAction = ImeAction.Done
                                    ),
                                    keyboardActions = KeyboardActions(
                                        onDone = {
                                            focusManager.clearFocus()
                                            if (password != confirmPassword) {
                                                Toast.makeText(context, "Passwords do not match", Toast.LENGTH_SHORT).show()
                                            } else {
                                                viewModel.signUpWithEmail(email, password, displayName) {
                                                    onAuthSuccess?.invoke()
                                                }
                                            }
                                        }
                                    ),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = Color(currentInstitution.primaryColorHex),
                                        focusedLabelColor = Color(currentInstitution.primaryColorHex)
                                    )
                                )
                            }
                        }

                        // Forgot Password Link (Sign In only)
                        if (authMode == AuthMode.SIGN_IN) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 4.dp),
                                contentAlignment = Alignment.CenterEnd
                            ) {
                                TextButton(
                                    onClick = {
                                        resetEmailInput = email
                                        showForgotPasswordDialog = true
                                    },
                                    contentPadding = PaddingValues(horizontal = 4.dp, vertical = 2.dp)
                                ) {
                                    Text(
                                        text = "Forgot password?",
                                        style = MaterialTheme.typography.bodySmall,
                                        fontWeight = FontWeight.SemiBold,
                                        color = Color(currentInstitution.primaryColorHex)
                                    )
                                }
                            }
                        } else {
                            Spacer(modifier = Modifier.height(14.dp))
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        // Submit Primary Button
                        Button(
                            onClick = {
                                focusManager.clearFocus()
                                if (authMode == AuthMode.SIGN_IN) {
                                    viewModel.signInWithEmail(email, password) {
                                        onAuthSuccess?.invoke()
                                    }
                                } else {
                                    if (password != confirmPassword) {
                                        Toast.makeText(context, "Passwords do not match", Toast.LENGTH_SHORT).show()
                                    } else {
                                        viewModel.signUpWithEmail(email, password, displayName) {
                                            onAuthSuccess?.invoke()
                                        }
                                    }
                                }
                            },
                            enabled = !isLoading,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(50.dp)
                                .testTag("submit_auth_button"),
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color(currentInstitution.primaryColorHex)
                            )
                        ) {
                            if (isLoading) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(22.dp),
                                    color = Color.White,
                                    strokeWidth = 2.5.dp
                                )
                            } else {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Text(
                                        text = if (authMode == AuthMode.SIGN_IN) "Sign In" else "Create Account",
                                        style = MaterialTheme.typography.bodyLarge,
                                        fontWeight = FontWeight.Bold
                                    )
                                    Icon(
                                        imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                                        contentDescription = null,
                                        modifier = Modifier.size(18.dp)
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(20.dp))

                        // Divider with OR
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            HorizontalDivider(modifier = Modifier.weight(1f), color = Slate200)
                            Text(
                                text = "OR",
                                modifier = Modifier.padding(horizontal = 12.dp),
                                style = MaterialTheme.typography.labelSmall,
                                color = HighDensityMutedText,
                                fontWeight = FontWeight.Bold
                            )
                            HorizontalDivider(modifier = Modifier.weight(1f), color = Slate200)
                        }

                        Spacer(modifier = Modifier.height(20.dp))

                        // Google Sign-In Button (Credential Manager)
                        OutlinedButton(
                            onClick = {
                                viewModel.signInWithGoogle(context) {
                                    onAuthSuccess?.invoke()
                                }
                            },
                            enabled = !isLoading,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(50.dp)
                                .testTag("google_sign_in_button"),
                            shape = RoundedCornerShape(12.dp),
                            border = BorderStroke(1.dp, Slate300),
                            colors = ButtonDefaults.outlinedButtonColors(containerColor = Color.White)
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Center
                            ) {
                                // Google Color Icon
                                Surface(
                                    shape = CircleShape,
                                    color = Color(0xFF4285F4),
                                    modifier = Modifier.size(22.dp)
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Text(
                                            text = "G",
                                            style = MaterialTheme.typography.labelMedium.copy(
                                                fontWeight = FontWeight.Black,
                                                color = Color.White
                                            )
                                        )
                                    }
                                }
                                Spacer(modifier = Modifier.width(10.dp))
                                Text(
                                    text = "Continue with Google",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = HighDensityText
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Guest / Skip Option
                TextButton(
                    onClick = {
                        viewModel.setSelectedTab(NavigationTab.DASHBOARD)
                    },
                    modifier = Modifier.testTag("skip_auth_button")
                ) {
                    Text(
                        text = "Continue as Guest (Offline Mode)",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = HighDensityMutedText
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }

    // Forgot Password Dialog
    if (showForgotPasswordDialog) {
        Dialog(onDismissRequest = { showForgotPasswordDialog = false }) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text(
                        text = "Reset Password",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = HighDensityText
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "Enter your registered student email address. We will send you instructions to reset your password.",
                        style = MaterialTheme.typography.bodySmall,
                        color = HighDensityMutedText
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    OutlinedTextField(
                        value = resetEmailInput,
                        onValueChange = { resetEmailInput = it },
                        label = { Text("Email Address") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp)
                    )
                    Spacer(modifier = Modifier.height(20.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        TextButton(onClick = { showForgotPasswordDialog = false }) {
                            Text("Cancel")
                        }
                        Spacer(modifier = Modifier.width(8.dp))
                        Button(
                            onClick = {
                                viewModel.sendPasswordReset(resetEmailInput)
                                showForgotPasswordDialog = false
                            },
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Color(currentInstitution.primaryColorHex)
                            )
                        ) {
                            Text("Send Reset Link", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun SignedInProfileCard(
    user: com.google.firebase.auth.FirebaseUser,
    institution: InstitutionProfile,
    viewModel: MainViewModel,
    onSignOut: () -> Unit,
    onContinue: () -> Unit
) {
    val isSyncing by viewModel.isCloudSyncing.collectAsState()

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("signed_in_profile_card"),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = BorderStroke(1.dp, Slate200),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Profile Avatar
            Surface(
                shape = CircleShape,
                color = Color(0xFF10B981).copy(alpha = 0.15f),
                border = BorderStroke(2.dp, Color(0xFF10B981)),
                modifier = Modifier.size(72.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Filled.CheckCircle,
                        contentDescription = null,
                        tint = Color(0xFF10B981),
                        modifier = Modifier.size(44.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            Surface(
                shape = RoundedCornerShape(12.dp),
                color = Color(0xFFDCFCE7)
            ) {
                Text(
                    text = "Authenticated via Firebase",
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                    style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                    color = Color(0xFF15803D)
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            Text(
                text = user.displayName ?: "Campus Student",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = HighDensityText
            )

            Text(
                text = user.email ?: "student@campusflow.gh",
                style = MaterialTheme.typography.bodyMedium,
                color = HighDensityMutedText
            )

            Spacer(modifier = Modifier.height(16.dp))

            // User Info Breakdown
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                color = Slate50,
                border = BorderStroke(1.dp, Slate200)
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Institution:", style = MaterialTheme.typography.bodySmall, color = HighDensityMutedText)
                        Text(institution.name, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold, color = HighDensityText)
                    }
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Firebase UID:", style = MaterialTheme.typography.bodySmall, color = HighDensityMutedText)
                        Text(
                            text = user.uid.take(12) + "...",
                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                            fontWeight = FontWeight.Medium,
                            color = HighDensityText
                        )
                    }
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Firestore Sync:", style = MaterialTheme.typography.bodySmall, color = HighDensityMutedText)
                        Text(
                            text = if (isSyncing) "Syncing..." else "Real-time Active",
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Bold,
                            color = if (isSyncing) Color(0xFFEAB308) else Color(0xFF16A34A)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Manual Sync Button
            OutlinedButton(
                onClick = { viewModel.syncAllToFirestore() },
                enabled = !isSyncing,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(46.dp)
                    .testTag("firestore_sync_button"),
                shape = RoundedCornerShape(12.dp),
                border = BorderStroke(1.dp, Color(institution.primaryColorHex).copy(alpha = 0.5f)),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(institution.primaryColorHex))
            ) {
                if (isSyncing) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp,
                        color = Color(institution.primaryColorHex)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Syncing with Firestore...", fontWeight = FontWeight.SemiBold)
                } else {
                    Icon(Icons.Filled.CloudSync, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Sync Data with Firestore Cloud", fontWeight = FontWeight.Bold)
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Action Buttons
            Button(
                onClick = onContinue,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
                    .testTag("continue_to_dashboard_button"),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(institution.primaryColorHex))
            ) {
                Text("Go to Dashboard", fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.width(8.dp))
                Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, modifier = Modifier.size(18.dp))
            }

            Spacer(modifier = Modifier.height(10.dp))

            OutlinedButton(
                onClick = onSignOut,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
                    .testTag("sign_out_button"),
                shape = RoundedCornerShape(12.dp),
                border = BorderStroke(1.dp, Color(0xFFFCA5A5)),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFDC2626))
            ) {
                Icon(Icons.Filled.Logout, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Sign Out", fontWeight = FontWeight.Bold)
            }
        }
    }
}
