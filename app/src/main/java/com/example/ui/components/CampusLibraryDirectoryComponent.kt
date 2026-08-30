package com.example.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
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
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.entity.CampusLibraryEntity
import com.example.data.repository.LibraryWithFloors
import com.example.data.repository.SeatOccupancyLevel
import com.example.ui.MainViewModel
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CampusLibraryDirectoryComponent(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val librariesWithFloors by viewModel.librariesWithFloors.collectAsState()
    val searchQuery by viewModel.librarySearchQuery.collectAsState()
    val selectedFilter by viewModel.libraryFilterChip.collectAsState()
    val selectedLibraryForModal by viewModel.selectedLibraryForDetails.collectAsState()

    val filterChips = listOf(
        "All",
        "Open Now",
        "High Availability",
        "Silent Study",
        "24/7 Hours",
        "Computer Lab",
        "Discussion Pods"
    )

    val filteredLibraries = librariesWithFloors.filter { item ->
        val lib = item.library
        val matchesSearch = searchQuery.isBlank() ||
                lib.name.contains(searchQuery, ignoreCase = true) ||
                lib.campusZone.contains(searchQuery, ignoreCase = true) ||
                lib.description.contains(searchQuery, ignoreCase = true) ||
                item.floors.any { it.sectionsDescription.contains(searchQuery, ignoreCase = true) || it.floorName.contains(searchQuery, ignoreCase = true) }

        val matchesFilter = when (selectedFilter) {
            "Open Now" -> lib.isOpenNow
            "High Availability" -> item.occupancyLevel == SeatOccupancyLevel.HIGH_AVAILABILITY
            "Silent Study" -> lib.currentNoiseLevel.contains("Silent", ignoreCase = true) || lib.currentNoiseLevel.contains("Deep", ignoreCase = true)
            "24/7 Hours" -> lib.openingHoursExams.contains("24/7", ignoreCase = true)
            "Computer Lab" -> lib.hasComputerLab
            "Discussion Pods" -> lib.hasDiscussionRooms
            else -> true
        }

        matchesSearch && matchesFilter
    }

    val totalAvailableCampusSeats = librariesWithFloors.sumOf { it.library.availableSeats }
    val totalCampusCapacity = librariesWithFloors.sumOf { it.library.totalCapacity }
    val openLibrariesCount = librariesWithFloors.count { it.library.isOpenNow }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 8.dp, bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // Summary & Real-time Sensor Counter Card
        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("library_summary_card"),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(containerColor = HighDensityLavenderContainer)
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top
                    ) {
                        Column {
                            Surface(
                                shape = RoundedCornerShape(100.dp),
                                color = HighDensityDeepPurple
                            ) {
                                Text(
                                    text = "CAMPUS STUDY DIRECTORY",
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                                    style = MaterialTheme.typography.labelSmall.copy(
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        letterSpacing = 0.8.sp
                                    ),
                                    color = Color.White
                                )
                            }
                            Spacer(Modifier.height(4.dp))
                            Text(
                                text = "Library Hours & Live Seats",
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = HighDensityText
                            )
                        }

                        IconButton(
                            onClick = { viewModel.refreshLibraryLiveOccupancy() },
                            modifier = Modifier.testTag("refresh_seats_button")
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Sensors,
                                contentDescription = "Sync Live Occupancy",
                                tint = HighDensityDeepPurple
                            )
                        }
                    }

                    // Stat Metrics Grid
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Surface(
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(14.dp),
                            color = Color.White,
                            shadowElevation = 1.dp
                        ) {
                            Column(
                                modifier = Modifier.padding(12.dp),
                                verticalArrangement = Arrangement.spacedBy(2.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(Icons.Filled.Chair, contentDescription = null, tint = StatusGreen, modifier = Modifier.size(16.dp))
                                    Text("Free Desks", style = MaterialTheme.typography.labelSmall, color = HighDensityMutedText)
                                }
                                Text(
                                    text = "$totalAvailableCampusSeats",
                                    style = MaterialTheme.typography.titleLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = StatusGreen
                                )
                                Text("of $totalCampusCapacity total seats", style = MaterialTheme.typography.bodySmall, color = HighDensityMutedText)
                            }
                        }

                        Surface(
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(14.dp),
                            color = Color.White,
                            shadowElevation = 1.dp
                        ) {
                            Column(
                                modifier = Modifier.padding(12.dp),
                                verticalArrangement = Arrangement.spacedBy(2.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(Icons.Filled.Storefront, contentDescription = null, tint = HighDensityDeepPurple, modifier = Modifier.size(16.dp))
                                    Text("Open Centers", style = MaterialTheme.typography.labelSmall, color = HighDensityMutedText)
                                }
                                Text(
                                    text = "$openLibrariesCount / ${librariesWithFloors.size}",
                                    style = MaterialTheme.typography.titleLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = HighDensityDeepPurple
                                )
                                Text("All branches active", style = MaterialTheme.typography.bodySmall, color = HighDensityMutedText)
                            }
                        }
                    }
                }
            }
        }

        // Search Bar
        item {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { viewModel.setLibrarySearchQuery(it) },
                placeholder = { Text("Search library name, zone, floor or amenities...") },
                leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null, tint = HighDensityMutedText) },
                trailingIcon = {
                    if (searchQuery.isNotBlank()) {
                        IconButton(onClick = { viewModel.setLibrarySearchQuery("") }) {
                            Icon(Icons.Filled.Close, contentDescription = "Clear")
                        }
                    }
                },
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("library_search_input"),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = HighDensityDeepPurple,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outlineVariant,
                    focusedContainerColor = MaterialTheme.colorScheme.surface,
                    unfocusedContainerColor = MaterialTheme.colorScheme.surface
                )
            )
        }

        // Filter Chips Row
        item {
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(vertical = 2.dp)
            ) {
                items(filterChips) { chip ->
                    val isSelected = selectedFilter == chip
                    FilterChip(
                        selected = isSelected,
                        onClick = { viewModel.setLibraryFilterChip(chip) },
                        label = { Text(chip, fontSize = 12.sp, fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal) },
                        shape = RoundedCornerShape(20.dp),
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = HighDensityDeepPurple,
                            selectedLabelColor = Color.White,
                            containerColor = MaterialTheme.colorScheme.surface
                        ),
                        border = FilterChipDefaults.filterChipBorder(
                            enabled = true,
                            selected = isSelected,
                            borderColor = if (isSelected) Color.Transparent else MaterialTheme.colorScheme.outlineVariant
                        )
                    )
                }
            }
        }

        // Search Results Header
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Campus Study Locations (${filteredLibraries.size})",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = "Live IoT Seat Tracker",
                    style = MaterialTheme.typography.labelSmall,
                    color = HighDensityDeepPurple,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }

        // Library Cards List
        items(filteredLibraries, key = { it.library.id }) { item ->
            LibraryDirectoryCard(
                item = item,
                onExploreFloors = { viewModel.selectLibraryForDetails(item) },
                onNavigate = { viewModel.navigateToLibraryBuilding(item.library) }
            )
        }

        if (filteredLibraries.isEmpty()) {
            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                ) {
                    Column(
                        modifier = Modifier.padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(Icons.Filled.SearchOff, contentDescription = null, tint = HighDensityMutedText, modifier = Modifier.size(40.dp))
                        Text(
                            text = "No libraries matching \"$searchQuery\"",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = "Try clearing filters or searching for 'Balme', 'Silent', or 'Law'.",
                            style = MaterialTheme.typography.bodySmall,
                            color = HighDensityMutedText
                        )
                    }
                }
            }
        }
    }

    // Interactive Floor Map & Live Seating Modal
    selectedLibraryForModal?.let { item ->
        LibraryFloorMapModal(
            libraryWithFloors = item,
            viewModel = viewModel,
            onDismiss = { viewModel.selectLibraryForDetails(null) }
        )
    }
}

