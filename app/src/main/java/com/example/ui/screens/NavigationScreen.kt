package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.entity.CampusLocationEntity
import com.example.ui.MainViewModel
import com.example.ui.components.CampusNavigationMapComponent
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NavigationScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val locations by viewModel.allLocations.collectAsState()
    val startLoc by viewModel.selectedStartLocation.collectAsState()
    val destLoc by viewModel.selectedDestLocation.collectAsState()
    val activeRoute by viewModel.activeRoute.collectAsState()
    val categoryFilter by viewModel.selectedCategoryFilter.collectAsState()

    var selectedBuildingDetail by remember { mutableStateOf<CampusLocationEntity?>(null) }
    var showStartDropdown by remember { mutableStateOf(false) }
    var showDestDropdown by remember { mutableStateOf(false) }
    var showInstitutionDialog by remember { mutableStateOf(false) }
    val currentInstitution by viewModel.currentInstitution.collectAsState()

    val categories = listOf("All", "Lecture Hall", "Examination Center", "Library", "Laboratory", "Hostel / Hall", "Cafeteria & Food", "Custom Landmark")

    val filteredLocations = if (categoryFilter == "All") {
        locations
    } else {
        locations.filter { it.category == categoryFilter || (categoryFilter == "Custom Landmark" && it.id.startsWith("pin_")) }
    }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 8.dp, bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // Header with Active Campus Context
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "${currentInstitution.shortCode} Campus Navigation",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "${currentInstitution.name} • ${currentInstitution.city} vector map & routes",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(currentInstitution.primaryColorHex),
                        fontWeight = FontWeight.Medium
                    )
                }

                AssistChip(
                    onClick = { showInstitutionDialog = true },
                    label = { Text("Switch", fontWeight = FontWeight.Bold) },
                    leadingIcon = { Icon(Icons.Filled.SwapHoriz, contentDescription = null, modifier = Modifier.size(16.dp)) },
                    colors = AssistChipDefaults.assistChipColors(
                        containerColor = Color(currentInstitution.primaryColorHex).copy(alpha = 0.12f),
                        labelColor = Color(currentInstitution.primaryColorHex)
                    )
                )
            }
        }

        // Interactive Campus Vector Map Component with Pinch-Zoom, Pan, Pin Dropper & Live Guidance
        item {
            CampusNavigationMapComponent(
                viewModel = viewModel,
                onBuildingSelected = { selectedBuildingDetail = it }
            )
        }

        // Route Selector & Waypoint Manager Box
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                border = BorderStroke(1.dp, Slate200)
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "ROUTE WAYPOINTS",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Black, letterSpacing = 0.8.sp),
                        color = Slate600
                    )

                    // Start Location Picker
                    Box(modifier = Modifier.fillMaxWidth()) {
                        OutlinedCard(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { showStartDropdown = true }
                                .testTag("start_location_picker"),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Filled.MyLocation, contentDescription = null, tint = CampusGreen, modifier = Modifier.size(20.dp))
                                Spacer(modifier = Modifier.width(10.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text("Start Point (Origin)", style = MaterialTheme.typography.labelSmall, color = Slate600)
                                    Text(
                                        text = startLoc?.name ?: "Select Starting Hall / Pin",
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.Bold,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                                Icon(Icons.Filled.ArrowDropDown, contentDescription = null, tint = Slate600)
                            }
                        }

                        DropdownMenu(
                            expanded = showStartDropdown,
                            onDismissRequest = { showStartDropdown = false }
                        ) {
                            locations.forEach { loc ->
                                DropdownMenuItem(
                                    text = { Text("${loc.name} (${loc.shortCode})") },
                                    onClick = {
                                        viewModel.selectStartLocation(loc)
                                        showStartDropdown = false
                                    }
                                )
                            }
                        }
                    }

                    // Swap Button Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        IconButton(
                            onClick = { viewModel.swapStartAndDestination() },
                            modifier = Modifier.size(32.dp)
                        ) {
                            Icon(Icons.Filled.SwapVert, contentDescription = "Swap Origin & Destination", tint = HighDensityDeepPurple)
                        }
                    }

                    // Destination Location Picker
                    Box(modifier = Modifier.fillMaxWidth()) {
                        OutlinedCard(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { showDestDropdown = true }
                                .testTag("dest_location_picker"),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Filled.Place, contentDescription = null, tint = CampusRed, modifier = Modifier.size(20.dp))
                                Spacer(modifier = Modifier.width(10.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text("Destination Venue / Landmark", style = MaterialTheme.typography.labelSmall, color = Slate600)
                                    Text(
                                        text = destLoc?.name ?: "Select Destination Venue (e.g. KAB 1, Great Hall)",
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.Bold,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                                Icon(Icons.Filled.ArrowDropDown, contentDescription = null, tint = Slate600)
                            }
                        }

                        DropdownMenu(
                            expanded = showDestDropdown,
                            onDismissRequest = { showDestDropdown = false }
                        ) {
                            locations.forEach { loc ->
                                DropdownMenuItem(
                                    text = { Text("${loc.name} (${loc.shortCode})") },
                                    onClick = {
                                        viewModel.selectDestLocation(loc)
                                        showDestDropdown = false
                                    }
                                )
                            }
                        }
                    }

                    // Route Summary Metrics (if route is active)
                    activeRoute?.let { route ->
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = HighDensityLavenderContainer.copy(alpha = 0.6f),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceAround,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text("DISTANCE", style = MaterialTheme.typography.labelSmall, color = Slate600)
                                    Text("${route.distanceMeters} m", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.ExtraBold, color = HighDensityDeepPurple)
                                }
                                Divider(modifier = Modifier.height(30.dp).width(1.dp), color = Slate200)
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text("WALKING TIME", style = MaterialTheme.typography.labelSmall, color = Slate600)
                                    Text("~${route.estimatedWalkingMinutes} min", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.ExtraBold, color = CampusGreen)
                                }
                                Divider(modifier = Modifier.height(30.dp).width(1.dp), color = Slate200)
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text("ROUTE TYPE", style = MaterialTheme.typography.labelSmall, color = Slate600)
                                    Text("Shaded / Paved", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = Slate700)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Category Filter Chips
        item {
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(vertical = 4.dp)
            ) {
                items(categories) { cat ->
                    val isSelected = cat == categoryFilter
                    FilterChip(
                        selected = isSelected,
                        onClick = { viewModel.setCategoryFilter(cat) },
                        label = { Text(cat, style = MaterialTheme.typography.labelMedium) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = HighDensityDeepPurple,
                            selectedLabelColor = Color.White
                        )
                    )
                }
            }
        }

        // Turn-by-Turn Directions (if route is active)
        activeRoute?.let { route ->
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                    border = BorderStroke(1.dp, Slate200)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.DirectionsWalk, contentDescription = null, tint = HighDensityDeepPurple)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Step-by-Step Walking Route",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        route.steps.forEachIndexed { index, step ->
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                                verticalAlignment = Alignment.Top
                            ) {
                                Surface(
                                    shape = CircleShape,
                                    color = HighDensityLavenderContainer,
                                    modifier = Modifier.size(24.dp)
                                ) {
                                    Box(contentAlignment = Alignment.Center) {
                                        Text(
                                            text = "${index + 1}",
                                            style = MaterialTheme.typography.labelSmall,
                                            fontWeight = FontWeight.Bold,
                                            color = HighDensityDeepPurple
                                        )
                                    }
                                }
                                Spacer(modifier = Modifier.width(10.dp))
                                Text(
                                    text = step,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Slate800,
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }
                }
            }
        }

        // Campus Directory List Header
        item {
            Text(
                text = "Campus Venues & Pinned Locations (${filteredLocations.size})",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }

        items(filteredLocations) { loc ->
            CampusLocationCard(
                location = loc,
                isSelected = loc.id == destLoc?.id,
                onSelectAsDest = { viewModel.selectDestLocation(loc) },
                onViewDetails = { selectedBuildingDetail = loc }
            )
        }
    }

    // Building Facility Details Dialog
    selectedBuildingDetail?.let { building ->
        AlertDialog(
            onDismissRequest = { selectedBuildingDetail = null },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Apartment, contentDescription = null, tint = HighDensityDeepPurple)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(building.name)
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "Category: ${building.category} (${building.shortCode})",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = HighDensityDeepPurple
                    )
                    Text(
                        text = building.description,
                        style = MaterialTheme.typography.bodyMedium,
                        color = Slate800
                    )
                    Divider()
                    Text("🏢 Floors: ${building.floors} Levels", style = MaterialTheme.typography.bodySmall)
                    Text("❄️ Air Conditioning: ${if (building.hasAirConditioning) "Fully Air-Conditioned" else "Natural Ventilation"}", style = MaterialTheme.typography.bodySmall)
                    Text("🔌 Power Outlets: ${if (building.hasPowerSockets) "Available in all halls" else "Limited sockets"}", style = MaterialTheme.typography.bodySmall)
                    Text("♿ Accessibility: ${if (building.wheelchairAccessible) "Ramps & Accessible lifts" else "Stairs only"}", style = MaterialTheme.typography.bodySmall)
                    Text("🚪 Major Rooms: ${building.popularVenuesInside}", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.SemiBold)
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.planRouteTo(building)
                        selectedBuildingDetail = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = HighDensityDeepPurple)
                ) {
                    Icon(Icons.Filled.Navigation, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Navigate Here")
                }
            },
            dismissButton = {
                TextButton(onClick = { selectedBuildingDetail = null }) {
                    Text("Close")
                }
            }
        )
    }

    if (showInstitutionDialog) {
        com.example.ui.components.InstitutionSelectorDialog(
            viewModel = viewModel,
            onDismiss = { showInstitutionDialog = false }
        )
    }
}

