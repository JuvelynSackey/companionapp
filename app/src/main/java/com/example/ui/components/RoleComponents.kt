package com.example.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.R
import com.example.ui.MainViewModel
import com.example.ui.NavigationTab
import com.example.ui.UserRole
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CampusTopAppBar(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val currentRole by viewModel.currentRole.collectAsState()
    val activeAlarm by viewModel.activeAlarmTrigger.collectAsState()
    val currentInstitution by viewModel.currentInstitution.collectAsState()
    val firebaseUser by viewModel.firebaseUser.collectAsState()
    var showRoleMenu by remember { mutableStateOf(false) }
    var showInstitutionSelector by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.background)
    ) {
        TopAppBar(
            navigationIcon = {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = Color.White,
                    border = androidx.compose.foundation.BorderStroke(1.dp, Slate200),
                    modifier = Modifier
                        .padding(start = 12.dp, end = 4.dp)
                        .size(40.dp)
                ) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier.padding(4.dp)
                    ) {
                        Image(
                            painter = painterResource(id = R.drawable.ic_campusflow_logo),
                            contentDescription = "CampusFlow Logo",
                            modifier = Modifier.size(32.dp)
                        )
                    }
                }
            },
            title = {
                Column(
                    modifier = Modifier.padding(vertical = 4.dp),
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = "CAMPUSFLOW • MULTI-TENANT",
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 1.2.sp
                        ),
                        color = HighDensityPurplePrimary
                    )
                    Text(
                        text = when (currentRole) {
                            UserRole.STUDENT -> if (firebaseUser != null) "Hi, ${(firebaseUser?.displayName ?: firebaseUser?.email)?.substringBefore("@")}" else "Hi, Alex"
                            UserRole.CLASS_REPRESENTATIVE -> "Class Rep Hub"
                            UserRole.ADMINISTRATOR -> "Admin Console"
                        },
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = HighDensityText
                    )
                }
            },
            actions = {
                // Firebase Auth Button / Pill
                Surface(
                    modifier = Modifier
                        .padding(end = 6.dp)
                        .clickable { viewModel.setSelectedTab(NavigationTab.SIGN_IN) }
                        .testTag("auth_top_bar_button"),
                    shape = RoundedCornerShape(20.dp),
                    color = if (firebaseUser != null) Color(0xFFDCFCE7) else Color(0xFFF1F5F9),
                    border = androidx.compose.foundation.BorderStroke(
                        1.dp,
                        if (firebaseUser != null) Color(0xFF86EFAC) else Color(0xFFCBD5E1)
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (firebaseUser != null) Icons.Filled.CheckCircle else Icons.Filled.AccountCircle,
                            contentDescription = "Firebase Auth",
                            tint = if (firebaseUser != null) Color(0xFF16A34A) else HighDensityText,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = if (firebaseUser != null) "Auth" else "Sign In",
                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                            color = if (firebaseUser != null) Color(0xFF166534) else HighDensityText
                        )
                    }
                }

                // Multi-Tenant Institution Switcher Pill
                Surface(
                    modifier = Modifier
                        .padding(end = 8.dp)
                        .clickable { showInstitutionSelector = true }
                        .testTag("institution_switcher_pill"),
                    shape = RoundedCornerShape(20.dp),
                    color = Color(currentInstitution.primaryColorHex).copy(alpha = 0.12f),
                    border = androidx.compose.foundation.BorderStroke(
                        1.dp,
                        Color(currentInstitution.primaryColorHex).copy(alpha = 0.4f)
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Surface(
                            shape = CircleShape,
                            color = Color(currentInstitution.primaryColorHex),
                            modifier = Modifier.size(20.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    text = currentInstitution.shortCode.take(2),
                                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                                    fontWeight = FontWeight.Black,
                                    color = Color.White
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = currentInstitution.shortCode,
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color(currentInstitution.primaryColorHex)
                        )
                        Icon(
                            imageVector = Icons.Filled.ArrowDropDown,
                            contentDescription = "Switch Campus",
                            tint = Color(currentInstitution.primaryColorHex),
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }

                // Role Switcher Avatar Pill
                Box {
                    Surface(
                        modifier = Modifier
                            .padding(end = 8.dp)
                            .clickable { showRoleMenu = true }
                            .testTag("role_switcher_pill"),
                        shape = CircleShape,
                        color = HighDensityLavenderContainer,
                        border = androidx.compose.foundation.BorderStroke(2.dp, Color.White),
                        shadowElevation = 2.dp
                    ) {
                        Box(
                            modifier = Modifier.size(40.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = when (currentRole) {
                                    UserRole.STUDENT -> if (firebaseUser != null) (firebaseUser?.displayName?.take(1) ?: "U").uppercase() else "A"
                                    UserRole.CLASS_REPRESENTATIVE -> "R"
                                    UserRole.ADMINISTRATOR -> "ADM"
                                },
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold,
                                color = HighDensityDeepPurple
                            )
                        }
                    }

                    DropdownMenu(
                        expanded = showRoleMenu,
                        onDismissRequest = { showRoleMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("🎓 Student (Personal Timetables & GPS)") },
                            onClick = {
                                viewModel.setRole(UserRole.STUDENT)
                                showRoleMenu = false
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("📢 Class Representative (Venue Shift Alerts)") },
                            onClick = {
                                viewModel.setRole(UserRole.CLASS_REPRESENTATIVE)
                                showRoleMenu = false
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("🏛️ Administrator (Manage Campus & Exams)") },
                            onClick = {
                                viewModel.setRole(UserRole.ADMINISTRATOR)
                                showRoleMenu = false
                            }
                        )
                        HorizontalDivider()
                        DropdownMenuItem(
                            text = {
                                Text(
                                    if (firebaseUser != null) "👤 Account (${firebaseUser?.email})" else "🔐 Firebase Sign In / Register"
                                )
                            },
                            onClick = {
                                showRoleMenu = false
                                viewModel.setSelectedTab(NavigationTab.SIGN_IN)
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("🏫 Switch Institution / University") },
                            onClick = {
                                showRoleMenu = false
                                showInstitutionSelector = true
                            }
                        )
                        if (firebaseUser != null) {
                            DropdownMenuItem(
                                text = { Text("🚪 Sign Out (Firebase)", color = Color(0xFFDC2626)) },
                                onClick = {
                                    showRoleMenu = false
                                    viewModel.signOutUser()
                                }
                            )
                        }
                    }
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = MaterialTheme.colorScheme.background
            )
        )

        if (showInstitutionSelector) {
            InstitutionSelectorDialog(
                viewModel = viewModel,
                onDismiss = { showInstitutionSelector = false }
            )
        }

        // Active Simulated Departure Alarm Banner
        activeAlarm?.let { alarmMessage ->
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("active_alarm_banner"),
                color = HighDensityRoseContainer,
                border = androidx.compose.foundation.BorderStroke(1.dp, HighDensityRoseBorder)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        modifier = Modifier.weight(1f),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Filled.AlarmOn,
                            contentDescription = null,
                            tint = HighDensityRoseText,
                            modifier = Modifier.size(22.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = alarmMessage,
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Bold,
                            color = HighDensityRoseText
                        )
                    }
                    TextButton(
                        onClick = { viewModel.dismissAlarm() },
                        colors = ButtonDefaults.textButtonColors(contentColor = HighDensityRoseText)
                    ) {
                        Text("Dismiss", fontWeight = FontWeight.Black)
                    }
                }
            }
        }
    }
}

