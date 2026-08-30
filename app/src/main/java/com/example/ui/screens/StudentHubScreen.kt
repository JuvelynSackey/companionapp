package com.example.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.data.model.*
import com.example.ui.MainViewModel
import com.example.ui.NavigationTab
import com.example.ui.theme.*

enum class StudentHubTab(val title: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    SHUTTLES("Shuttles & Trotros", Icons.Filled.DirectionsBus),
    MOMO_DUES("MoMo Dues & Fees", Icons.Filled.Payments),
    LOST_AND_FOUND("Lost & Found", Icons.Filled.Search),
    EVENTS("Campus Events", Icons.Filled.ConfirmationNumber),
    PORTALS("Student Portals", Icons.Filled.Language),
    STUDENT_ID("Digital ID Card", Icons.Filled.Badge)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StudentHubScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier,
    initialTab: StudentHubTab = StudentHubTab.SHUTTLES
) {
    var selectedSubTab by remember { mutableStateOf(initialTab) }
    val currentInstitution by viewModel.currentInstitution.collectAsState()
    val studentProfile by viewModel.studentProfile.collectAsState()
    val shuttleRoutes by viewModel.shuttleRoutes.collectAsState()
    val campusDues by viewModel.campusDues.collectAsState()
    val lostAndFoundItems by viewModel.lostAndFoundItems.collectAsState()
    val campusEvents by viewModel.campusEvents.collectAsState()
    val isProcessingPayment by viewModel.isProcessingPayment.collectAsState()
    val lastReceipt by viewModel.lastPaymentReceipt.collectAsState()

    var dueToPay by remember { mutableStateOf<CampusDueItem?>(null) }
    var showReportDialog by remember { mutableStateOf(false) }
    var showEditProfileDialog by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Slate50)
    ) {
        // Top Header Banner
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = Color.White,
            shadowElevation = 1.dp
        ) {
            Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "🇬🇭 GHANA CAMPUS COMPANION",
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 11.sp,
                                    letterSpacing = 1.sp
                                ),
                                color = Color(currentInstitution.primaryColorHex)
                            )
                        }
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = "Student Life & Services Hub",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = HighDensityText
                        )
                    }

                    // Mini Student Avatar / Badge
                    Surface(
                        modifier = Modifier
                            .size(42.dp)
                            .clickable { selectedSubTab = StudentHubTab.STUDENT_ID },
                        shape = CircleShape,
                        color = Color(currentInstitution.primaryColorHex).copy(alpha = 0.15f),
                        border = BorderStroke(1.5.dp, Color(currentInstitution.primaryColorHex))
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Filled.AccountCircle,
                                contentDescription = "Student Profile",
                                tint = Color(currentInstitution.primaryColorHex),
                                modifier = Modifier.size(28.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Scrollable Sub-Tabs
                ScrollableTabRow(
                    selectedTabIndex = selectedSubTab.ordinal,
                    edgePadding = 0.dp,
                    containerColor = Color.Transparent,
                    contentColor = Color(currentInstitution.primaryColorHex),
                    divider = {}
                ) {
                    StudentHubTab.values().forEach { tab ->
                        val isSelected = selectedSubTab == tab
                        Tab(
                            selected = isSelected,
                            onClick = { selectedSubTab = tab },
                            text = {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(
                                        imageVector = tab.icon,
                                        contentDescription = null,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Text(
                                        text = tab.title,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                        fontSize = 13.sp
                                    )
                                }
                            }
                        )
                    }
                }
            }
        }

        // Active Tab Content
        Box(
            modifier = Modifier
                .fillMaxSize()
                .weight(1f)
        ) {
            when (selectedSubTab) {
                StudentHubTab.SHUTTLES -> {
                    ShuttleTrackerSection(
                        shuttles = shuttleRoutes,
                        institution = currentInstitution,
                        onRefresh = { viewModel.refreshShuttles() }
                    )
                }
                StudentHubTab.MOMO_DUES -> {
                    MoMoDuesSection(
                        dues = campusDues,
                        studentProfile = studentProfile,
                        institution = currentInstitution,
                        onPayClick = { dueToPay = it }
                    )
                }
                StudentHubTab.LOST_AND_FOUND -> {
                    LostAndFoundSection(
                        items = lostAndFoundItems,
                        institution = currentInstitution,
                        onReportClick = { showReportDialog = true },
                        onClaimClick = { viewModel.markLostAndFoundItemClaimed(it.id) }
                    )
                }
                StudentHubTab.EVENTS -> {
                    EventsAndPassesSection(
                        events = campusEvents,
                        institution = currentInstitution,
                        onToggleRsvp = { viewModel.toggleEventRsvp(it.id) }
                    )
                }
                StudentHubTab.PORTALS -> {
                    PortalsGatewaySection(institution = currentInstitution)
                }
                StudentHubTab.STUDENT_ID -> {
                    DigitalStudentIdSection(
                        profile = studentProfile,
                        institution = currentInstitution,
                        viewModel = viewModel,
                        onEditClick = { showEditProfileDialog = true }
                    )
                }
            }
        }
    }

    // MoMo Payment Dialog
    dueToPay?.let { due ->
        MoMoPaymentDialog(
            due = due,
            studentProfile = studentProfile,
            institution = currentInstitution,
            isProcessing = isProcessingPayment,
            onConfirm = { momoNum, provider ->
                viewModel.payCampusDue(due.id, momoNum, provider)
                dueToPay = null
            },
            onDismiss = { dueToPay = null }
        )
    }

    // MoMo Receipt Modal Dialog
    lastReceipt?.let { receipt ->
        MoMoReceiptDialog(
            receipt = receipt,
            institution = currentInstitution,
            onDismiss = { viewModel.clearLastReceipt() }
        )
    }

    // Report Lost/Found Dialog
    if (showReportDialog) {
        ReportLostFoundDialog(
            institution = currentInstitution,
            studentProfile = studentProfile,
            onSubmit = { newItem ->
                viewModel.reportLostAndFoundItem(newItem)
                showReportDialog = false
            },
            onDismiss = { showReportDialog = false }
        )
    }

    // Edit Profile Dialog
    if (showEditProfileDialog) {
        EditStudentProfileDialog(
            currentProfile = studentProfile,
            onSave = { updated ->
                viewModel.updateStudentProfile(updated)
                showEditProfileDialog = false
            },
            onDismiss = { showEditProfileDialog = false }
        )
    }
}

