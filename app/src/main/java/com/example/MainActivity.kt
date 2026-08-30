package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.animation.Crossfade
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.example.data.worker.CampusAlertNotificationHelper
import com.example.data.worker.ClassReminderNotificationHelper
import com.example.ui.MainViewModel
import com.example.ui.NavigationTab
import com.example.ui.components.CampusBottomNavigationBar
import com.example.ui.components.CampusTopAppBar
import com.example.ui.screens.AlertsScreen
import com.example.ui.screens.AnalyticsScreen
import com.example.ui.screens.AssistantScreen
import com.example.ui.screens.DashboardScreen
import com.example.ui.screens.ExamsScreen
import com.example.ui.screens.InstitutionPickerScreen
import com.example.ui.screens.NavigationScreen
import com.example.ui.screens.ResourcesScreen
import com.example.ui.screens.SignInScreen
import com.example.ui.screens.StudentHubScreen
import com.example.ui.screens.TimetableScreen
import com.example.ui.theme.MyApplicationTheme

class MainActivity : ComponentActivity() {

    private val viewModel: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        // Initialize notification channels
        ClassReminderNotificationHelper.createNotificationChannel(this)
        CampusAlertNotificationHelper.createNotificationChannel(this)

        setContent {
            MyApplicationTheme {
                CampusAppRoot(viewModel = viewModel)
            }
        }
    }
}

@Composable
fun CampusAppRoot(viewModel: MainViewModel) {
    val isOnboardingCompleted by viewModel.isOnboardingCompleted.collectAsState()

    Crossfade(targetState = isOnboardingCompleted, label = "OnboardingCrossfade") { isCompleted ->
        when (isCompleted) {
            null -> {
                // Loading state while DataStore initial read completes
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
            }
            false -> {
                // First-time institution selection screen
                InstitutionPickerScreen(viewModel = viewModel)
            }
            true -> {
                // Main Multi-Tenant Campus App UI
                CampusCompanionApp(viewModel = viewModel)
            }
        }
    }
}

@Composable
fun CampusCompanionApp(viewModel: MainViewModel) {
    val selectedTab by viewModel.selectedTab.collectAsState()

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = { CampusTopAppBar(viewModel = viewModel) },
        bottomBar = { CampusBottomNavigationBar(viewModel = viewModel) }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when (selectedTab) {
                NavigationTab.DASHBOARD -> DashboardScreen(viewModel = viewModel)
                NavigationTab.TIMETABLE -> TimetableScreen(viewModel = viewModel)
                NavigationTab.STUDENT_HUB -> StudentHubScreen(viewModel = viewModel)
                NavigationTab.EXAMS -> ExamsScreen(viewModel = viewModel)
                NavigationTab.MAP_NAV -> NavigationScreen(viewModel = viewModel)
                NavigationTab.ALERTS -> AlertsScreen(viewModel = viewModel)
                NavigationTab.ANALYTICS -> AnalyticsScreen(viewModel = viewModel)
                NavigationTab.RESOURCES -> ResourcesScreen(viewModel = viewModel)
                NavigationTab.LIBRARIES -> ResourcesScreen(viewModel = viewModel)
                NavigationTab.AI_ASSISTANT -> AssistantScreen(viewModel = viewModel)
                NavigationTab.SIGN_IN -> SignInScreen(
                    viewModel = viewModel,
                    onNavigateBack = { viewModel.setSelectedTab(NavigationTab.DASHBOARD) },
                    onAuthSuccess = { viewModel.setSelectedTab(NavigationTab.DASHBOARD) }
                )
            }
        }
    }
}