@Composable
fun CampusBottomNavigationBar(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val selectedTab by viewModel.selectedTab.collectAsState()

    NavigationBar(
        modifier = modifier.testTag("bottom_nav_bar"),
        containerColor = HighDensityNavBg,
        tonalElevation = 2.dp
    ) {
        NavigationBarItem(
            selected = selectedTab == NavigationTab.DASHBOARD,
            onClick = { viewModel.setSelectedTab(NavigationTab.DASHBOARD) },
            icon = { Icon(Icons.Filled.Dashboard, contentDescription = "Dashboard") },
            label = { Text("Home", style = MaterialTheme.typography.labelSmall) },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = Color(0xFF1D192B),
                selectedTextColor = Color(0xFF1D192B),
                indicatorColor = HighDensityLavenderMuted,
                unselectedIconColor = HighDensityMutedText,
                unselectedTextColor = HighDensityMutedText
            )
        )
        NavigationBarItem(
            selected = selectedTab == NavigationTab.TIMETABLE,
            onClick = { viewModel.setSelectedTab(NavigationTab.TIMETABLE) },
            icon = { Icon(Icons.Filled.CalendarMonth, contentDescription = "Timetable") },
            label = { Text("Classes", style = MaterialTheme.typography.labelSmall) },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = Color(0xFF1D192B),
                selectedTextColor = Color(0xFF1D192B),
                indicatorColor = HighDensityLavenderMuted,
                unselectedIconColor = HighDensityMutedText,
                unselectedTextColor = HighDensityMutedText
            )
        )
        NavigationBarItem(
            selected = selectedTab == NavigationTab.STUDENT_HUB,
            onClick = { viewModel.setSelectedTab(NavigationTab.STUDENT_HUB) },
            icon = { Icon(Icons.Filled.Hub, contentDescription = "Student Hub") },
            label = { Text("Student Hub", style = MaterialTheme.typography.labelSmall) },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = Color(0xFF1D192B),
                selectedTextColor = Color(0xFF1D192B),
                indicatorColor = HighDensityLavenderMuted,
                unselectedIconColor = HighDensityMutedText,
                unselectedTextColor = HighDensityMutedText
            )
        )
        NavigationBarItem(
            selected = selectedTab == NavigationTab.MAP_NAV,
            onClick = { viewModel.setSelectedTab(NavigationTab.MAP_NAV) },
            icon = { Icon(Icons.Filled.Explore, contentDescription = "Map") },
            label = { Text("Map & ETA", style = MaterialTheme.typography.labelSmall) },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = Color(0xFF1D192B),
                selectedTextColor = Color(0xFF1D192B),
                indicatorColor = HighDensityLavenderMuted,
                unselectedIconColor = HighDensityMutedText,
                unselectedTextColor = HighDensityMutedText
            )
        )
        NavigationBarItem(
            selected = selectedTab == NavigationTab.AI_ASSISTANT,
            onClick = { viewModel.setSelectedTab(NavigationTab.AI_ASSISTANT) },
            icon = { Icon(Icons.Filled.SmartToy, contentDescription = "Assistant") },
            label = { Text("AI Advisor", style = MaterialTheme.typography.labelSmall) },
            colors = NavigationBarItemDefaults.colors(
                selectedIconColor = Color(0xFF1D192B),
                selectedTextColor = Color(0xFF1D192B),
                indicatorColor = HighDensityLavenderMuted,
                unselectedIconColor = HighDensityMutedText,
                unselectedTextColor = HighDensityMutedText
            )
        )
    }
}