// ------------------------------------------------------------------------------------------------
// SECTION 1: SHUTTLE & TROTRO TRACKER
// ------------------------------------------------------------------------------------------------
@Composable
fun ShuttleTrackerSection(
    shuttles: List<CampusShuttleRoute>,
    institution: InstitutionProfile,
    onRefresh: () -> Unit
) {
    val context = LocalContext.current

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            // Live Status Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = BorderStroke(1.dp, Slate200)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Surface(
                            shape = CircleShape,
                            color = Color(0xFF10B981).copy(alpha = 0.15f),
                            modifier = Modifier.size(44.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icons.Filled.Sensors,
                                    contentDescription = null,
                                    tint = Color(0xFF10B981),
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }
                        Column {
                            Text(
                                text = "Live Shuttle GPS Feeds",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = HighDensityText
                            )
                            Text(
                                text = "${shuttles.size} campus routes active on ${institution.shortCode}",
                                style = MaterialTheme.typography.bodySmall,
                                color = HighDensityMutedText
                            )
                        }
                    }

                    FilledTonalButton(
                        onClick = onRefresh,
                        shape = RoundedCornerShape(10.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Refresh,
                            contentDescription = "Refresh",
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Update", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        items(shuttles, key = { it.id }) { shuttle ->
            ShuttleCard(shuttle = shuttle, institution = institution, onCallDriver = { phone ->
                val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$phone"))
                context.startActivity(intent)
            })
        }
    }
}