@Composable
fun LibraryDirectoryCard(
    item: LibraryWithFloors,
    onExploreFloors: () -> Unit,
    onNavigate: () -> Unit,
    modifier: Modifier = Modifier
) {
    val library = item.library
    val occupancyPercent = item.occupancyPercentage

    val badgeColor = when (item.occupancyLevel) {
        SeatOccupancyLevel.HIGH_AVAILABILITY -> StatusGreen
        SeatOccupancyLevel.MODERATE -> StatusAmber
        SeatOccupancyLevel.NEARLY_FULL -> StatusOrange
        SeatOccupancyLevel.FULL -> StatusRed
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onExploreFloors() }
            .testTag("library_card_${library.id}"),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f))
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Top Row: Title, Campus Zone & Occupancy Badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = library.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(Icons.Filled.LocationOn, contentDescription = null, tint = HighDensityMutedText, modifier = Modifier.size(14.dp))
                        Text(
                            text = library.campusZone,
                            style = MaterialTheme.typography.bodySmall,
                            color = HighDensityMutedText
                        )
                    }
                }

                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = badgeColor.copy(alpha = 0.15f),
                    border = BorderStroke(1.dp, badgeColor.copy(alpha = 0.3f))
                ) {
                    Text(
                        text = item.statusText,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = badgeColor
                    )
                }
            }

            // Real-Time Seat Occupancy Progress Bar
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "${library.availableSeats} of ${library.totalCapacity} Desks Available",
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "$occupancyPercent% Occupied",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = badgeColor
                    )
                }

                LinearProgressIndicator(
                    progress = { occupancyPercent / 100f },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    color = badgeColor,
                    trackColor = Color.LightGray.copy(alpha = 0.3f)
                )
            }

            // Floor Badges Row
            if (item.floors.isNotEmpty()) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    item.floors.forEach { floor ->
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)
                        ) {
                            Text(
                                text = "${if (floor.floorNumber == 0) "G" else "${floor.floorNumber}F"}: ${floor.availableFloorSeats} free",
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }
            }

            // Operating Hours & Noise Policy Tags
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = HighDensityLavenderContainer
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(Icons.Filled.AccessTime, contentDescription = null, tint = HighDensityDeepPurple, modifier = Modifier.size(12.dp))
                        Text(
                            text = library.openingHoursWeekdays,
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                            fontWeight = FontWeight.SemiBold,
                            color = HighDensityDeepPurple
                        )
                    }
                }

                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(Icons.Filled.VolumeDown, contentDescription = null, tint = HighDensityMutedText, modifier = Modifier.size(12.dp))
                        Text(
                            text = library.currentNoiseLevel,
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            // Amenities Icon Badges
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                AmenityBadge(icon = Icons.Filled.Power, label = "Sockets", isAvailable = library.hasPowerSockets)
                AmenityBadge(icon = Icons.Filled.Wifi, label = "WiFi 6", isAvailable = library.hasWiFi)
                AmenityBadge(icon = Icons.Filled.AcUnit, label = "AC", isAvailable = library.hasAirConditioning)
                AmenityBadge(icon = Icons.Filled.Computer, label = "PC Lab", isAvailable = library.hasComputerLab)
                AmenityBadge(icon = Icons.Filled.Print, label = "Print", isAvailable = library.hasPrintingStation)
                AmenityBadge(icon = Icons.Filled.Groups, label = "Pods", isAvailable = library.hasDiscussionRooms)
            }

            Divider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))

            // Action Buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onNavigate,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Icon(Icons.Filled.DirectionsWalk, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("Directions", style = MaterialTheme.typography.labelSmall)
                }

                Button(
                    onClick = onExploreFloors,
                    modifier = Modifier.weight(1.5f),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = HighDensityDeepPurple)
                ) {
                    Icon(Icons.Filled.Layers, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("Floor Maps & Seats", style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}

@Composable
private fun AmenityBadge(
    icon: ImageVector,
    label: String,
    isAvailable: Boolean
) {
    if (!isAvailable) return
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = HighDensityDeepPurple,
            modifier = Modifier.size(13.dp)
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
            color = HighDensityMutedText
        )
    }
}