@Composable
fun CampusLocationCard(
    location: CampusLocationEntity,
    isSelected: Boolean,
    onSelectAsDest: () -> Unit,
    onViewDetails: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onViewDetails)
            .testTag("location_card_${location.shortCode}"),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) HighDensityLavenderContainer.copy(alpha = 0.5f) else MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(1.dp, if (isSelected) HighDensityDeepPurple else Slate200)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = when {
                    location.category.contains("Exam") -> CampusRed.copy(alpha = 0.12f)
                    location.category.contains("Library") -> Color(0xFF2563EB).copy(alpha = 0.12f)
                    location.category.contains("Laboratory") -> CampusGreen.copy(alpha = 0.12f)
                    location.id.startsWith("pin_") -> Color(0xFFE11D48).copy(alpha = 0.12f)
                    else -> HighDensityDeepPurple.copy(alpha = 0.12f)
                },
                modifier = Modifier.size(44.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = location.shortCode,
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = HighDensityDeepPurple
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = location.name,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = "${location.category} • ~${location.walkingTimeFromHostelMinutes} min walk",
                    style = MaterialTheme.typography.bodySmall,
                    color = Slate600
                )
            }

            Button(
                onClick = onSelectAsDest,
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.buttonColors(containerColor = HighDensityDeepPurple),
                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
            ) {
                Icon(Icons.Filled.Navigation, contentDescription = null, modifier = Modifier.size(14.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text("Route", style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}