@Composable
fun ShuttleCard(
    shuttle: CampusShuttleRoute,
    institution: InstitutionProfile,
    onCallDriver: (String) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        border = BorderStroke(1.dp, Slate200)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Route Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = Color(institution.primaryColorHex),
                        modifier = Modifier.padding(vertical = 2.dp)
                    ) {
                        Text(
                            text = shuttle.routeCode,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelMedium.copy(
                                fontWeight = FontWeight.Black,
                                color = Color.White
                            )
                        )
                    }
                    Text(
                        text = "GH₵ ${String.format("%.2f", shuttle.fareCedis)}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF047857)
                    )
                }

                // Next Arrival Pill
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = if (shuttle.nextArrivalMinutes <= 3) Color(0xFFFEF2F2) else Color(0xFFF0FDF4),
                    border = BorderStroke(
                        1.dp,
                        if (shuttle.nextArrivalMinutes <= 3) Color(0xFFF87171) else Color(0xFF86EFAC)
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.AccessTime,
                            contentDescription = null,
                            tint = if (shuttle.nextArrivalMinutes <= 3) Color(0xFFDC2626) else Color(0xFF16A34A),
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            text = if (shuttle.nextArrivalMinutes <= 2) "Arriving Now" else "in ${shuttle.nextArrivalMinutes} mins",
                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                            color = if (shuttle.nextArrivalMinutes <= 3) Color(0xFFDC2626) else Color(0xFF16A34A)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            Text(
                text = shuttle.routeName,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = HighDensityText
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Origin -> Destination Stop Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Filled.TripOrigin,
                    contentDescription = null,
                    tint = Color(institution.primaryColorHex),
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = shuttle.fromStop,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = HighDensityText
                )
                Spacer(modifier = Modifier.width(8.dp))
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = null,
                    tint = HighDensityMutedText,
                    modifier = Modifier.size(14.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Icon(
                    imageVector = Icons.Filled.LocationOn,
                    contentDescription = null,
                    tint = Color(0xFFDC2626),
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = shuttle.toStop,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = HighDensityText
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Via Stops Chips
            Text(
                text = "Key Stops: ${shuttle.viaStops.joinToString(" • ")}",
                style = MaterialTheme.typography.bodySmall,
                color = HighDensityMutedText,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(12.dp))
            HorizontalDivider(color = Slate100)
            Spacer(modifier = Modifier.height(12.dp))

            // Driver & Seat Availability Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Filled.AirlineSeatReclineNormal,
                            contentDescription = null,
                            tint = if (shuttle.seatsAvailable <= 5) Color(0xFFDC2626) else Color(0xFF047857),
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "${shuttle.seatsAvailable} seats left (${shuttle.totalSeats - shuttle.seatsAvailable}/${shuttle.totalSeats} onboard)",
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Medium,
                            color = HighDensityText
                        )
                    }
                    Text(
                        text = "Bus: ${shuttle.busNumberPlate} • ${shuttle.driverName}",
                        style = MaterialTheme.typography.labelSmall,
                        color = HighDensityMutedText
                    )
                }

                OutlinedButton(
                    onClick = { onCallDriver(shuttle.driverPhone) },
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                    border = BorderStroke(1.dp, Slate300)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Call,
                        contentDescription = "Call Driver",
                        modifier = Modifier.size(16.dp),
                        tint = Color(institution.primaryColorHex)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Call Driver",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(institution.primaryColorHex)
                    )
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------------------------
// SECTION 2: MOMO DUES & FEES
// ------------------------------------------------------------------------------------------------
@Composable
fun MoMoDuesSection(
    dues: List<CampusDueItem>,
    studentProfile: StudentProfile,
    institution: InstitutionProfile,
    onPayClick: (CampusDueItem) -> Unit
) {
    val totalUnpaid = dues.filter { !it.isPaid }.sumOf { it.amountCedis }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            // Outstanding Dues Banner
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1B4B))
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(18.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "OFFICIAL CAMPUS DUES",
                            style = MaterialTheme.typography.labelSmall.copy(
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 1.sp
                            ),
                            color = Color(0xFFFCD34D)
                        )
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = Color.White.copy(alpha = 0.15f)
                        ) {
                            Text(
                                text = "MoMo Instant Clearing",
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelSmall,
                                color = Color.White
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Text(
                        text = "GH₵ ${String.format("%.2f", totalUnpaid)}",
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Black,
                        color = Color.White
                    )

                    Text(
                        text = "Total Outstanding for ${studentProfile.level} • ${studentProfile.program}",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.8f)
                    )

                    Spacer(modifier = Modifier.height(14.dp))

                    Row(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        MoMoProviderPill(name = "MTN MoMo", color = Color(0xFFF59E0B))
                        MoMoProviderPill(name = "Telecel Cash", color = Color(0xFFE11D48))
                        MoMoProviderPill(name = "AT Money", color = Color(0xFF0284C7))
                    }
                }
            }
        }

        item {
            Text(
                text = "Departmental, Hall & Statutory Dues",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = HighDensityText
            )
        }

        items(dues, key = { it.id }) { due ->
            DueItemCard(due = due, institution = institution, onPayClick = { onPayClick(due) })
        }
    }
}

@Composable
fun MoMoProviderPill(name: String, color: Color) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = color.copy(alpha = 0.25f),
        border = BorderStroke(1.dp, color.copy(alpha = 0.6f))
    ) {
        Text(
            text = name,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
            color = Color.White
        )
    }
}

