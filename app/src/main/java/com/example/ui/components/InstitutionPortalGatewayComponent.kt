package com.example.ui.components

import android.content.Intent
import android.net.Uri
import android.widget.Toast
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.InstitutionPortal
import com.example.ui.MainViewModel
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InstitutionPortalGatewayComponent(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val currentInstitution by viewModel.currentInstitution.collectAsState()
    var selectedCategory by remember { mutableStateOf("All") }
    var showAddPortalDialog by remember { mutableStateOf(false) }

    val categories = listOf("All", "LMS & Virtual Class", "Student Records / SIS", "Library & E-Resources", "Payments & Services")

    val portals = currentInstitution.portals.filter { portal ->
        if (selectedCategory == "All") true else portal.category == selectedCategory
    }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(top = 12.dp, bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // Institution Banner Header
        item {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(18.dp),
                color = Color(currentInstitution.primaryColorHex).copy(alpha = 0.08f),
                border = BorderStroke(1.dp, Color(currentInstitution.primaryColorHex).copy(alpha = 0.25f))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Surface(
                                shape = RoundedCornerShape(6.dp),
                                color = Color(currentInstitution.primaryColorHex)
                            ) {
                                Text(
                                    text = currentInstitution.shortCode,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White
                                )
                            }
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Portal Gateway",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Centralized access to official ${currentInstitution.name} digital platforms.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    IconButton(
                        onClick = { showAddPortalDialog = true },
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(Color(currentInstitution.primaryColorHex).copy(alpha = 0.12f))
                    ) {
                        Icon(
                            Icons.Filled.AddLink,
                            contentDescription = "Add Custom Portal",
                            tint = Color(currentInstitution.primaryColorHex)
                        )
                    }
                }
            }
        }

        // Category Filter Chips
        item {
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(categories) { cat ->
                    val isSelected = cat == selectedCategory
                    FilterChip(
                        selected = isSelected,
                        onClick = { selectedCategory = cat },
                        label = { Text(cat, style = MaterialTheme.typography.labelSmall) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = Color(currentInstitution.primaryColorHex),
                            selectedLabelColor = Color.White
                        )
                    )
                }
            }
        }

        // Portals List
        items(portals) { portal ->
            PortalGatewayCard(
                portal = portal,
                brandColor = Color(currentInstitution.primaryColorHex),
                onOpen = {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(portal.url))
                        context.startActivity(intent)
                    } catch (e: Exception) {
                        Toast.makeText(context, "Opening ${portal.name}: ${portal.url}", Toast.LENGTH_SHORT).show()
                    }
                }
            )
        }

        // Help Desk Notice
        item {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Filled.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Text(
                        text = "Need IT login assistance? Contact ${currentInstitution.shortCode} University ICT Directorate or Helpdesk.",
                        style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }

    if (showAddPortalDialog) {
        var portalName by remember { mutableStateOf("") }
        var portalUrl by remember { mutableStateOf("") }
        var portalDesc by remember { mutableStateOf("") }
        var portalCat by remember { mutableStateOf("LMS & Virtual Class") }

        AlertDialog(
            onDismissRequest = { showAddPortalDialog = false },
            title = { Text("Add Custom Campus Link") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = portalName,
                        onValueChange = { portalName = it },
                        label = { Text("Link / Service Name") },
                        placeholder = { Text("e.g. Department Code Repository") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = portalUrl,
                        onValueChange = { portalUrl = it },
                        label = { Text("Web URL") },
                        placeholder = { Text("https://example.edu.gh") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = portalDesc,
                        onValueChange = { portalDesc = it },
                        label = { Text("Short Description") },
                        placeholder = { Text("Lecture notes and assignment submissions") },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (portalName.isNotBlank() && portalUrl.isNotBlank()) {
                            viewModel.addCustomPortalToCurrentInstitution(
                                name = portalName.trim(),
                                url = portalUrl.trim(),
                                category = portalCat,
                                description = portalDesc.trim()
                            )
                            showAddPortalDialog = false
                        }
                    },
                    enabled = portalName.isNotBlank() && portalUrl.isNotBlank()
                ) {
                    Text("Add Link")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddPortalDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun PortalGatewayCard(
    portal: InstitutionPortal,
    brandColor: Color,
    onOpen: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onOpen() }
            .testTag("portal_item_${portal.id}"),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Surface(
                        shape = CircleShape,
                        color = brandColor.copy(alpha = 0.12f),
                        modifier = Modifier.size(40.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = when (portal.category) {
                                    "LMS & Virtual Class" -> Icons.Filled.School
                                    "Student Records / SIS" -> Icons.Filled.Badge
                                    "Library & E-Resources" -> Icons.Filled.LocalLibrary
                                    else -> Icons.Filled.Language
                                },
                                contentDescription = null,
                                tint = brandColor,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }

                    Column {
                        Text(
                            text = portal.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = portal.category,
                            style = MaterialTheme.typography.labelSmall,
                            color = brandColor,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }

                FilledTonalButton(
                    onClick = onOpen,
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text("Launch", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(Icons.Filled.OpenInNew, contentDescription = null, modifier = Modifier.size(14.dp))
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = portal.description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = portal.url,
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                color = Slate600
            )
        }
    }
}
