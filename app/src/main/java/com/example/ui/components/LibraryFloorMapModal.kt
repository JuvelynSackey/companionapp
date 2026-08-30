package com.example.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.entity.LibraryFloorEntity
import com.example.data.repository.LibraryWithFloors
import com.example.data.repository.SeatOccupancyLevel
import com.example.ui.MainViewModel
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LibraryFloorMapModal(
    libraryWithFloors: LibraryWithFloors,
    viewModel: MainViewModel,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    val library = libraryWithFloors.library
    val floors = libraryWithFloors.floors.sortedBy { it.floorNumber }

    var selectedFloorIndex by remember { mutableStateOf(0) }
    val currentFloor = floors.getOrNull(selectedFloorIndex) ?: floors.firstOrNull()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = MaterialTheme.colorScheme.surface,
        dragHandle = { BottomSheetDefaults.DragHandle() },
        modifier = modifier.testTag("library_floor_modal")
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header: Library Name & Live Occupancy Counter
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = library.name,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "${library.campusZone} • ${library.totalFloorsCount} Floors",
                        style = MaterialTheme.typography.bodyMedium,
                        color = HighDensityMutedText
                    )
                }

                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = when (libraryWithFloors.occupancyLevel) {
                        SeatOccupancyLevel.HIGH_AVAILABILITY -> StatusGreen.copy(alpha = 0.15f)
                        SeatOccupancyLevel.MODERATE -> StatusAmber.copy(alpha = 0.15f)
                        SeatOccupancyLevel.NEARLY_FULL -> StatusOrange.copy(alpha = 0.15f)
                        SeatOccupancyLevel.FULL -> StatusRed.copy(alpha = 0.15f)
                    },
                    border = BorderStroke(
                        1.dp,
                        when (libraryWithFloors.occupancyLevel) {
                            SeatOccupancyLevel.HIGH_AVAILABILITY -> StatusGreen.copy(alpha = 0.4f)
                            SeatOccupancyLevel.MODERATE -> StatusAmber.copy(alpha = 0.4f)
                            SeatOccupancyLevel.NEARLY_FULL -> StatusOrange.copy(alpha = 0.4f)
                            SeatOccupancyLevel.FULL -> StatusRed.copy(alpha = 0.4f)
                        }
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(
                                    when (libraryWithFloors.occupancyLevel) {
                                        SeatOccupancyLevel.HIGH_AVAILABILITY -> StatusGreen
                                        SeatOccupancyLevel.MODERATE -> StatusAmber
                                        SeatOccupancyLevel.NEARLY_FULL -> StatusOrange
                                        SeatOccupancyLevel.FULL -> StatusRed
                                    }
                                )
                        )
                        Text(
                            text = "${library.availableSeats} of ${library.totalCapacity} Desks Free",
                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                            color = when (libraryWithFloors.occupancyLevel) {
                                SeatOccupancyLevel.HIGH_AVAILABILITY -> StatusGreen
                                SeatOccupancyLevel.MODERATE -> Color(0xFFB45309)
                                SeatOccupancyLevel.NEARLY_FULL -> StatusOrange
                                SeatOccupancyLevel.FULL -> StatusRed
                            }
                        )
                    }
                }
            }

            // Floor Level Selector Tabs
            if (floors.isNotEmpty()) {
                ScrollableTabRow(
                    selectedTabIndex = selectedFloorIndex,
                    edgePadding = 0.dp,
                    containerColor = Color.Transparent,
                    divider = {},
                    modifier = Modifier.fillMaxWidth()
                ) {
                    floors.forEachIndexed { index, floor ->
                        Tab(
                            selected = selectedFloorIndex == index,
                            onClick = { selectedFloorIndex = index },
                            text = {
                                Text(
                                    text = if (floor.floorNumber == 0) "Ground Floor" else "Floor ${floor.floorNumber}",
                                    fontWeight = if (selectedFloorIndex == index) FontWeight.Bold else FontWeight.Medium
                                )
                            },
                            icon = {
                                Icon(
                                    imageVector = when (floor.floorNumber) {
                                        0 -> Icons.Filled.MeetingRoom
                                        1 -> Icons.Filled.Layers
                                        2 -> Icons.Filled.Domain
                                        else -> Icons.Filled.Apartment
                                    },
                                    contentDescription = null,
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        )
                    }
                }
            }

            // Floor Map & Real-Time Availability View
            currentFloor?.let { floor ->
                FloorDetailCard(
                    floor = floor,
                    library = library,
                    viewModel = viewModel
                )
            }

            // Operating Hours Summary Row
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = HighDensityLavenderContainer)
            ) {
                Column(
                    modifier = Modifier.padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.AccessTime,
                            contentDescription = null,
                            tint = HighDensityDeepPurple,
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = "Library Schedule & Contact Info",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = HighDensityDeepPurple
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text("Weekdays (Mon-Fri)", style = MaterialTheme.typography.labelSmall, color = HighDensityMutedText)
                            Text(library.openingHoursWeekdays, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.SemiBold)
                        }
                        Column {
                            Text("Weekends (Sat-Sun)", style = MaterialTheme.typography.labelSmall, color = HighDensityMutedText)
                            Text(library.openingHoursWeekends, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.SemiBold)
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text("Exam Revision Mode", style = MaterialTheme.typography.labelSmall, color = HighDensityMutedText)
                            Text(library.openingHoursExams, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.SemiBold, color = HighDensityDeepPurple)
                        }
                        Column {
                            Text("Help Desk & Phone", style = MaterialTheme.typography.labelSmall, color = HighDensityMutedText)
                            Text("${library.librarianHelpDesk} • ${library.contactPhone}", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Medium)
                        }
                    }
                }
            }

            // Bottom Actions: Walk to Building & Close
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OutlinedButton(
                    onClick = onDismiss,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("Close")
                }

                Button(
                    onClick = {
                        onDismiss()
                        viewModel.navigateToLibraryBuilding(library)
                    },
                    modifier = Modifier
                        .weight(1.5f)
                        .testTag("walk_to_library_button"),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = HighDensityDeepPurple)
                ) {
                    Icon(Icons.Filled.DirectionsWalk, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("Walk to Library")
                }
            }
        }
    }
}