@Composable
fun DueItemCard(
    due: CampusDueItem,
    institution: InstitutionProfile,
    onPayClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = BorderStroke(1.dp, if (due.isPaid) Color(0xFF86EFAC) else Slate200)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = if (due.isPaid) Color(0xFFF0FDF4) else Color(institution.primaryColorHex).copy(alpha = 0.1f)
                ) {
                    Text(
                        text = due.category,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = if (due.isPaid) Color(0xFF047857) else Color(institution.primaryColorHex)
                    )
                }

                Text(
                    text = "GH₵ ${String.format("%.2f", due.amountCedis)}",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Black,
                    color = HighDensityText
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = due.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = HighDensityText
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = due.description,
                style = MaterialTheme.typography.bodySmall,
                color = HighDensityMutedText
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = if (due.isPaid) "Paid • Ref: ${due.paymentReference}" else "Due Date: ${due.dueDate}",
                    style = MaterialTheme.typography.labelSmall,
                    color = if (due.isPaid) Color(0xFF047857) else HighDensityMutedText,
                    fontWeight = if (due.isPaid) FontWeight.Bold else FontWeight.Normal
                )

                if (due.isPaid) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = Color(0xFFDCFCE7)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.CheckCircle,
                                contentDescription = null,
                                tint = Color(0xFF16A34A),
                                modifier = Modifier.size(16.dp)
                            )
                            Text(
                                text = "Paid",
                                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                color = Color(0xFF16A34A)
                            )
                        }
                    }
                } else {
                    Button(
                        onClick = onPayClick,
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(institution.primaryColorHex)
                        ),
                        contentPadding = PaddingValues(horizontal = 14.dp, vertical = 6.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Payment,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "Pay with MoMo",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------------------------
// SECTION 3: LOST & FOUND HUB
// ------------------------------------------------------------------------------------------------
@Composable
fun LostAndFoundSection(
    items: List<LostAndFoundItem>,
    institution: InstitutionProfile,
    onReportClick: () -> Unit,
    onClaimClick: (LostAndFoundItem) -> Unit
) {
    var filterStatus by remember { mutableStateOf("ALL") }

    val filteredItems = items.filter {
        when (filterStatus) {
            "LOST" -> it.status == "LOST"
            "FOUND" -> it.status == "FOUND"
            "CLAIMED" -> it.status == "CLAIMED"
            else -> true
        }
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            // Action Banner
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = BorderStroke(1.dp, Slate200)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Campus Lost & Found",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = HighDensityText
                        )
                        Text(
                            text = "Report lost student IDs, gadgets & study packs on ${institution.shortCode}",
                            style = MaterialTheme.typography.bodySmall,
                            color = HighDensityMutedText
                        )
                    }

                    Button(
                        onClick = onReportClick,
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(institution.primaryColorHex)),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Add,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Post Notice", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        item {
            // Filter Chips Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf("ALL" to "All Items", "FOUND" to "Found Items", "LOST" to "Lost Items", "CLAIMED" to "Resolved").forEach { (key, label) ->
                    FilterChip(
                        selected = filterStatus == key,
                        onClick = { filterStatus = key },
                        label = { Text(label, fontSize = 12.sp) },
                        shape = RoundedCornerShape(8.dp)
                    )
                }
            }
        }

        items(filteredItems, key = { it.id }) { item ->
            LostFoundCard(
                item = item,
                institution = institution,
                onClaimClick = { onClaimClick(item) }
            )
        }
    }
}

