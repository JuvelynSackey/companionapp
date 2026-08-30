package com.example.ui.components

import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.entity.CampusLocationEntity
import com.example.data.repository.NavigationRoute
import com.example.ui.MainViewModel
import com.example.ui.theme.*
import kotlin.math.roundToInt

/**
 * Interactive Campus Navigation Map Component:
 * - 2D Interactive Canvas with Pinch-to-Zoom & Pan gestures
 * - Custom Pin Dropping with Room Database Persistence
 * - Real-time Walking Route Calculations & Step-by-Step Guidance
 * - Building details inspector & quick waypoint assignment
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CampusNavigationMapComponent(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier,
    onBuildingSelected: ((CampusLocationEntity) -> Unit)? = null
) {
    val locations by viewModel.allLocations.collectAsState()
    val startLoc by viewModel.selectedStartLocation.collectAsState()
    val destLoc by viewModel.selectedDestLocation.collectAsState()
    val activeRoute by viewModel.activeRoute.collectAsState()
    val selectedPace by viewModel.selectedWalkingPace.collectAsState()

    // Map gesture states
    var zoomScale by remember { mutableFloatStateOf(1.0f) }
    var panOffset by remember { mutableStateOf(Offset.Zero) }

    // Pinning states
    var isPinDropMode by remember { mutableStateOf(false) }
    var droppedCoordinate by remember { mutableStateOf<Pair<Float, Float>?>(null) }
    var showPinDialog by remember { mutableStateOf(false) }

    // Building detail inspector dialog
    var inspectedLocation by remember { mutableStateOf<CampusLocationEntity?>(null) }

    // Walk guidance simulation
    var isNavigatingLive by remember { mutableStateOf(false) }
    var activeStepIdx by remember { mutableIntStateOf(0) }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .testTag("campus_interactive_map_card"),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 3.dp),
        border = BorderStroke(1.dp, HighDensityBorder)
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {

            // Top Toolbar / Map Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        shape = CircleShape,
                        color = HighDensityDeepPurple,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.Explore, contentDescription = "Campus Map", tint = Color.White, modifier = Modifier.size(20.dp))
                        }
                    }
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text(
                            text = "CAMPUS INTERACTIVE MAP",
                            style = MaterialTheme.typography.labelSmall.copy(
                                fontWeight = FontWeight.Black,
                                letterSpacing = 0.8.sp
                            ),
                            color = HighDensityText
                        )
                        Text(
                            text = if (isPinDropMode) "📍 Pin Mode: Tap map to drop a point" else "Pinch to zoom • Drag to pan • Tap venues",
                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                            color = if (isPinDropMode) CampusRed else Slate600,
                            fontWeight = if (isPinDropMode) FontWeight.Bold else FontWeight.Normal
                        )
                    }
                }

                // Drop Pin Mode Toggle
                FilledTonalButton(
                    onClick = {
                        isPinDropMode = !isPinDropMode
                        if (!isPinDropMode) droppedCoordinate = null
                    },
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.filledTonalButtonColors(
                        containerColor = if (isPinDropMode) CampusRed else HighDensityLavenderContainer,
                        contentColor = if (isPinDropMode) Color.White else HighDensityDeepPurple
                    ),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp),
                    modifier = Modifier.testTag("btn_toggle_pin_mode")
                ) {
                    Icon(
                        imageVector = if (isPinDropMode) Icons.Filled.LocationOff else Icons.Filled.AddLocationAlt,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = if (isPinDropMode) "Cancel Pin" else "Drop Pin",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold)
                    )
                }
            }

            // Interactive Map Canvas with Overlays
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(340.dp)
                    .clip(RoundedCornerShape(topStart = 0.dp, topEnd = 0.dp, bottomStart = 20.dp, bottomEnd = 20.dp))
                    .background(Color(0xFFE2E8F0))
            ) {
                // Interactive Vector Canvas
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .pointerInput(isPinDropMode, locations, zoomScale, panOffset) {
                            detectTransformGestures { _, pan, zoom, _ ->
                                if (!isPinDropMode) {
                                    zoomScale = (zoomScale * zoom).coerceIn(0.75f, 3.5f)
                                    panOffset = Offset(
                                        x = (panOffset.x + pan.x).coerceIn(-size.width * 0.8f, size.width * 0.8f),
                                        y = (panOffset.y + pan.y).coerceIn(-size.height * 0.8f, size.height * 0.8f)
                                    )
                                }
                            }
                        }
                        .pointerInput(isPinDropMode, locations, zoomScale, panOffset) {
                            detectTapGestures { tapOffset ->
                                val canvasW = size.width
                                val canvasH = size.height

                                // Invert zoom and pan to get percentage coordinates [0..100]
                                val transformedX = (tapOffset.x - panOffset.x - (canvasW / 2)) / zoomScale + (canvasW / 2)
                                val transformedY = (tapOffset.y - panOffset.y - (canvasH / 2)) / zoomScale + (canvasH / 2)

                                val pctX = (transformedX / canvasW) * 100f
                                val pctY = (transformedY / canvasH) * 100f

                                if (isPinDropMode) {
                                    droppedCoordinate = Pair(pctX.coerceIn(5f, 95f), pctY.coerceIn(5f, 95f))
                                    showPinDialog = true
                                } else {
                                    // Check building click hit-test
                                    val clickedBuilding = locations.minByOrNull { loc ->
                                        val locCanvasX = ((loc.mapX / 100f) * canvasW - (canvasW / 2)) * zoomScale + (canvasW / 2) + panOffset.x
                                        val locCanvasY = ((loc.mapY / 100f) * canvasH - (canvasH / 2)) * zoomScale + (canvasH / 2) + panOffset.y
                                        val dx = tapOffset.x - locCanvasX
                                        val dy = tapOffset.y - locCanvasY
                                        dx * dx + dy * dy
                                    }

                                    clickedBuilding?.let { loc ->
                                        val locCanvasX = ((loc.mapX / 100f) * canvasW - (canvasW / 2)) * zoomScale + (canvasW / 2) + panOffset.x
                                        val locCanvasY = ((loc.mapY / 100f) * canvasH - (canvasH / 2)) * zoomScale + (canvasH / 2) + panOffset.y
                                        val dist = kotlin.math.sqrt(((tapOffset.x - locCanvasX) * (tapOffset.x - locCanvasX) + (tapOffset.y - locCanvasY) * (tapOffset.y - locCanvasY)).toDouble())
                                        if (dist < 48 * zoomScale.coerceAtLeast(1f)) {
                                            inspectedLocation = loc
                                            onBuildingSelected?.invoke(loc)
                                        }
                                    }
                                }
                            }
                        }
                ) {
                    val w = size.width
                    val h = size.height

                    // Center pivot transformation
                    val centerX = w / 2f
                    val centerY = h / 2f

                    fun toScreenX(modelPctX: Float): Float =
                        (modelPctX / 100f * w - centerX) * zoomScale + centerX + panOffset.x

                    fun toScreenY(modelPctY: Float): Float =
                        (modelPctY / 100f * h - centerY) * zoomScale + centerY + panOffset.y

                    // 1. Draw Campus Background Zones
                    drawCampusTerrain(w, h, ::toScreenX, ::toScreenY, zoomScale)

                    // 2. Draw Walkways & Main Avenues
                    drawCampusPaths(w, h, ::toScreenX, ::toScreenY, zoomScale)

                    // 3. Draw Active Navigation Route Polyline
                    activeRoute?.let { route ->
                        drawCalculatedRoute(route, ::toScreenX, ::toScreenY, zoomScale)
                    }

                    // 4. Draw Building Footprints and Markers
                    locations.forEach { loc ->
                        val sx = toScreenX(loc.mapX)
                        val sy = toScreenY(loc.mapY)
                        val isStart = loc.id == startLoc?.id
                        val isDest = loc.id == destLoc?.id
                        val isInspected = loc.id == inspectedLocation?.id

                        drawBuildingNode(
                            location = loc,
                            screenX = sx,
                            screenY = sy,
                            isStart = isStart,
                            isDest = isDest,
                            isInspected = isInspected,
                            scale = zoomScale
                        )
                    }

                    // 5. Draw Dropped Pin (if active)
                    droppedCoordinate?.let { (px, py) ->
                        val sx = toScreenX(px)
                        val sy = toScreenY(py)
                        drawCustomPinMarker(sx, sy, zoomScale)
                    }
                }

                // Floating Map Controls (Top-End & Bottom-End)
                Column(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Compass Rose
                    Surface(
                        shape = CircleShape,
                        color = Color.White.copy(alpha = 0.92f),
                        shadowElevation = 4.dp,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text("🧭 N", fontSize = 11.sp, fontWeight = FontWeight.Black, color = CampusRed)
                        }
                    }

                    // Zoom In
                    SmallFloatingActionButton(
                        onClick = { zoomScale = (zoomScale + 0.35f).coerceAtMost(3.5f) },
                        containerColor = Color.White,
                        contentColor = HighDensityText,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(Icons.Filled.Add, contentDescription = "Zoom In", modifier = Modifier.size(18.dp))
                    }

                    // Zoom Out
                    SmallFloatingActionButton(
                        onClick = { zoomScale = (zoomScale - 0.35f).coerceAtLeast(0.75f) },
                        containerColor = Color.White,
                        contentColor = HighDensityText,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(Icons.Filled.Remove, contentDescription = "Zoom Out", modifier = Modifier.size(18.dp))
                    }

                    // Recenter / Reset View
                    SmallFloatingActionButton(
                        onClick = {
                            zoomScale = 1.0f
                            panOffset = Offset.Zero
                        },
                        containerColor = Color.White,
                        contentColor = HighDensityPurplePrimary,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(Icons.Filled.CenterFocusStrong, contentDescription = "Recenter", modifier = Modifier.size(18.dp))
                    }
                }

                // Active Route Floating Summary Ribbon
                activeRoute?.let { route ->
                    Surface(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .padding(12.dp)
                            .fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        color = Color.White.copy(alpha = 0.96f),
                        shadowElevation = 6.dp,
                        border = BorderStroke(1.dp, AcademicBlue.copy(alpha = 0.3f))
                    ) {
                        Column(modifier = Modifier.padding(10.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Filled.DirectionsWalk, contentDescription = null, tint = CampusGreen, modifier = Modifier.size(20.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Column {
                                        Text(
                                            text = "${route.fromLocation.shortCode} ➔ ${route.toLocation.shortCode}",
                                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Black),
                                            color = HighDensityText
                                        )
                                        Text(
                                            text = "${route.distanceMeters}m • ~${route.estimatedWalkingMinutes} min walk",
                                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp, fontWeight = FontWeight.Bold),
                                            color = AcademicBlue
                                        )
                                    }
                                }

                                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                    // Swap Button
                                    IconButton(
                                        onClick = { viewModel.swapStartAndDestination() },
                                        modifier = Modifier.size(32.dp)
                                    ) {
                                        Icon(Icons.Filled.SwapHoriz, contentDescription = "Swap Origin/Dest", tint = HighDensityDeepPurple, modifier = Modifier.size(18.dp))
                                    }

                                    // Clear Route Button
                                    IconButton(
                                        onClick = {
                                            viewModel.clearActiveRoute()
                                            isNavigatingLive = false
                                        },
                                        modifier = Modifier.size(32.dp)
                                    ) {
                                        Icon(Icons.Filled.Close, contentDescription = "Clear Route", tint = Slate600, modifier = Modifier.size(18.dp))
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Route Action Controls & Pace Selector
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // Walking Pace Chips
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Walking Pace:",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = Slate600
                    )

                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        MainViewModel.WalkingPace.values().forEach { pace ->
                            val isPaceSelected = pace == selectedPace
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isPaceSelected) HighDensityDeepPurple else Slate100,
                                modifier = Modifier
                                    .clickable { viewModel.setWalkingPace(pace) }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(pace.iconEmoji, fontSize = 11.sp)
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = pace.name.lowercase().replaceFirstChar { it.uppercase() },
                                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp, fontWeight = FontWeight.Bold),
                                        color = if (isPaceSelected) Color.White else HighDensityText
                                    )
                                }
                            }
                        }
                    }
                }

                // Live Navigation Simulation Banner (if active)
                activeRoute?.let { route ->
                    Surface(
                        shape = RoundedCornerShape(14.dp),
                        color = HighDensityLavenderContainer.copy(alpha = 0.6f),
                        border = BorderStroke(1.dp, HighDensityPurplePrimary.copy(alpha = 0.25f)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Filled.Navigation, contentDescription = null, tint = HighDensityDeepPurple, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = if (isNavigatingLive) "ACTIVE GUIDANCE (STEP ${activeStepIdx + 1}/${route.steps.size})" else "WALKING DIRECTIONS",
                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Black, fontSize = 10.sp),
                                        color = HighDensityDeepPurple
                                    )
                                }

                                TextButton(
                                    onClick = {
                                        if (isNavigatingLive) {
                                            if (activeStepIdx < route.steps.size - 1) {
                                                activeStepIdx++
                                            } else {
                                                isNavigatingLive = false
                                                activeStepIdx = 0
                                            }
                                        } else {
                                            isNavigatingLive = true
                                            activeStepIdx = 0
                                        }
                                    },
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                                ) {
                                    Text(
                                        text = if (isNavigatingLive) (if (activeStepIdx < route.steps.size - 1) "Next Step ➔" else "Finish") else "Start Guidance ▶",
                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                        color = HighDensityDeepPurple
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(4.dp))

                            Text(
                                text = route.steps.getOrElse(activeStepIdx) { route.steps.first() },
                                style = MaterialTheme.typography.bodySmall.copy(fontSize = 12.sp, fontWeight = FontWeight.SemiBold),
                                color = HighDensityText
                            )
                        }
                    }
                }
            }
        }
    }

    // Custom Pin Save Dialog
    if (showPinDialog && droppedCoordinate != null) {
        val (px, py) = droppedCoordinate!!
        var pinName by remember { mutableStateOf("") }
        var pinCode by remember { mutableStateOf("") }
        var pinCategory by remember { mutableStateOf("Custom Landmark") }
        var pinDescription by remember { mutableStateOf("") }

        AlertDialog(
            onDismissRequest = {
                showPinDialog = false
                droppedCoordinate = null
                isPinDropMode = false
            },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.AddLocation, contentDescription = null, tint = CampusRed)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Pin New Campus Location", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Text(
                        text = "Coordinate: (${px.roundToInt()}%, ${py.roundToInt()}%) on Campus Grid",
                        style = MaterialTheme.typography.labelSmall,
                        color = Slate600
                    )

                    OutlinedTextField(
                        value = pinName,
                        onValueChange = { pinName = it },
                        label = { Text("Location / Landmark Name *") },
                        placeholder = { Text("e.g. Science Quad Gazebo, Study Hut 4") },
                        modifier = Modifier.fillMaxWidth().testTag("input_pin_name"),
                        singleLine = true
                    )

                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = pinCode,
                            onValueChange = { pinCode = it },
                            label = { Text("Short Code") },
                            placeholder = { Text("e.g. GAZ-1") },
                            modifier = Modifier.weight(1f).testTag("input_pin_code"),
                            singleLine = true
                        )

                        OutlinedTextField(
                            value = pinCategory,
                            onValueChange = { pinCategory = it },
                            label = { Text("Category") },
                            modifier = Modifier.weight(1f).testTag("input_pin_category"),
                            singleLine = true
                        )
                    }

                    OutlinedTextField(
                        value = pinDescription,
                        onValueChange = { pinDescription = it },
                        label = { Text("Description & Notes") },
                        placeholder = { Text("e.g. Shaded wooden benches with Wi-Fi signal") },
                        modifier = Modifier.fillMaxWidth().testTag("input_pin_description")
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (pinName.isNotBlank()) {
                            viewModel.addCustomPinnedLocation(
                                name = pinName,
                                shortCode = pinCode.ifBlank { "PIN" },
                                category = pinCategory.ifBlank { "Custom Landmark" },
                                mapX = px,
                                mapY = py,
                                description = pinDescription
                            )
                            showPinDialog = false
                            droppedCoordinate = null
                            isPinDropMode = false
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = HighDensityDeepPurple),
                    modifier = Modifier.testTag("btn_save_pin")
                ) {
                    Text("Save to Map")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    showPinDialog = false
                    droppedCoordinate = null
                    isPinDropMode = false
                }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Inspected Building / Pin Detail Bottom Sheet
    inspectedLocation?.let { building ->
        AlertDialog(
            onDismissRequest = { inspectedLocation = null },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        shape = CircleShape,
                        color = getBuildingColor(building.category).copy(alpha = 0.15f),
                        modifier = Modifier.size(36.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = getBuildingIcon(building.category),
                                contentDescription = null,
                                tint = getBuildingColor(building.category),
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text(building.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        Text(building.category, style = MaterialTheme.typography.labelSmall, color = Slate600)
                    }
                }
            },
            text = {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Text(building.description, style = MaterialTheme.typography.bodyMedium, color = Slate700)

                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = Slate100,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text("📍 Key Venues & Rooms:", style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = HighDensityText)
                            Text(building.popularVenuesInside, style = MaterialTheme.typography.bodySmall, color = Slate600)
                        }
                    }

                    // Facility badges
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        if (building.hasAirConditioning) {
                            FacilityPill("❄️ A/C Equipped")
                        }
                        if (building.hasPowerSockets) {
                            FacilityPill("⚡ Power Outlets")
                        }
                        if (building.wheelchairAccessible) {
                            FacilityPill("♿ Accessible")
                        }
                    }
                }
            },
            confirmButton = {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    OutlinedButton(
                        onClick = {
                            viewModel.selectStartLocation(building)
                            inspectedLocation = null
                        }
                    ) {
                        Text("Set Start 🟢", style = MaterialTheme.typography.labelSmall)
                    }

                    Button(
                        onClick = {
                            viewModel.selectDestLocation(building)
                            inspectedLocation = null
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = CampusRed)
                    ) {
                        Text("Set Destination 🔴", style = MaterialTheme.typography.labelSmall)
                    }
                }
            },
            dismissButton = {
                if (building.id.startsWith("pin_")) {
                    TextButton(
                        onClick = {
                            viewModel.deleteCampusLocation(building)
                            inspectedLocation = null
                        }
                    ) {
                        Text("Delete Pin", color = CampusRed)
                    }
                } else {
                    TextButton(onClick = { inspectedLocation = null }) {
                        Text("Close")
                    }
                }
            }
        )
    }
}

// ----------------- Canvas Map Drawing Helpers -----------------

private fun DrawScope.drawCampusTerrain(
    w: Float,
    h: Float,
    toX: (Float) -> Float,
    toY: (Float) -> Float,
    scale: Float
) {
    // 1. Campus Base Grass Ground
    drawRect(color = Color(0xFFF1F5F9))

    // 2. Science Quadrangle (Sage Green Lawn)
    drawRoundRect(
        color = Color(0xFFDCFCE7),
        topLeft = Offset(toX(10f), toY(15f)),
        size = Size(toX(45f) - toX(10f), toY(50f) - toY(15f)),
        cornerRadius = CornerRadius(24f * scale)
    )

    // 3. Central Fountain & Academic Water Body
    val fX = toX(50f)
    val fY = toY(50f)
    val fR = 26f * scale
    drawCircle(color = Color(0xFFBAE6FD), radius = fR, center = Offset(fX, fY))
    drawCircle(color = Color(0xFF0284C7).copy(alpha = 0.35f), radius = fR * 0.6f, center = Offset(fX, fY))

    // 4. University Sports Field / Oval Turf
    drawRoundRect(
        color = Color(0xFFBBF7D0),
        topLeft = Offset(toX(65f), toY(60f)),
        size = Size(toX(92f) - toX(65f), toY(88f) - toY(60f)),
        cornerRadius = CornerRadius(30f * scale)
    )
    // Sports field center ring
    drawCircle(
        color = Color.White.copy(alpha = 0.7f),
        radius = 16f * scale,
        center = Offset(toX(78.5f), toY(74f)),
        style = Stroke(width = 2f * scale)
    )

    // 5. Forestry & Botanical Gardens (South West)
    drawRoundRect(
        color = Color(0xFFD1FAE5),
        topLeft = Offset(toX(12f), toY(65f)),
        size = Size(toX(40f) - toX(12f), toY(90f) - toY(65f)),
        cornerRadius = CornerRadius(20f * scale)
    )
}

private fun DrawScope.drawCampusPaths(
    w: Float,
    h: Float,
    toX: (Float) -> Float,
    toY: (Float) -> Float,
    scale: Float
) {
    val roadColor = Color(0xFFCBD5E1)
    val walkwayColor = Color(0xFFE2E8F0)

    // Main University Ring Road
    val ringPath = Path().apply {
        moveTo(toX(8f), toY(12f))
        lineTo(toX(92f), toY(12f))
        lineTo(toX(92f), toY(92f))
        lineTo(toX(8f), toY(92f))
        close()
    }
    drawPath(path = ringPath, color = roadColor, style = Stroke(width = 10f * scale))

    // Cross Campus Boulevard (East-West & North-South)
    drawLine(
        color = walkwayColor,
        start = Offset(toX(8f), toY(50f)),
        end = Offset(toX(92f), toY(50f)),
        strokeWidth = 14f * scale
    )
    drawLine(
        color = walkwayColor,
        start = Offset(toX(50f), toY(12f)),
        end = Offset(toX(50f), toY(92f)),
        strokeWidth = 14f * scale
    )

    // Shaded Diagonal Walkways
    drawLine(
        color = Color(0xFFFEF3C7),
        start = Offset(toX(20f), toY(25f)),
        end = Offset(toX(50f), toY(50f)),
        strokeWidth = 6f * scale
    )
    drawLine(
        color = Color(0xFFFEF3C7),
        start = Offset(toX(50f), toY(50f)),
        end = Offset(toX(80f), toY(35f)),
        strokeWidth = 6f * scale
    )
    drawLine(
        color = Color(0xFFFEF3C7),
        start = Offset(toX(50f), toY(50f)),
        end = Offset(toX(30f), toY(75f)),
        strokeWidth = 6f * scale
    )
}

private fun DrawScope.drawCalculatedRoute(
    route: NavigationRoute,
    toX: (Float) -> Float,
    toY: (Float) -> Float,
    scale: Float
) {
    if (route.pathPoints.size < 2) return

    val path = Path().apply {
        val first = route.pathPoints.first()
        moveTo(toX(first.first), toY(first.second))
        for (i in 1 until route.pathPoints.size) {
            val pt = route.pathPoints[i]
            lineTo(toX(pt.first), toY(pt.second))
        }
    }

    // Glowing Underlay
    drawPath(
        path = path,
        color = AcademicBlue.copy(alpha = 0.25f),
        style = Stroke(width = 18f * scale, pathEffect = PathEffect.cornerPathEffect(24f * scale))
    )

    // Vibrant Dashed Walking Line
    drawPath(
        path = path,
        color = HighDensityDeepPurple,
        style = Stroke(
            width = 6f * scale,
            pathEffect = PathEffect.dashPathEffect(floatArrayOf(16f * scale, 10f * scale), 0f)
        )
    )

    // Start Waypoint Ring (Green)
    val startPt = route.pathPoints.first()
    drawCircle(
        color = CampusGreen.copy(alpha = 0.3f),
        radius = 24f * scale,
        center = Offset(toX(startPt.first), toY(startPt.second))
    )
    drawCircle(
        color = CampusGreen,
        radius = 12f * scale,
        center = Offset(toX(startPt.first), toY(startPt.second))
    )
    drawCircle(
        color = Color.White,
        radius = 4f * scale,
        center = Offset(toX(startPt.first), toY(startPt.second))
    )

    // Destination Waypoint Ring (Red)
    val destPt = route.pathPoints.last()
    drawCircle(
        color = CampusRed.copy(alpha = 0.35f),
        radius = 26f * scale,
        center = Offset(toX(destPt.first), toY(destPt.second))
    )
    drawCircle(
        color = CampusRed,
        radius = 14f * scale,
        center = Offset(toX(destPt.first), toY(destPt.second))
    )
    drawCircle(
        color = Color.White,
        radius = 5f * scale,
        center = Offset(toX(destPt.first), toY(destPt.second))
    )
}

private fun DrawScope.drawBuildingNode(
    location: CampusLocationEntity,
    screenX: Float,
    screenY: Float,
    isStart: Boolean,
    isDest: Boolean,
    isInspected: Boolean,
    scale: Float
) {
    val nodeColor = when {
        isStart -> CampusGreen
        isDest -> CampusRed
        isInspected -> AcademicGold
        location.id.startsWith("pin_") -> Color(0xFFE11D48)
        else -> getBuildingColor(location.category)
    }

    val radius = if (isStart || isDest || isInspected) 18f * scale else 13f * scale

    // 2.5D Drop Shadow
    drawCircle(
        color = Color.Black.copy(alpha = 0.18f),
        radius = radius,
        center = Offset(screenX, screenY + (3f * scale))
    )

    // Outer Aura Ring
    drawCircle(
        color = nodeColor.copy(alpha = if (isStart || isDest || isInspected) 0.35f else 0.18f),
        radius = radius * 1.7f,
        center = Offset(screenX, screenY)
    )

    // Building Main Core
    drawCircle(
        color = nodeColor,
        radius = radius,
        center = Offset(screenX, screenY)
    )

    // Inner White Accent
    drawCircle(
        color = Color.White,
        radius = radius * 0.4f,
        center = Offset(screenX, screenY)
    )
}

private fun DrawScope.drawCustomPinMarker(screenX: Float, screenY: Float, scale: Float) {
    // Crosshair target animation
    drawCircle(
        color = CampusRed.copy(alpha = 0.4f),
        radius = 28f * scale,
        center = Offset(screenX, screenY)
    )
    drawLine(
        color = CampusRed,
        start = Offset(screenX - (18f * scale), screenY),
        end = Offset(screenX + (18f * scale), screenY),
        strokeWidth = 3f * scale
    )
    drawLine(
        color = CampusRed,
        start = Offset(screenX, screenY - (18f * scale)),
        end = Offset(screenX, screenY + (18f * scale)),
        strokeWidth = 3f * scale
    )
    drawCircle(
        color = CampusRed,
        radius = 8f * scale,
        center = Offset(screenX, screenY)
    )
}

@Composable
private fun FacilityPill(label: String) {
    Surface(
        shape = RoundedCornerShape(6.dp),
        color = Slate200
    ) {
        Text(
            text = label,
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp),
            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp, fontWeight = FontWeight.Bold),
            color = Slate700
        )
    }
}

private fun getBuildingColor(category: String): Color {
    return when {
        category.contains("Exam") -> Color(0xFFDC2626)
        category.contains("Library") -> Color(0xFF2563EB)
        category.contains("Laboratory") -> Color(0xFF0891B2)
        category.contains("Hostel") -> Color(0xFF7C3AED)
        category.contains("Food") || category.contains("Cafeteria") -> Color(0xFFD97706)
        category.contains("Landmark") || category.contains("Custom") -> Color(0xFFE11D48)
        else -> AcademicBlue
    }
}

private fun getBuildingIcon(category: String): androidx.compose.ui.graphics.vector.ImageVector {
    return when {
        category.contains("Exam") -> Icons.Filled.Assignment
        category.contains("Library") -> Icons.Filled.LocalLibrary
        category.contains("Laboratory") -> Icons.Filled.Science
        category.contains("Hostel") -> Icons.Filled.Hotel
        category.contains("Food") || category.contains("Cafeteria") -> Icons.Filled.Restaurant
        category.contains("Landmark") || category.contains("Custom") -> Icons.Filled.PinDrop
        else -> Icons.Filled.Apartment
    }
}