@Composable
private fun FloorDetailCard(
    floor: LibraryFloorEntity,
    library: com.example.data.local.entity.CampusLibraryEntity,
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val floorOccupancyPercent = if (floor.totalFloorSeats > 0) {
        ((floor.totalFloorSeats - floor.availableFloorSeats) * 100) / floor.totalFloorSeats
    } else 0

    val floorOccupancyColor = when {
        floorOccupancyPercent < 60 -> StatusGreen
        floorOccupancyPercent < 85 -> StatusAmber
        else -> StatusRed
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Floor Name & Noise Policy
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = floor.floorName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.VolumeMute,
                            contentDescription = null,
                            tint = HighDensityDeepPurple,
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            text = floor.noisePolicy,
                            style = MaterialTheme.typography.labelSmall,
                            color = HighDensityDeepPurple,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }

                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = floorOccupancyColor.copy(alpha = 0.15f)
                ) {
                    Text(
                        text = "${floor.availableFloorSeats} Vacant / ${floor.totalFloorSeats}",
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = floorOccupancyColor
                    )
                }
            }

            // Floor Capacity Bar
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Floor Occupancy ($floorOccupancyPercent%)",
                        style = MaterialTheme.typography.labelSmall,
                        color = HighDensityMutedText
                    )
                    Text(
                        text = floor.crowdStatus,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = floorOccupancyColor
                    )
                }
                LinearProgressIndicator(
                    progress = { floorOccupancyPercent / 100f },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    color = floorOccupancyColor,
                    trackColor = Color.LightGray.copy(alpha = 0.3f)
                )
            }

            // Power Socket & Amenities Stats
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Surface(
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    color = MaterialTheme.colorScheme.surface
                ) {
                    Row(
                        modifier = Modifier.padding(8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Icon(Icons.Filled.Power, contentDescription = null, tint = HighDensityDeepPurple, modifier = Modifier.size(16.dp))
                        Text(
                            text = "${floor.powerSocketAvailabilityPercent}% Power Outlets",
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }

                Surface(
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    color = MaterialTheme.colorScheme.surface
                ) {
                    Row(
                        modifier = Modifier.padding(8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Icon(Icons.Filled.Wifi, contentDescription = null, tint = HighDensityDeepPurple, modifier = Modifier.size(16.dp))
                        Text(
                            text = "Gigabit Eduroam",
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            // Floor Map Layout & Specific Zones
            Text(
                text = "Interactive Floor Zones & Live Desk Vacancy",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            val zonesList = floor.interactiveMapZones.split(";").map { it.trim() }.filter { it.isNotBlank() }
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                zonesList.forEach { zone ->
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.surface,
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(10.dp)
                                        .clip(CircleShape)
                                        .background(
                                            if (zone.contains("Full", ignoreCase = true)) StatusRed
                                            else StatusGreen
                                        )
                                )
                                Text(
                                    text = zone.substringBefore("(").trim(),
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                            Text(
                                text = if (zone.contains("(")) "(" + zone.substringAfter("(") else "",
                                style = MaterialTheme.typography.bodySmall,
                                fontWeight = FontWeight.Bold,
                                color = if (zone.contains("Full", ignoreCase = true)) StatusRed else StatusGreen
                            )
                        }
                    }
                }
            }

            // Quick Desk Reservation / Check-In Actions
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = { viewModel.checkInToLibraryFloor(floor, library) },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    enabled = floor.availableFloorSeats > 0
                ) {
                    Icon(Icons.Filled.Chair, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("Check In to Desk", style = MaterialTheme.typography.labelSmall)
                }

                FilledTonalButton(
                    onClick = { viewModel.releaseSeatOnLibraryFloor(floor, library) },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Icon(Icons.Filled.CheckCircle, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("Release Desk", style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}