@Composable
fun LostFoundCard(
    item: LostAndFoundItem,
    institution: InstitutionProfile,
    onClaimClick: () -> Unit
) {
    val isFound = item.status == "FOUND"
    val isClaimed = item.status == "CLAIMED"

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = BorderStroke(1.dp, Slate200)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = when {
                        isClaimed -> Color(0xFFF3F4F6)
                        isFound -> Color(0xFFF0FDF4)
                        else -> Color(0xFFFEF2F2)
                    }
                ) {
                    Text(
                        text = item.status,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Black),
                        color = when {
                            isClaimed -> Color(0xFF6B7280)
                            isFound -> Color(0xFF16A34A)
                            else -> Color(0xFFDC2626)
                        }
                    )
                }

                Text(
                    text = item.dateReported,
                    style = MaterialTheme.typography.labelSmall,
                    color = HighDensityMutedText
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            Text(
                text = item.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = HighDensityText
            )

            Spacer(modifier = Modifier.height(4.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.Place,
                    contentDescription = null,
                    tint = Color(institution.primaryColorHex),
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = item.campusLocation,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.SemiBold,
                    color = Color(institution.primaryColorHex)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = item.description,
                style = MaterialTheme.typography.bodySmall,
                color = HighDensityText
            )

            if (item.rewardCedis != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = Color(0xFFFEF3C7)
                ) {
                    Text(
                        text = "🎁 Cash Reward Offered: GH₵ ${String.format("%.2f", item.rewardCedis)}",
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = Color(0xFF92400E)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))
            HorizontalDivider(color = Slate100)
            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Posted by: ${item.reporterName}",
                        style = MaterialTheme.typography.labelSmall,
                        color = HighDensityMutedText
                    )
                    Text(
                        text = "Contact: ${item.contactPhone}",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = HighDensityText
                    )
                }

                if (!isClaimed) {
                    OutlinedButton(
                        onClick = onClaimClick,
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                        border = BorderStroke(1.dp, Slate300)
                    ) {
                        Text("Mark Claimed", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------------------------
// SECTION 4: EVENTS & PASSES
// ------------------------------------------------------------------------------------------------
@Composable
fun EventsAndPassesSection(
    events: List<CampusEvent>,
    institution: InstitutionProfile,
    onToggleRsvp: (CampusEvent) -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            Text(
                text = "Upcoming Campus Festivals & Tech Summits",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = HighDensityText
            )
        }

        items(events, key = { it.id }) { event ->
            EventCard(event = event, institution = institution, onRsvpClick = { onToggleRsvp(event) })
        }
    }
}

@Composable
fun EventCard(
    event: CampusEvent,
    institution: InstitutionProfile,
    onRsvpClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = BorderStroke(1.dp, if (event.isRsvpd) Color(institution.primaryColorHex) else Slate200)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = Color(institution.primaryColorHex).copy(alpha = 0.12f)
                ) {
                    Text(
                        text = event.category,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = Color(institution.primaryColorHex)
                    )
                }

                Text(
                    text = event.eventDate,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = Color(institution.primaryColorHex)
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            Text(
                text = event.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = HighDensityText
            )

            Spacer(modifier = Modifier.height(4.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.AccessTime,
                    contentDescription = null,
                    tint = HighDensityMutedText,
                    modifier = Modifier.size(14.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = event.time,
                    style = MaterialTheme.typography.bodySmall,
                    color = HighDensityMutedText
                )
                Spacer(modifier = Modifier.width(12.dp))
                Icon(
                    imageVector = Icons.Filled.LocationOn,
                    contentDescription = null,
                    tint = HighDensityMutedText,
                    modifier = Modifier.size(14.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = event.venue,
                    style = MaterialTheme.typography.bodySmall,
                    color = HighDensityMutedText
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = event.description,
                style = MaterialTheme.typography.bodySmall,
                color = HighDensityText
            )

            Spacer(modifier = Modifier.height(12.dp))
            HorizontalDivider(color = Slate100)
            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "${event.attendeeCount} students attending",
                    style = MaterialTheme.typography.labelSmall,
                    color = HighDensityMutedText
                )

                Button(
                    onClick = onRsvpClick,
                    shape = RoundedCornerShape(10.dp),
                    colors = if (event.isRsvpd) {
                        ButtonDefaults.buttonColors(containerColor = Color(0xFFDCFCE7), contentColor = Color(0xFF16A34A))
                    } else {
                        ButtonDefaults.buttonColors(containerColor = Color(institution.primaryColorHex))
                    },
                    contentPadding = PaddingValues(horizontal = 14.dp, vertical = 6.dp)
                ) {
                    Icon(
                        imageVector = if (event.isRsvpd) Icons.Filled.Check else Icons.Filled.ConfirmationNumber,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = if (event.isRsvpd) "RSVP'd (Pass Saved)" else "RSVP Free Pass",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------------------------
// SECTION 5: STUDENT PORTALS GATEWAY
// ------------------------------------------------------------------------------------------------
@Composable
fun PortalsGatewaySection(institution: InstitutionProfile) {
    val context = LocalContext.current

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = BorderStroke(1.dp, Slate200)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "${institution.shortCode} Official Student Portals Gateway",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = HighDensityText
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Instant 1-tap direct access to course registration, LMS assignment submissions, and e-library databases.",
                        style = MaterialTheme.typography.bodySmall,
                        color = HighDensityMutedText
                    )
                }
            }
        }

        items(institution.portals, key = { it.id }) { portal ->
            PortalCard(portal = portal, institution = institution, onOpen = { url ->
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                context.startActivity(intent)
            })
        }
    }
}

@Composable
fun PortalCard(
    portal: InstitutionPortal,
    institution: InstitutionProfile,
    onOpen: (String) -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onOpen(portal.url) },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        border = BorderStroke(1.dp, Slate200)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                modifier = Modifier.weight(1f),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = Color(institution.primaryColorHex).copy(alpha = 0.12f),
                    modifier = Modifier.size(46.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Filled.Language,
                            contentDescription = null,
                            tint = Color(institution.primaryColorHex),
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }

                Column {
                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = Slate100
                    ) {
                        Text(
                            text = portal.category,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                            color = HighDensityMutedText
                        )
                    }
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = portal.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = HighDensityText
                    )
                    Text(
                        text = portal.description,
                        style = MaterialTheme.typography.bodySmall,
                        color = HighDensityMutedText,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            IconButton(onClick = { onOpen(portal.url) }) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                    contentDescription = "Open Portal",
                    tint = Color(institution.primaryColorHex)
                )
            }
        }
    }
}

// ------------------------------------------------------------------------------------------------
// SECTION 6: DIGITAL STUDENT ID CARD
// ------------------------------------------------------------------------------------------------
@Composable
fun DigitalStudentIdSection(
    profile: StudentProfile,
    institution: InstitutionProfile,
    viewModel: MainViewModel,
    onEditClick: () -> Unit
) {
    val firebaseUser by viewModel.firebaseUser.collectAsState()

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Firebase Cloud Authentication Banner
        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("firebase_auth_status_card"),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = BorderStroke(1.dp, if (firebaseUser != null) Color(0xFFBBF7D0) else Slate200)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        Surface(
                            shape = CircleShape,
                            color = if (firebaseUser != null) Color(0xFFDCFCE7) else Color(0xFFEFF6FF),
                            modifier = Modifier.size(42.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = if (firebaseUser != null) Icons.Filled.VerifiedUser else Icons.Filled.LockPerson,
                                    contentDescription = null,
                                    tint = if (firebaseUser != null) Color(0xFF16A34A) else Color(0xFF2563EB),
                                    modifier = Modifier.size(22.dp)
                                )
                            }
                        }
                        Column {
                            Text(
                                text = if (firebaseUser != null) "Firebase Cloud Sync Active" else "Firebase Auth (Sign In)",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold,
                                color = HighDensityText
                            )
                            Text(
                                text = if (firebaseUser != null) (firebaseUser?.email ?: "Authenticated") else "Sync courses, dues & attendance",
                                style = MaterialTheme.typography.bodySmall,
                                color = HighDensityMutedText,
                                maxLines = 1
                            )
                        }
                    }

                    Button(
                        onClick = { viewModel.setSelectedTab(NavigationTab.SIGN_IN) },
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (firebaseUser != null) Color(0xFFF1F5F9) else Color(institution.primaryColorHex)
                        ),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                        Text(
                            text = if (firebaseUser != null) "Account" else "Sign In",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            color = if (firebaseUser != null) HighDensityText else Color.White
                        )
                    }
                }
            }
        }
        item {
            // Digital ID Card Container (Authentic Ghanaian University style)
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(
                    containerColor = Color(institution.primaryColorHex)
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 6.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp)
                ) {
                    // University Header Bar
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(
                                text = institution.name.uppercase(),
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontWeight = FontWeight.Black,
                                    fontSize = 11.sp,
                                    letterSpacing = 0.5.sp
                                ),
                                color = Color.White
                            )
                            Text(
                                text = "STUDENT IDENTITY CARD • ${institution.city}",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                                color = Color(institution.secondaryColorHex)
                            )
                        }

                        Surface(
                            shape = CircleShape,
                            color = Color.White.copy(alpha = 0.2f),
                            modifier = Modifier.size(36.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    text = institution.shortCode,
                                    fontWeight = FontWeight.Black,
                                    color = Color.White,
                                    fontSize = 12.sp
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Photo & Details Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // Avatar Photo
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = Color.White,
                            border = BorderStroke(2.dp, Color(institution.secondaryColorHex)),
                            modifier = Modifier.size(80.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icons.Filled.Person,
                                    contentDescription = null,
                                    tint = Color(institution.primaryColorHex),
                                    modifier = Modifier.size(54.dp)
                                )
                            }
                        }

                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = profile.name,
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            Text(
                                text = "ID: ${profile.studentId}",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Black,
                                color = Color(institution.secondaryColorHex)
                            )
                            Text(
                                text = profile.program,
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.White.copy(alpha = 0.9f)
                            )
                            Text(
                                text = "${profile.level} • ${profile.hallOfResidence}",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color.White.copy(alpha = 0.8f)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    HorizontalDivider(color = Color.White.copy(alpha = 0.2f))
                    Spacer(modifier = Modifier.height(12.dp))

                    // Barcode & Validity Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(
                                text = "BARCODE: ${profile.studentCardBarcode}",
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 10.sp,
                                    letterSpacing = 1.sp
                                ),
                                color = Color.White.copy(alpha = 0.85f)
                            )
                            Text(
                                text = "VALID: ${profile.academicYear}",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                                color = Color(institution.secondaryColorHex)
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = Color.White.copy(alpha = 0.2f)
                        ) {
                            Text(
                                text = "ACTIVE ENROLLED",
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Black),
                                color = Color.White
                            )
                        }
                    }
                }
            }
        }

        item {
            // Profile Actions Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = BorderStroke(1.dp, Slate200)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Student Contact & MoMo Account",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = HighDensityText
                        )
                        IconButton(onClick = onEditClick) {
                            Icon(
                                imageVector = Icons.Filled.Edit,
                                contentDescription = "Edit Profile",
                                tint = Color(institution.primaryColorHex)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    ProfileDetailRow(label = "Student Email", value = profile.email)
                    ProfileDetailRow(label = "Phone Number", value = profile.phone)
                    ProfileDetailRow(label = "MoMo Wallet Number", value = "${profile.momoNumber} (${profile.momoProvider})")
                    ProfileDetailRow(label = "Hall & Room", value = "${profile.hallOfResidence}, ${profile.roomNumber}")
                    ProfileDetailRow(label = "Campus Companion Points", value = "${profile.campusPoints} PTS 🌟")
                }
            }
        }
    }
}

@Composable
fun ProfileDetailRow(label: String, value: String) {
    Column(modifier = Modifier.padding(vertical = 4.dp)) {
        Text(text = label, style = MaterialTheme.typography.labelSmall, color = HighDensityMutedText)
        Text(text = value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = HighDensityText)
    }
}

// ------------------------------------------------------------------------------------------------
// DIALOGS: MOMO PAYMENT, RECEIPT, REPORT, EDIT PROFILE
// ------------------------------------------------------------------------------------------------
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MoMoPaymentDialog(
    due: CampusDueItem,
    studentProfile: StudentProfile,
    institution: InstitutionProfile,
    isProcessing: Boolean,
    onConfirm: (momoNumber: String, provider: String) -> Unit,
    onDismiss: () -> Unit
) {
    var momoNumber by remember { mutableStateOf(studentProfile.momoNumber) }
    var selectedProvider by remember { mutableStateOf(studentProfile.momoProvider) }

    Dialog(onDismissRequest = { if (!isProcessing) onDismiss() }) {
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "MoMo Campus Checkout",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = HighDensityText
                    )
                    IconButton(onClick = onDismiss, enabled = !isProcessing) {
                        Icon(imageVector = Icons.Filled.Close, contentDescription = "Close")
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = Slate100,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text(text = due.title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                        Text(text = "Payable to: ${institution.shortCode} Bursary / SRC Accounts", style = MaterialTheme.typography.labelSmall, color = HighDensityMutedText)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "GH₵ ${String.format("%.2f", due.amountCedis)}",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Black,
                            color = Color(0xFF047857)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Text(text = "Select Mobile Money Network:", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("MTN MoMo", "Telecel Cash", "AT Money").forEach { prov ->
                        val isSelected = selectedProvider == prov
                        OutlinedButton(
                            onClick = { selectedProvider = prov },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(8.dp),
                            border = BorderStroke(
                                1.5.dp,
                                if (isSelected) Color(institution.primaryColorHex) else Slate300
                            ),
                            colors = ButtonDefaults.outlinedButtonColors(
                                containerColor = if (isSelected) Color(institution.primaryColorHex).copy(alpha = 0.1f) else Color.Transparent
                            ),
                            contentPadding = PaddingValues(horizontal = 4.dp, vertical = 6.dp)
                        ) {
                            Text(
                                text = prov.take(7),
                                fontSize = 11.sp,
                                fontWeight = if (isSelected) FontWeight.Black else FontWeight.Normal,
                                color = if (isSelected) Color(institution.primaryColorHex) else HighDensityText
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                OutlinedTextField(
                    value = momoNumber,
                    onValueChange = { momoNumber = it },
                    label = { Text("MoMo Phone Number") },
                    placeholder = { Text("024 XXX XXXX") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(18.dp))

                Button(
                    onClick = { onConfirm(momoNumber, selectedProvider) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    shape = RoundedCornerShape(10.dp),
                    enabled = !isProcessing && momoNumber.isNotBlank(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(institution.primaryColorHex)
                    )
                ) {
                    if (isProcessing) {
                        CircularProgressIndicator(color = Color.White, modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Authorizing via MoMo USSD...")
                    } else {
                        Icon(imageVector = Icons.Filled.Lock, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Pay GH₵ ${String.format("%.2f", due.amountCedis)} Now", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@Composable
fun MoMoReceiptDialog(
    receipt: MoMoPaymentReceipt,
    institution: InstitutionProfile,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Surface(
                    shape = CircleShape,
                    color = Color(0xFFDCFCE7),
                    modifier = Modifier.size(56.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Filled.CheckCircle,
                            contentDescription = null,
                            tint = Color(0xFF16A34A),
                            modifier = Modifier.size(36.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "Payment Successful!",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = HighDensityText
                )

                Text(
                    text = "Official e-Receipt Generated",
                    style = MaterialTheme.typography.bodySmall,
                    color = HighDensityMutedText
                )

                Spacer(modifier = Modifier.height(16.dp))

                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = Slate50,
                    border = BorderStroke(1.dp, Slate200),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        ReceiptRow(label = "Transaction Ref", value = receipt.transactionRef)
                        ReceiptRow(label = "Item Paid", value = receipt.itemTitle)
                        ReceiptRow(label = "Amount Paid", value = "GH₵ ${String.format("%.2f", receipt.amountCedis)}")
                        ReceiptRow(label = "Payer Student", value = "${receipt.payerName} (${receipt.studentId})")
                        ReceiptRow(label = "Network & Number", value = "${receipt.provider} • ${receipt.momoNumber}")
                        ReceiptRow(label = "Status", value = "CLEARED & VERIFIED ✅")
                    }
                }

                Spacer(modifier = Modifier.height(18.dp))

                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(institution.primaryColorHex))
                ) {
                    Text("Done & Save Receipt", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
fun ReceiptRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = label, style = MaterialTheme.typography.labelSmall, color = HighDensityMutedText)
        Text(text = value, style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = HighDensityText)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReportLostFoundDialog(
    institution: InstitutionProfile,
    studentProfile: StudentProfile,
    onSubmit: (LostAndFoundItem) -> Unit,
    onDismiss: () -> Unit
) {
    var title by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var status by remember { mutableStateOf("LOST") }
    var contactPhone by remember { mutableStateOf(studentProfile.phone) }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text(
                    text = "Report Campus Item",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = HighDensityText
                )

                Spacer(modifier = Modifier.height(10.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("LOST" to "I Lost an Item", "FOUND" to "I Found an Item").forEach { (type, label) ->
                        val isSelected = status == type
                        OutlinedButton(
                            onClick = { status = type },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(8.dp),
                            border = BorderStroke(1.5.dp, if (isSelected) Color(institution.primaryColorHex) else Slate300),
                            colors = ButtonDefaults.outlinedButtonColors(
                                containerColor = if (isSelected) Color(institution.primaryColorHex).copy(alpha = 0.1f) else Color.Transparent
                            )
                        ) {
                            Text(label, fontSize = 11.sp, fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Item Name (e.g. Casio fx-991EX)") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = location,
                    onValueChange = { location = it },
                    label = { Text("Location on Campus (e.g. Balme Library 1st Floor)") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Description & Distinguishing marks") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    maxLines = 3
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = contactPhone,
                    onValueChange = { contactPhone = it },
                    label = { Text("Contact Phone / WhatsApp") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Text("Cancel")
                    }

                    Button(
                        onClick = {
                            if (title.isNotBlank() && location.isNotBlank()) {
                                onSubmit(
                                    LostAndFoundItem(
                                        institutionId = institution.id,
                                        title = title,
                                        category = "Gadgets & Cards",
                                        status = status,
                                        campusLocation = location,
                                        dateReported = "Just now",
                                        reporterName = studentProfile.name,
                                        contactPhone = contactPhone,
                                        description = description.ifBlank { "Reported via Student Companion App." }
                                    )
                                )
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp),
                        enabled = title.isNotBlank() && location.isNotBlank(),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(institution.primaryColorHex))
                    ) {
                        Text("Publish Notice")
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditStudentProfileDialog(
    currentProfile: StudentProfile,
    onSave: (StudentProfile) -> Unit,
    onDismiss: () -> Unit
) {
    var name by remember { mutableStateOf(currentProfile.name) }
    var studentId by remember { mutableStateOf(currentProfile.studentId) }
    var program by remember { mutableStateOf(currentProfile.program) }
    var level by remember { mutableStateOf(currentProfile.level) }
    var hall by remember { mutableStateOf(currentProfile.hallOfResidence) }
    var phone by remember { mutableStateOf(currentProfile.phone) }
    var momoNumber by remember { mutableStateOf(currentProfile.momoNumber) }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text(
                    text = "Update Student Profile",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = HighDensityText
                )

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Full Name") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(6.dp))

                OutlinedTextField(
                    value = studentId,
                    onValueChange = { studentId = it },
                    label = { Text("Student / Index Number") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(6.dp))

                OutlinedTextField(
                    value = program,
                    onValueChange = { program = it },
                    label = { Text("Programme / Degree") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(6.dp))

                OutlinedTextField(
                    value = level,
                    onValueChange = { level = it },
                    label = { Text("Academic Level (e.g. Level 300)") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(6.dp))

                OutlinedTextField(
                    value = hall,
                    onValueChange = { hall = it },
                    label = { Text("Hall of Residence") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(6.dp))

                OutlinedTextField(
                    value = phone,
                    onValueChange = { phone = it },
                    label = { Text("Phone Number") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Text("Cancel")
                    }

                    Button(
                        onClick = {
                            onSave(
                                currentProfile.copy(
                                    name = name,
                                    studentId = studentId,
                                    program = program,
                                    level = level,
                                    hallOfResidence = hall,
                                    phone = phone,
                                    momoNumber = momoNumber
                                )
                            )
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Text("Save Details")
                    }
                }
            }
        }
    }
}
